require 'thread' # to get Thread.exclusive
require 'rbconfig'
require 'parallel/version'

module Parallel
  # This can be returned from lambda or pushed onto queue to end iteration.
  EndOfIteration = Object.new

  class DeadWorker < StandardError
  end

  class Break < StandardError
  end

  class Kill < StandardError
  end

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

  class ItemsWrapper
    def initialize options, items
      @mutex = options[:mutex]
      @index = -1
      @index_mutex = Mutex.new
      @last_value = nil
      @items = items
    end

    def known_size
      nil
    end

    def [] index
      raise "indexed access only allowed with arrays"
    end

    def next
      @index_mutex.synchronize do
        next_without_sync
      end
    end

    def next_without_sync
      if EndOfIteration == @last_value
        EndOfIteration
      else
        @index += 1
        @last_value = next!

        if EndOfIteration == @last_value
          return EndOfIteration
        else
          [@last_value, @index]
        end
      end
    end
  end

  class ArrayWrapper < ItemsWrapper
    def known_size
      @items.size
    end

    def [] index
      @items[index]
    end

    def next!
      if @items.size > @index
        @items[@index]
      else
        EndOfIteration
      end
    end
  end

  class QueueWrapper < ItemsWrapper
    def next!
      @items.pop
    end
  end

  class LambdaWrapper < ItemsWrapper
    def next!
      @mutex.synchronize do
        @items.call
      end
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

      begin
        Marshal.load(read)
      rescue EOFError
        raise DeadWorker
      end
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

      kill_on_ctrl_c(threads) { wait_for_threads(threads) }

      out
    end

    def in_processes(options = {}, &block)
      count, options = extract_count_from_options(options)
      count ||= processor_count
      map(0...count, options.merge(:in_processes => count), &block)
    end

    def each(items, options={}, &block)
      map(items, options.merge(:_preserve_results => false), &block)
      items
    end

    def each_with_index(items, options={}, &block)
      each(items, options.merge(:_with_index => true), &block)
    end

    def map(items, options = {}, &block)
      options[:_preserve_results] = options[:_preserve_results] != false
      options[:_return_result] = options[:_preserve_results] || options[:finish]
      options[:mutex] ||= Mutex.new

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

      items = wrap_items(options, items)
      add_progress_bar!(items, options)

      if size == 0
        work_direct(items, options, &block)
      elsif method == :in_threads
        work_in_threads(items, options.merge(:count => size), &block)
      else
        work_in_processes(items, options.merge(:count => size), &block)
      end
    end

    def add_progress_bar!(items, options)
      title = options[:progress]
      if title
        unless items.known_size
          raise ArgumentError, "can't use progress bar with queues or lambdas"
        end

        require 'ruby-progressbar'
        progress = ProgressBar.create(
          :title => title,
          :total => items.known_size,
          :format => '%t |%E | %B | %a'
        )
        options[:_progressed] = lambda {progress.increment}
      end
    end

    def map_with_index(items, options={}, &block)
      map(items, options.merge(:_with_index => true), &block)
    end

    # Number of processors seen by the OS and used for process scheduling.
    #
    # * AIX: /usr/sbin/pmcycles (AIX 5+), /usr/sbin/lsdev
    # * BSD: /sbin/sysctl
    # * Cygwin: /proc/cpuinfo
    # * Darwin: /usr/bin/hwprefs, /usr/sbin/sysctl
    # * HP-UX: /usr/sbin/ioscan
    # * IRIX: /usr/sbin/sysconf
    # * Linux: /proc/cpuinfo
    # * Minix 3+: /proc/cpuinfo
    # * Solaris: /usr/sbin/psrinfo
    # * Tru64 UNIX: /usr/sbin/psrinfo
    # * UnixWare: /usr/sbin/psrinfo
    #
    def processor_count
      @processor_count ||= begin
        os_name = RbConfig::CONFIG["target_os"]
        if os_name =~ /mingw|mswin/
          require 'win32ole'
          result = WIN32OLE.connect("winmgmts://").ExecQuery(
              "select NumberOfLogicalProcessors from Win32_Processor")
          result.to_enum.collect(&:NumberOfLogicalProcessors).reduce(:+)
        elsif File.readable?("/proc/cpuinfo")
          IO.read("/proc/cpuinfo").scan(/^processor/).size
        elsif File.executable?("/usr/bin/hwprefs")
          IO.popen("/usr/bin/hwprefs thread_count").read.to_i
        elsif File.executable?("/usr/sbin/psrinfo")
          IO.popen("/usr/sbin/psrinfo").read.scan(/^.*on-*line/).size
        elsif File.executable?("/usr/sbin/ioscan")
          IO.popen("/usr/sbin/ioscan -kC processor") do |out|
            out.read.scan(/^.*processor/).size
          end
        elsif File.executable?("/usr/sbin/pmcycles")
          IO.popen("/usr/sbin/pmcycles -m").read.count("\n")
        elsif File.executable?("/usr/sbin/lsdev")
          IO.popen("/usr/sbin/lsdev -Cc processor -S 1").read.count("\n")
        elsif File.executable?("/usr/sbin/sysconf") and os_name =~ /irix/i
          IO.popen("/usr/sbin/sysconf NPROC_ONLN").read.to_i
        elsif File.executable?("/usr/sbin/sysctl")
          IO.popen("/usr/sbin/sysctl -n hw.ncpu").read.to_i
        elsif File.executable?("/sbin/sysctl")
          IO.popen("/sbin/sysctl -n hw.ncpu").read.to_i
        else
          $stderr.puts "Unknown platform: " + RbConfig::CONFIG["target_os"]
          $stderr.puts "Assuming 1 processor."
          1
        end
      end
    end

    # Number of physical processor cores on the current system.
    #
    def physical_processor_count
      @physical_processor_count ||= begin
        ppc = case RbConfig::CONFIG["target_os"]
        when /darwin1/
          IO.popen("/usr/sbin/sysctl -n hw.physicalcpu").read.to_i
        when /linux/
          cores = {}  # unique physical ID / core ID combinations
          phy = 0
          IO.read("/proc/cpuinfo").scan(/^physical id.*|^core id.*/) do |ln|
            if ln.start_with?("physical")
              phy = ln[/\d+/]
            elsif ln.start_with?("core")
              cid = phy + ":" + ln[/\d+/]
              cores[cid] = true if not cores[cid]
            end
          end
          cores.count
        when /mswin|mingw/
          require 'win32ole'
          result_set = WIN32OLE.connect("winmgmts://").ExecQuery(
              "select NumberOfCores from Win32_Processor")
          result_set.to_enum.collect(&:NumberOfCores).reduce(:+)
        else
          processor_count
        end
        # fall back to logical count if physical info is invalid
        ppc > 0 ? ppc : processor_count
      end
    end

    private
    def wrap_items options, items
      if items.kind_of? Array
        items = ArrayWrapper.new options, items
      elsif items.respond_to? :pop
        items = QueueWrapper.new options, items
      elsif items.respond_to? :call
        items = LambdaWrapper.new options, items
      elsif items.respond_to? :to_a
        items = ArrayWrapper.new options, items.to_a
      else
        raise ArgumentError, "Parallel argument should respond to to_a/pop/call"
      end
    end

    def work_direct(items, options)
      results = [] if options[:_preserve_results]

      loop do
        item, index = items.next_without_sync
        break if EndOfIteration == item
        result = options[:_with_index] ? yield(item,index) : yield(item)
        results << result if results
      end

      results
    end

    def work_in_threads(items, options, &block)
      results = [] if options[:_preserve_results]
      exception = nil

      in_threads(options[:count]) do
        # as long as there are more items, work on one of them
        loop do
          break if exception

          item, index = items.next

          break if exception # check again. Some time might have passed.
          break if EndOfIteration == item

          with_instrumentation item, index, options do
            begin
              result = call_with_index(item, index, options, &block)

              # avoid keeping large results around
              results[index] = result if results

              result
            rescue StandardError => e
              exception = e
              break
            end
          end
        end
      end

      handle_exception(exception, results)
    end

    def work_in_processes(items, options, &blk)
      workers = create_workers(items, options, &blk)
      results = [] if options[:_preserve_results]
      exception = nil

      kill_on_ctrl_c(workers.map(&:pid)) do
        in_threads(options[:count]) do |i|
          worker = workers[i]
          worker.thread = Thread.current

          begin
            loop do
              break if exception

              item, index = items.next

              break if exception # check again. Some time might have passed.
              break if EndOfIteration == item

              result = with_instrumentation item, index, options do
                if items.known_size
                  worker.work [index]
                else
                  worker.work [item,index]
                end
              end

              if ExceptionWrapper === result
                exception = result.exception

                if Parallel::Kill === exception
                  (workers - [worker]).each do |w|
                    kill_that_thing!(w.thread)
                    kill_that_thing!(w.pid)
                  end
                end
              else
                results[index] = result if results
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
        item_and_index = Marshal.load(read)
        if item_and_index.size == 1
          index = item_and_index.first
          item = items[index]
        else
          item, index = item_and_index
        end

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
    def kill_on_ctrl_c(things)
      @to_be_killed ||= []
      old_interrupt = nil

      if @to_be_killed.empty?
        old_interrupt = trap_interrupt do
          $stderr.puts 'Parallel execution interrupted, exiting ...'
          @to_be_killed.flatten.compact.each { |thing| kill_that_thing!(thing) }
        end
      end

      @to_be_killed << things

      yield
    ensure
      @to_be_killed.pop # free threads for GC and do not kill pids that could be used for new processes
      restore_interrupt(old_interrupt) if @to_be_killed.empty?
    end

    def trap_interrupt
      old = Signal.trap INTERRUPT_SIGNAL, 'IGNORE'

      Signal.trap INTERRUPT_SIGNAL do
        yield
        if old == "DEFAULT"
          raise Interrupt
        else
          old.call
        end
      end

      old
    end

    def restore_interrupt(old)
      Signal.trap INTERRUPT_SIGNAL, old
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
      args << index if options[:_with_index]
      r = block.call(*args)
      # avoid overhead of passing large results around
      r if options[:_return_result]
    end

    def with_instrumentation(item, index, options)
      if options[:start]
        options[:mutex].synchronize do
          options[:start].call(item, index)
        end
      end

      result = yield
    ensure
      if options[:finish]
        options[:mutex].synchronize do
          options[:finish].call(item, index, result)
        end
      end
      options[:_progressed].call if options[:_progressed]
    end
  end
end
