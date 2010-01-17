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

    # Start writing results into n pipes
    reads = []
    pids = []
    count.times do |i|
      reads[i], write = IO.pipe
      pids << forked_do(i, :into => write, :preserve_results => preserve_results, &block)
      write.close
    end

    kill_on_ctrl_c(pids)

    out = read_from_pipes(reads)

    if preserve_results
      out.map{|x| deserialize(x) }
    end
  end

  def self.each(array, options={}, &block)
    map(array, options.merge(:preserve_results => false), &block)
    array
  end

  def self.map(array, options = {})
    array = array.to_a if array.is_a?(Range)

    if options[:in_threads]
      method = :in_threads
      size = options[method]
    else
      method = :in_processes
      size = options[method] || processor_count
    end

    # work in #{size} threads that use threads/processes
    results = []
    current = -1

    in_threads(size) do
      # as long as there are more items, work on one of them
      loop do
        index = Thread.exclusive{ current+=1 }
        break if index >= array.size
        results[index] = *send(method, options.merge(:count => 1)){ yield array[index] }
      end
    end

    results
  end

  def self.processor_count
    case RUBY_PLATFORM
    when /darwin/
      `hwprefs cpu_count`.to_i
    when /linux/
      `cat /proc/cpuinfo | grep processor | wc -l`.to_i
    end
  end

  private

  # Collect results from pipes simultanously
  # otherwise pipes get stuck when to much is written (buffer full)
  def self.read_from_pipes(reads)
    out = Array.new(reads.size).fill('')
    in_threads(reads.size) do |i|
      while text = reads[i].gets
        out[i] += text
      end
      reads[i].close
    end
    out
  end

  def self.forked_do(work_item, options)
    # activate copy on write friendly GC of REE
    GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)
    Process.fork do
      result = yield(work_item)
      serialize(result, :into => options[:into]) if options[:preserve_results]
    end
  end

  def self.serialize(something, options)
    Marshal.dump(something, options[:into])
  end

  def self.deserialize(something)
    Marshal.load(something)
  end

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

  #handle user interrupt (Ctrl+c)
  def self.kill_on_ctrl_c(pids)
    Signal.trap :SIGINT do
      $stderr.puts 'Parallel execution interrupted, exiting ...'
      pids.each { |pid| Process.kill(:KILL, pid) }
      exit 1 # Quit with 'failed' signal
    end
  end
end