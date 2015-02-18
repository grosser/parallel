require 'rbconfig'
require 'parallel/version'
require 'parallel/processor_count'

module Parallel
  extend Parallel::ProcessorCount

  class DeadWorker < StandardError
  end

  class Break < StandardError
  end

  class Kill < StandardError
  end

  Stop = Object.new

  INTERRUPT_SIGNAL = :SIGINT

  class ExceptionWrapper
    attr_reader :exception
    def initialize(exception)
      dumpable = Marshal.dump(exception) rescue nil
      unless dumpable
        exception = RuntimeError.new("Undumpable Exception -- #{exception.inspect}")
      end

      @exception = exception
    end
  end

  class Worker
    attr_reader :pid, :read, :write
    attr_accessor :thread
    def initialize(read, write, pid)
      @read, @write, @pid = read, write, pid
    end

    def close_pipes
      read.close
      write.close
    end

    def wait
      Process.wait(pid)
    rescue Interrupt
      # process died
    end

    def work(data)
      begin
        Marshal.dump(data, write)
      rescue Errno::EPIPE
        raise DeadWorker
      end

      result = begin
        Marshal.load(read)
      rescue EOFError
        raise DeadWorker
      end
      raise result.exception if ExceptionWrapper === result
      result
    end
  end

  class ItemWrapper
    def initialize(array, mutex)
      @lambda = (array.respond_to?(:call) && array) || queue_wrapper(array)
      @items = array.to_a unless @lambda # turn Range and other Enumerable-s into an Array
      @mutex = mutex
      @index = -1
      @stopped = false
    end

    def producer?
      @lambda
    end

    def each_with_index(&block)
      if producer?
        loop do
          item, index = self.next
          break unless index
          yield(item, index)
        end
      else
        @items.each_with_index(&block)
      end
    end

    def next
      if producer?
        # - index and item stay in sync
        # - do not call lambda after it has returned Stop
        item, index = @mutex.synchronize do
          return if @stopped
          item = @lambda.call
          @stopped = (item == Parallel::Stop)
          return if @stopped
          [item, @index += 1]
        end
      else
        index = @mutex.synchronize { @index += 1 }
        return if index >= size
        item = @items[index]
      end
      [item, index]
    end

    def size
      @items.size
    end

    def pack(item, index)
      producer? ? [item, index] : index
    end

    def unpack(data)
      producer? ? data : [@items[data], data]
    end

    def queue_wrapper(array)
      array.respond_to?(:num_waiting) && array.respond_to?(:pop) && lambda { array.pop(false) }
    end
  end

  class << self
    def in_threads(options={:count => 2})
      count, options = extract_count_from_options(options)

      out = []
      threads = []

      count.times do |i|
        threads[i] = Thread.new do
          out[i] = yield(i)
        end
      end

      kill_on_ctrl_c(threads, options) { wait_for_threads(threads) }

      out
    end

    def in_processes(options = {}, &block)
      count, options = extract_count_from_options(options)
      count ||= processor_count
      map(0...count, options.merge(:in_processes => count), &block)
    end

    def each(array, options={}, &block)
      map(array, options.merge(:preserve_results => false), &block)
      array
    end

    def each_with_index(array, options={}, &block)
      each(array, options.merge(:with_index => true), &block)
    end

    def map(array, options = {}, &block)
      options[:mutex] = Mutex.new

      if RUBY_PLATFORM =~ /java/ and not options[:in_processes]
        method = :in_threads
        size = options[method] || processor_count
      elsif options[:in_threads]
        method = :in_threads
        size = options[method]
      else
        method = :in_processes
        if Process.respond_to?(:fork)
          size = options[method] || processor_count
        else
          $stderr.puts "Warning: Process.fork is not supported by this Ruby"
          size = 0
        end
      end

      items = ItemWrapper.new(array, options[:mutex])

      size = [items.producer? ? size : items.size, size].min

      options[:return_results] = (options[:preserve_results] != false || !!options[:finish])
      add_progress_bar!(items, options)

      if size == 0
        work_direct(items, options, &block)
      elsif method == :in_threads
        work_in_threads(items, options.merge(:count => size), &block)
      else
        work_in_processes(items, options.merge(:count => size), &block)
      end
    end

    def map_with_index(array, options={}, &block)
      map(array, options.merge(:with_index => true), &block)
    end

    private

    def add_progress_bar!(items, options)
      if progress_options = options[:progress]
        raise "Progressbar and producers don't mix" if items.producer?
        require 'ruby-progressbar'

        if progress_options.respond_to? :to_str
          progress_options = { title: progress_options.to_str }
        end

        progress_options = {
          total: items.size,
          format: '%t |%E | %B | %a'
        }.merge(progress_options)

        progress = ProgressBar.create(progress_options)
        old_finish = options[:finish]
        options[:finish] = lambda do |item, i, result|
          old_finish.call(item, i, result) if old_finish
          progress.increment
        end
      end
    end


    def work_direct(items, options, &block)
      results = []
      items.each_with_index do |item, index|
        results << with_instrumentation(item, index, options) do
          call_with_index(item, index, options, &block)
        end
      end
      results
    end

    def work_in_threads(items, options, &block)
      results = []
      exception = nil

      in_threads(options) do
        # as long as there are more items, work on one of them
        loop do
          break if exception
          item, index = items.next
          break unless index

          begin
            results[index] = with_instrumentation item, index, options do
              call_with_index(item, index, options, &block)
            end
          rescue StandardError => e
            exception = e
            break
          end
        end
      end

      handle_exception(exception, results)
    end

    def work_in_processes(items, options, &blk)
      workers = create_workers(items, options, &blk)
      results = []
      exception = nil

      kill_on_ctrl_c(workers.map(&:pid), options) do
        in_threads(options) do |i|
          worker = workers[i]
          worker.thread = Thread.current

          begin
            loop do
              break if exception
              item, index = items.next
              break unless index

              begin
                results[index] = with_instrumentation item, index, options do
                  worker.work(items.pack(item, index))
                end
              rescue StandardError => e
                exception = e
                if Parallel::Kill === exception
                  (workers - [worker]).each do |w|
                    kill_that_thing!(w.thread)
                    kill_that_thing!(w.pid)
                  end
                end
              end
            end
          ensure
            worker.close_pipes
            worker.wait # if it goes zombie, rather wait here to be able to debug
          end
        end
      end

      handle_exception(exception, results)
    end

    def create_workers(items, options, &block)
      workers = []
      Array.new(options[:count]).each do
        workers << worker(items, options.merge(:started_workers => workers), &block)
      end
      workers
    end

    def worker(items, options, &block)
      # use less memory on REE
      GC.copy_on_write_friendly = true if GC.respond_to?(:copy_on_write_friendly=)

      child_read, parent_write = IO.pipe
      parent_read, child_write = IO.pipe

      pid = Process.fork do
        begin
          options.delete(:started_workers).each(&:close_pipes)

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

      Worker.new(parent_read, parent_write, pid)
    end

    def process_incoming_jobs(read, write, items, options, &block)
      while !read.eof?
        data = Marshal.load(read)
        item, index = items.unpack(data)
        result = begin
          call_with_index(item, index, options, &block)
        rescue StandardError => e
          ExceptionWrapper.new(e)
        end
        Marshal.dump(result, write)
      end
    end

    def wait_for_threads(threads)
      interrupted = threads.compact.map do |t|
        begin
          t.join
          nil
        rescue Interrupt => e
          e # thread died, do not stop other threads
        end
      end.compact
      raise interrupted.first if interrupted.first
    end

    def handle_exception(exception, results)
      return nil if [Parallel::Break, Parallel::Kill].include? exception.class
      raise exception if exception
      results
    end

    # options is either a Integer or a Hash with :count
    def extract_count_from_options(options)
      if options.is_a?(Hash)
        count = options[:count]
      else
        count = options
        options = {}
      end
      [count, options]
    end

    # kill all these pids or threads if user presses Ctrl+c
    def kill_on_ctrl_c(things, options)
      @to_be_killed ||= []
      old_interrupt = nil
      signal = options.fetch(:interrupt_signal, INTERRUPT_SIGNAL)

      if @to_be_killed.empty?
        old_interrupt = trap_interrupt(signal) do
          $stderr.puts 'Parallel execution interrupted, exiting ...'
          @to_be_killed.flatten.compact.each { |thing| kill_that_thing!(thing) }
        end
      end

      @to_be_killed << things

      yield
    ensure
      @to_be_killed.pop # free threads for GC and do not kill pids that could be used for new processes
      restore_interrupt(old_interrupt, signal) if @to_be_killed.empty?
    end

    def trap_interrupt(signal)
      old = Signal.trap signal, 'IGNORE'

      Signal.trap signal do
        yield
        if old == "DEFAULT"
          raise Interrupt
        else
          old.call
        end
      end

      old
    end

    def restore_interrupt(old, signal)
      Signal.trap signal, old
    end

    def kill_that_thing!(thing)
      if thing.is_a?(Thread)
        thing.kill
      else
        begin
          Process.kill(:KILL, thing)
        rescue Errno::ESRCH
          # some linux systems already automatically killed the children at this point
          # so we just ignore them not being there
        end
      end
    end

    def call_with_index(item, index, options, &block)
      args = [item]
      args << index if options[:with_index]
      if options[:return_results]
        block.call(*args)
      else
        block.call(*args)
        nil # avoid GC overhead of passing large results around
      end
    end

    def with_instrumentation(item, index, options)
      on_start = options[:start]
      on_finish = options[:finish]
      options[:mutex].synchronize { on_start.call(item, index) } if on_start
      result = yield
      result unless options[:preserve_results] == false
    ensure
      options[:mutex].synchronize { on_finish.call(item, index, result) } if on_finish
    end
  end
end
