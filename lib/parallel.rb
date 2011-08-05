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
    end
    size = [array.size, size].min

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
      `cat /proc/cpuinfo | grep processor | wc -l`.to_i
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

    raise exception if exception

    results
  end

  def self.work_in_processes(items, options, &blk)
    workers = Array.new(options[:count]).map{ worker(items, options, &blk) }
    Parallel.kill_on_ctrl_c(workers.map{|worker| worker[:pid] })

    current_index = -1

    # give every worker something to do
    workers.each do |worker|
      write_to_pipe(worker[:write], current_index += 1)
    end

    # fetch results and hand out new work
    listener_threads = []
    result = Array.new(items.size)
    exception = nil

    workers.each do |worker|
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

            result[result_index] = output

            # give worker next item
            next_index = Thread.exclusive{ current_index += 1 }
            break if next_index >= items.size
            write_to_pipe(worker[:write], next_index)
          end
        ensure
          worker[:read].close
          worker[:write].close
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
    while input = read.gets and input != "\n"
      index = decode(input.chomp)
      begin
        result = call_with_index(items, index, options, &block)
        result = nil if options[:preserve_results] == false
      rescue Exception => e
        result = ExceptionWrapper.new(e)
      end
      write_to_pipe(write, [index, result])
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
