require 'thread' # to get Thread.exclusive

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

    threads.each{|t| t.join }
    out
  end

  def self.in_processes(options = {}, &block)
    count, options = extract_count_from_options(options)
    count ||= processor_count
    preserve_results = (options[:preserve_results] != false)

    pipes, pids = fork_and_start_writing(count, :preserve_results => preserve_results, &block)
    out = read_from_pipes(pipes)
    pids.each { |pid| Process.wait(pid) }
    out.map{|x| deserialize(x) } if preserve_results
  end

  def self.each(array, options={}, &block)
    map(array, options.merge(:preserve_results => false), &block)
    array
  end

  def self.each_with_index(array, options={}, &block)
    each(array, options.merge(:with_index => true), &block)
  end

  def self.map(array, options = {}, &block)
    array = array.to_a if array.is_a?(Range)

    if options[:in_threads]
      method = :in_threads
      size = options[method]
    else
      method = :in_processes
      size = options[method] || processor_count
    end
    size = [array.size, size].min

    if method == :in_threads
      # work in #{size} threads that use threads/processes
      results = []
      current = -1

      in_threads(size) do
        # as long as there are more items, work on one of them
        loop do
          index = Thread.exclusive{ current+=1 }
          break if index >= array.size
          results[index] = call_with_index(array, index, options, &block)
        end
      end

      results
    else
      ForkQueue.collect(array, options.merge(:count => size), &block)
    end
  end

  def self.map_with_index(array, options={}, &block)
    map(array, options.merge(:with_index => true), &block)
  end

  def self.processor_count
    case RUBY_PLATFORM
    when /darwin9/
      `hwprefs cpu_count`.to_i
    when /darwin10/
      `hwprefs thread_count`.to_i
    when /linux/
      `cat /proc/cpuinfo | grep processor | wc -l`.to_i
    when /freebsd/
      `sysctl -n hw.ncpu`.to_i
    end
  end

  private

  # Collect results from pipes simultanously
  # otherwise pipes get stuck when to much is written (buffer full)
  def self.read_from_pipes(reads)
    out = []
    in_threads(reads.size) do |i|
      out[i] = ''
      while text = reads[i].gets
        out[i] += text
      end
      reads[i].close
    end
    out
  end

  # fork and start writing results into n pipes
  def self.fork_and_start_writing(count, options, &block)
    reads = []
    pids = []
    count.times do |i|
      reads[i], write = IO.pipe
      pids << do_in_new_process(i, options.merge(:write_to => (options[:preserve_results] ? write : nil)), &block)
      write.close
    end
    kill_on_ctrl_c(pids)
    [reads, pids]
  end

  def self.do_in_new_process(work_item, options)
    # activate copy on write friendly GC of REE
    GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)
    Process.fork do
      result = yield(work_item)
      serialize(result, options) if options[:write_to]
    end
  end

  def self.serialize(something, options)
    Marshal.dump(something, options[:write_to])
  end

  def self.deserialize(something)
    Marshal.load(something)
  end

  # options is either a Interger or a Hash with :count
  def self.extract_count_from_options(options)
    if options.is_a?(Hash)
      count = options[:count]
    else
      count = options
      options = {}
    end
    [count, options]
  end

  # split an array into groups of size items
  # (copied from ActiveSupport, to not require it)
  def self.in_groups_of(array, size)
    results = []
    loop do
      slice = array[(results.size * size)...((results.size+1) * size)]
      if slice.nil? or slice.empty?
        break
      else
        results << slice
      end
    end
    results
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


require 'base64'

module ForkQueue
  module_function

  def collect(items, options, &blk)
    current_index = 0

    workers = Array.new([options[:count], items.size].min).map do
      worker(items, options, &blk)
    end

    # give every worker something to do
    workers.each do |child|
      child[:write].write(encode(current_index))
      current_index += 1
    end

    # fetch results and hand out new work
    listener_threads = []
    result = Array.new(items.size)

    workers.each do |worker|
      listener_threads << Thread.new do
        begin
          while output = worker[:read].gets
            # handle output from running child
            result_index, output = decode(output.chomp)
            result[result_index] = output

            # more work to do ?
            next_index = Thread.exclusive do
              if items.size > current_index
                current_index += 1
                current_index - 1
              else
                nil
              end
            end

            # give child next item
            if next_index
              worker[:write].write(encode(next_index))
            else
              break
            end
          end
        ensure
          worker[:read].close
          worker[:write].close
        end
      end
    end

    listener_threads.each do |t|
      begin
        t.join
      rescue Interrupt
        # listener died
      end
    end

    workers.each do |worker|
      begin
        Process.wait(worker[:pid])
      rescue Interrupt
        # child died
      end
    end

    return result
  end

  def worker(items, options, &block)
    child_read, parent_write = IO.pipe
    parent_read, child_write = IO.pipe

    pid = Process.fork do
      parent_write.close
      parent_read.close

      begin
        while input = child_read.gets and input != "\n"
          index = decode(input.chomp)
          begin
            result = Parallel.call_with_index(items, index, options, &block)
            result = nil if options[:preserve_results] == false
          rescue Exception => e
            result = Parallel::ExceptionWrapper.new(e)
          end
          child_write.write(encode([index, result]))
        end
      rescue Interrupt
        child_read.close
        child_write.close
      end
    end
    child_read.close
    child_write.close

    {:read => parent_read, :write => parent_write, :pid => pid}
  end

  def encode(obj)
    Base64.encode64(Marshal.dump(obj)).split("\n").join + "\n"
  end

  def decode(str)
    result = Marshal.load(Base64.decode64(str))
    if Parallel::ExceptionWrapper === result
      raise result.exception
    end
    result
  end
end

