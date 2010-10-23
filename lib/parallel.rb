require 'thread' # to get Thread.exclusive

class Parallel
  VERSION = File.read( File.join(File.dirname(__FILE__),'..','VERSION') ).strip
  SPLAT_BUG = *[] # fix for bug/feature http://redmine.ruby-lang.org/issues/show/2422

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

          args = [array[index]]
          args << index if options[:with_index]
          results[index] = yield *args
        end
      end

      results = results.flatten(1) if SPLAT_BUG
      results
    else
      ForkQueue.collect(array, options, &block)
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
end


require 'base64'

module ForkQueue
  module_function

  def collect(items, options, &blk)
    current_index = 0
    children_pids = []
    children_pipes = []

    [THREADS, items.size].min.times do
      child_read, parent_write = IO.pipe
      parent_read, child_write = IO.pipe
      children_pids << Process.fork do
        parent_write.close
        parent_read.close
        begin
          while input = child_read.gets and input != "\n"
            input = items[decode(input.chomp)]
            begin
              result = blk.call(input)
              result = nil unless options[:preserve_results]
            rescue Exception => ex
              result = ForqueExceptionWrapper.new(ex)
            end
            child_write.write(encode(result)+"\n")
          end
        rescue Interrupt
          # init forque aborted
          child_read.close
          child_write.close
        end
      end
      child_write.close
      child_read.close
      children_pipes << {:read => parent_read, :write => parent_write}
    end

    children_pipes.each do |p|
      p[:write].write(encode(current_index) + "\n")
      current_index += 1
    end

    listener_threads = []

    result = []

    children_pipes.each do |p|
      listener_threads << Thread.new do
        begin
          while output = p[:read].gets
            output = decode(output.chomp)
            if ForqueExceptionWrapper === output
              raise output.exception
            end
            result << output

            next_index = Thread.exclusive do
              if items.size <= current_index
                current_index += 1
                current_index - 1
              else
                nil
              end
            end

            if next_index
              p[:read].close
              p[:write].close
              break
            else
              p[:write].write(encode(next_index)+"\n")
            end
          end
        rescue Interrupt
          # listener forque aborted
          p[:read].close
          p[:write].close
          raise "Forque Aborted"
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

    children_pids.each do |p|
      begin
        Process.wait(p)
      rescue Interrupt
        # child died
      end
    end

    return result
  end

  class ForqueExceptionWrapper
    attr_reader :exception
    def initialize(exception)
      @exception = exception
    end
  end

  # detect system
  THREADS = Parallel.processor_count

  def encode(obj)
    Base64.encode64(Marshal.dump(obj)).split("\n").join
  end

  def decode(str)
    Marshal.load(Base64.decode64(str))
  end
end

