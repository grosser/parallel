require 'thread' # to get Thread.exclusive
require 'base64'
require 'rbconfig'

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
    array = array.to_a # turn Range and other Enumerable-s into an Array

    if options[:in_threads]
      method = :in_threads
      size = options[method]
    else
      method = :in_processes
      size = options[method] || processor_count
      size = [array.size, size].min
    end


    return work_direct(array, options, &block) if size == 0

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
    array.each_with_index do |e,i|
      results << (options[:with_index] ? yield(e,i) : yield(e))
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

    queue = []

    producer = Thread.new do
      items.each do |item|
        # wait until queue is empty
        loop do
          could_add = false

          # try to push something into the queue
          Thread.exclusive do
            if queue.empty?
              queue.push item
              could_add = true
            end
          end

          break if could_add

          sleep 0.01 # queue was already full, so wait a bit
        end
      end
    end

    # consumers
    in_threads(options[:count]) do
      loop do
        break if exception
        break if queue.empty? and producer.status == false

        begin
          something_to_do = false
          item = nil
          index = nil

          Thread.exclusive do
            if not queue.empty?
              index = (current += 1)
              something_to_do = true
              item = queue.pop
            end
          end

          if something_to_do
            results[index] = call_with_index_item(item, index, options, &block)
          else
            sleep 0.01 # nothing to do atm, wait for producer
          end
        rescue Exception => e
          exception = e
          break
        end
      end
    end

    raise exception if exception

    results
  end

  def self.work_in_processes(items, options, &blk)
    current_index = -1
    results = []
    pids = []
    exception = nil

    Parallel.kill_on_ctrl_c(pids)

    in_threads(options[:count]) do |i|
      x = i
      worker = worker(items, options, &blk)
      pids[i] = worker[:pid]

      begin
        loop do
          break if exception
          index = Thread.exclusive{ current_index += 1 }
          break if index >= items.size

          write_to_pipe(worker[:write], index)
          output = decode(worker[:read].gets.chomp)

          if ExceptionWrapper === output
            exception = output.exception
          else
            results[index] = output
          end
        end
      ensure
        worker[:read].close
        worker[:write].close

        # if it goes zombie, rather wait here to be able to debug
        wait_for_process worker[:pid]
      end
    end

    raise exception if exception

    results
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
    while input = read.gets and input != "\n"
      index = decode(input.chomp)
      begin
        result = call_with_index(items, index, options, &block)
        result = nil if options[:preserve_results] == false
      rescue Exception => e
        result = ExceptionWrapper.new(e)
      end
      write_to_pipe(write, result)
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

  def self.wait_for_process(pid)
    begin
      Process.wait(pid)
    rescue Interrupt
      # process died
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
      pids.each { |pid| Process.kill(:KILL, pid) if pid }
      exit 1 # Quit with 'failed' signal
    end
  end

  def self.call_with_index_item(item, index, options, &block)
    args = [item]
    args << index if options[:with_index]
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
