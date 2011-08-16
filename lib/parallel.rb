require 'thread' # to get Thread.exclusive
require 'base64'
require 'rbconfig'
require 'core_ext/queue'

class Parallel
  VERSION = File.read( File.join(File.dirname(__FILE__),'..','VERSION') ).strip

  def self.in_threads(options={:count => 2})
    count, options = extract_count_from_options(options)

    out = []
    threads = []

    count.times do |i|
      threads[i] = Thread.new do
        out[i] = yield(i)
      end
    end

    wait_for_threads(threads)

    out
  end

  def self.in_processes(options = {}, &block)
    count, options = extract_count_from_options(options)
    count ||= processor_count
    map(0...count, options.merge(:in_processes => count), &block)
  end

  def self.each(array, options={}, &block)
    map(array, options.merge(:preserve_results => false), &block)
    array
  end

  def self.each_with_index(array, options={}, &block)
    each(array, options.merge(:with_index => true), &block)
  end

  def self.map(array, options = {}, &block)
    if !is_queue?(array)
      array = array.to_a # turn Range and other Enumerable-s into an Array
    end
   
    if options[:in_threads]
      method = :in_threads
      size = options[method]
    else
      method = :in_processes
      size = options[method] || processor_count
    end
    
    if !is_queue?(array)
      size = [array.size, size].min   
      return work_direct(array, options, &block) if  size == 0
    end

    if method == :in_threads
      work_in_threads(array, options.merge(:count => size), &block)
    else
      work_in_processes(array, options.merge(:count => size), &block)
    end
  end

  def self.map_with_index(array, options={}, &block)
    map(array, options.merge(:with_index => true), &block)
  end

  def self.processor_count
    case RbConfig::CONFIG['host_os']
    when /darwin9/
      `hwprefs cpu_count`.to_i
    when /darwin/
      (hwprefs_available? ? `hwprefs thread_count` : `sysctl -n hw.ncpu`).to_i
    when /linux/
      `grep -c processor /proc/cpuinfo`.to_i
    when /freebsd/
      `sysctl -n hw.ncpu`.to_i
    when /mswin|mingw/
      require 'win32ole'
      wmi = WIN32OLE.connect("winmgmts://")
      cpu = wmi.ExecQuery("select NumberOfLogicalProcessors from Win32_Processor")
      cpu.to_enum.first.NumberOfLogicalProcessors
    end
  end

  private

  def self.work_direct(array, options)
    results = []
    if is_queue?(array)
      loop do
        begin
          break if array.empty? && array.closed?
          item = array.pop(true)
          e, i = item
          results << (options[:with_index] ? yield(e,i) : yield(e))
        rescue ThreadError
          sleep 0.2
        rescue Exception => e
          break
        end
      end
    else
      array.each_with_index do |e,i|
        results << (options[:with_index] ? yield(e,i) : yield(e))
      end
    end
    results
  end

  def self.hwprefs_available?
    `which hwprefs` != ''
  end

  def self.work_in_threads(items, options, &block)
    results = []
    current = -1
    exception = nil

    in_threads(options[:count]) do
      # as long as there are more items, work on one of them
      loop do
        break if exception
        if is_queue?(items)
          break if items.empty? && items.closed?
          begin
            result = call_from_queue(items.pop(true), options, &block)
            Thread.exclusive {
              results << result
            }
          rescue ThreadError
            sleep 0.2
          rescue Exception => e
            exception = e
            break
          end
        else
          index = Thread.exclusive{ current+=1 }
          break if index >= items.size

          begin
            results[index] = call_with_index(items, index, options, &block)
          rescue Exception => e
            exception = e
            break
          end
        end
      end
    end

    raise exception if exception

    results
  end
  
  def self.work_in_processes(items, options, &blk)
    workers = Array.new(options[:count]).map{ worker(items, options, &blk) }
    Parallel.kill_on_ctrl_c(workers.map{|worker| worker[:pid] })

    current_index = -1
    listener_threads = []
    # give every worker something to do
    if is_queue?(items)
      # this is a little harder to do for queues so use threads to wait for each worker to get it's first item
      workers.each_index do |worker_index|
        worker = workers[worker_index]
        listener_threads << Thread.new do
          loop do
            begin
              if items.empty? && items.closed?
                worker[:write].close
                break
              end
              
              write_to_pipe(worker[:write], options[:send_worker_index] ? items.pop(worker_index, true) : items.pop(true))
              break
            rescue ThreadError
              sleep 0.2
            rescue Exception => e
              exception = e
              break
            end
          end
        end
       
      end
    else    
      workers.each do |worker|
        write_to_pipe(worker[:write], current_index += 1)
      end
    end
    # fetch results and hand out new work
    
    result = nil
    # if a queue is provided for output then send results there.
    # Entry order is not the same as queue output order
    if !options[:output_queue].nil?
        result = options[:output_queue]
    end
    if result.nil?
      if is_queue?(items)
        result ||= []
      else
        result ||= Array.new(items.size)
      end
    end

    exception = nil

    workers.each_index do |worker_index|
      worker = workers[worker_index]
      listener_threads << Thread.new do
        begin
          while output = worker[:read].gets
            # store output from worker
            result_index, output = decode(output.chomp)
            
            if ExceptionWrapper === output
              exception = output.exception
              break
            elsif exception # some other thread failed
              break
            end
            #
            if options[:preserve_results] == true || options[:preserve_results].nil?
              if is_queue?(result)
                result.push(output)
              else
                if result_index == -1
                  Thread.exclusive{ 
                    result << output 
                  }
                else
                  result[result_index] = output
                end
              end
            end

            # give worker next item
            if is_queue?(items)
              if items.empty? && items.closed?
                break
              end
              loop do
                begin
                  break if items.empty? && items.closed?
                  # send_worker_index allows the worker to be sent to the queue pop method if it supports this.    
                  # This allows the work coming from the queue to determine which worker is trying to get it's next job.
                  # the queue_bundle gem is an example of how this could work
                  # https://github.com/pbrumm/queue_bundle
                  write_to_pipe(worker[:write], options[:send_worker_index] ? items.pop(worker_index, true) : items.pop(true))
                  break
                rescue ThreadError
                  sleep 0.2
                rescue Exception => e
                  exception = e
                  break
                end
              end
              
            else
              next_index = Thread.exclusive{ current_index += 1 }
              break if next_index >= items.size
              write_to_pipe(worker[:write], next_index)
            end
          end
        ensure
          worker[:read].close
          worker[:write].close  rescue nil
        end
      end
    end

    wait_for_threads(listener_threads)
    # if they go zombie, rather wait here to be able to debug
    wait_for_processes(workers.map{|worker| worker[:pid] })

    raise exception if exception

    result
  end

  def self.worker(items, options, &block)
    # use less memory on REE
    GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)

    child_read, parent_write = IO.pipe
    parent_read, child_write = IO.pipe

    pid = Process.fork do
      begin
        parent_write.close
        parent_read.close

        process_incoming_jobs(child_read, child_write, items, options, &block)
      ensure
        child_read.close
        child_write.close
      end
    end

    child_read.close
    child_write.close

    {:read => parent_read, :write => parent_write, :pid => pid}
  end

  def self.process_incoming_jobs(read, write, items, options, &block)
    if options[:starting_worker_process].kind_of?(Proc)
      options[:starting_worker_process].call true
    end
    while input = read.gets and input != "\n" and !input.nil?
      index_or_item = decode(input.chomp)
      begin
        if is_queue?(items)
          result = call_from_queue(index_or_item, options, &block)
          result = nil if options[:preserve_results] == false
        else
          result = call_with_index(items, index_or_item, options, &block)
          result = nil if options[:preserve_results] == false
        end
      rescue Exception => e
        result = ExceptionWrapper.new(e)
      end
      if is_queue?(items)
        write_to_pipe(write, [-1, result])
      else
        write_to_pipe(write, [index_or_item, result])
      end
    end
    
  end

  def self.write_to_pipe(pipe, item)
    pipe.write(encode(item))
  end

  def self.wait_for_threads(threads)
    threads.compact.each do |t|
      begin
        t.join
      rescue Interrupt
        # thread died, do not stop other threads
      end
    end
  end

  def self.wait_for_processes(pids)
    pids.each do |pid|
      begin
        Process.wait(pid)
      rescue Interrupt
        # process died
      end
    end
  end

  def self.encode(obj)
    Base64.encode64(Marshal.dump(obj)).split("\n").join + "\n"
  end

  def self.decode(str)
    Marshal.load(Base64.decode64(str))
  end

  # options is either a Integer or a Hash with :count
  def self.extract_count_from_options(options)
    if options.is_a?(Hash)
      count = options[:count]
    else
      count = options
      options = {}
    end
    [count, options]
  end

  # kill all these processes (children) if user presses Ctrl+c
  def self.kill_on_ctrl_c(pids)
    Signal.trap :SIGINT do
      $stderr.puts 'Parallel execution interrupted, exiting ...'
      pids.each { |pid| Process.kill(:KILL, pid) }
      exit 1 # Quit with 'failed' signal
    end
  end
  # Checks to determine items type.   check to see if it is a queue object, but also check to see if the object should be treated like a queue.
  def self.is_queue?(items)
    items.kind_of?(Queue) || (items.respond_to?(:is_queue?) && items.is_queue? == true)
  end
  def self.call_from_queue(element, options, &block)
    args = [element]
    block.call(*args)
  end
  def self.call_with_index(array, index, options, &block)
    args = [array[index]]
    args << index if options[:with_index]
    block.call(*args)
  end

  class ExceptionWrapper
    attr_reader :exception
    def initialize(exception)
      @exception = exception
    end
  end
end
