# frozen_string_literal: true
require 'spec_helper'

describe Parallel do
  worker_types = ["threads"]
  worker_types << "processes" if Process.respond_to?(:fork)
  worker_types << "ractors" if defined?(Ractor)

  def time_taken
    t = Time.now.to_f
    yield
    RUBY_ENGINE == "jruby" ? 0 : Time.now.to_f - t # jruby is super slow ... don't blow up all the tests ...
  end

  def kill_process_with_name(file, signal = 'INT')
    running_processes = `ps -f`.split("\n").map { |line| line.split(/\s+/) }
    pid_index = running_processes.detect { |p| p.include?("UID") }.index("UID") + 1
    parent_pid = running_processes.detect { |p| p.include?(file) and !p.include?("sh") }[pid_index]
    `kill -s #{signal} #{parent_pid}`
  end

  def execute_start_and_kill(command, amount, signal = 'INT')
    t = nil
    lambda {
      t = Thread.new { ruby("spec/cases/parallel_start_and_kill.rb #{command} 2>&1 && echo 'FINISHED'") }
      sleep 1.5
      kill_process_with_name('spec/cases/parallel_start_and_kill.rb', signal)
      sleep 1
    }.should change { `ps`.split("\n").size }.by amount
    t.value
  end

  def without_ractor_warning(out)
    out.sub(/.*Ractor is experimental.*\n/, "")
  end

  describe ".processor_count" do
    before do
      Parallel.instance_variable_set(:@processor_count, nil)
    end

    it "returns a number" do
      (1..999).should include(Parallel.processor_count)
    end

    if RUBY_PLATFORM =~ /darwin10/
      it 'works if hwprefs in not available' do
        Parallel.should_receive(:hwprefs_available?).and_return false
        (1..999).should include(Parallel.processor_count)
      end
    end

    it 'uses Etc.nprocessors in Ruby 2.2+' do
      defined?(Etc).should == "constant"
      Etc.respond_to?(:nprocessors).should == true
    end
  end

  describe ".physical_processor_count" do
    before do
      Parallel.instance_variable_set(:@physical_processor_count, nil)
    end

    it "returns a number" do
      (1..999).should include(Parallel.physical_processor_count)
    end

    it "is even factor of logical cpus" do
      (Parallel.processor_count % Parallel.physical_processor_count).should == 0
    end
  end

  describe ".in_processes" do
    def cpus
      Parallel.processor_count
    end

    it "executes with detected cpus" do
      ruby("spec/cases/parallel_with_detected_cpus.rb").should == "HELLO\n" * cpus
    end

    it "executes with detected cpus when nil was given" do
      ruby("spec/cases/parallel_with_nil_uses_detected_cpus.rb").should == "HELLO\n" * cpus
    end

    it "executes with cpus from ENV" do
      `PARALLEL_PROCESSOR_COUNT=10 ruby spec/cases/parallel_with_detected_cpus.rb`.should == "HELLO\n" * 10
    end

    it "set amount of parallel processes" do
      ruby("spec/cases/parallel_with_set_processes.rb").should == "HELLO\n" * 5
    end

    it "enforces only one worker type" do
      -> { Parallel.map([1, 2, 3], in_processes: 2, in_threads: 3) }.should raise_error(ArgumentError)
    end

    it "does not influence outside data" do
      ruby("spec/cases/parallel_influence_outside_data.rb").should == "yes"
    end

    it "kills the processes when the main process gets killed through ctrl+c" do
      time_taken do
        result = execute_start_and_kill "PROCESS", 0
        result.should_not include "FINISHED"
      end.should be <= 3
    end

    it "kills the processes when the main process gets killed through a custom interrupt" do
      time_taken do
        execute_start_and_kill "PROCESS SIGTERM", 0, "TERM"
      end.should be <= 3
    end

    it "kills the threads when the main process gets killed through ctrl+c" do
      time_taken do
        result = execute_start_and_kill "THREAD", 0
        result.should_not include "FINISHED"
      end.should be <= 3
    end

    it "does not kill processes when the main process gets sent an interrupt besides the custom interrupt" do
      time_taken do
        result = execute_start_and_kill "PROCESS SIGTERM", 4
        result.should include 'FINISHED'
        result.should include 'Wrapper caught SIGINT'
        result.should include 'I should have been killed earlier'
      end.should be <= 7
    end

    it "does not kill threads when the main process gets sent an interrupt besides the custom interrupt" do
      time_taken do
        result = execute_start_and_kill "THREAD SIGTERM", 2
        result.should include 'FINISHED'
        result.should include 'Wrapper caught SIGINT'
        result.should include 'I should have been killed earlier'
      end.should be <= 7
    end

    it "does not kill anything on ctrl+c when everything has finished" do
      time_taken do
        t = Thread.new { ruby("spec/cases/parallel_fast_exit.rb 2>&1") }
        sleep 2
        kill_process_with_name("spec/cases/parallel_fast_exit.rb") # simulates Ctrl+c
        sleep 1
        result = t.value
        result.scan("I finished").size.should == 3
        result.should_not include("Parallel execution interrupted")
      end.should <= 4
    end

    it "preserves original intrrupts" do
      t = Thread.new { ruby("spec/cases/double_interrupt.rb 2>&1 && echo FIN") }
      sleep 2
      kill_process_with_name("spec/cases/double_interrupt.rb") # simulates Ctrl+c
      sleep 1
      result = t.value
      result.should include("YES")
      result.should include("FIN")
    end

    it "restores original intrrupts" do
      ruby("spec/cases/after_interrupt.rb 2>&1").should == "DEFAULT\n"
    end

    it "saves time" do
      time_taken do
        ruby("spec/cases/parallel_sleeping_2.rb")
      end.should < 3.5
    end

    it "raises when one of the processes raises" do
      ruby("spec/cases/parallel_raise.rb").strip.should == 'TEST'
    end

    it "can raise an undumpable exception" do
      out = ruby("spec/cases/parallel_raise_undumpable.rb").strip
      out.sub!(Dir.pwd, '.') # relative paths
      out.gsub!(/(\d+):.*/, "\\1") # no diff in ruby version xyz.rb:123:in `block in <main>'
      out.should == "MyException: MyException\nBACKTRACE: spec/cases/parallel_raise_undumpable.rb:14"
    end

    it "can handle Break exceptions when the better_errors gem is installed" do
      out = ruby("spec/cases/parallel_break_better_errors.rb").strip
      out.should == "NOTHING WAS RAISED"
    end

    it 'can handle to high fork rate' do
      next if RbConfig::CONFIG["target_os"].include?("darwin1") # kills macs for some reason
      ruby("spec/cases/parallel_high_fork_rate.rb").should == 'OK'
    end

    it 'does not leave processes behind while running' do
      ruby("spec/cases/closes_processes_at_runtime.rb").gsub(/.* deprecated; use BigDecimal.*\n/, '').should == 'OK'
    end

    it "does not open unnecessary pipes" do
      max = (RbConfig::CONFIG["target_os"].include?("darwin1") ? 10 : 1800) # somehow super bad on CI
      ruby("spec/cases/count_open_pipes.rb").to_i.should < max
    end
  end

  describe ".in_threads" do
    it "saves time" do
      time_taken do
        Parallel.in_threads(3) { sleep 2 }
      end.should < 3
    end

    it "does not create new processes" do
      -> { Thread.new { Parallel.in_threads(2) { sleep 1 } } }.should_not(change { `ps`.split("\n").size })
    end

    it "returns results as array" do
      Parallel.in_threads(4) { |i| "XXX#{i}" }.should == ["XXX0", 'XXX1', 'XXX2', 'XXX3']
    end

    it "raises when a thread raises" do
      Thread.report_on_exception = false
      -> { Parallel.in_threads(2) { |_i| raise "TEST" } }.should raise_error("TEST")
    ensure
      Thread.report_on_exception = true
    end
  end

  describe ".map" do
    it "saves time" do
      time_taken do
        ruby("spec/cases/parallel_map_sleeping.rb")
      end.should <= 3.5
    end

    it "does not modify options" do
      -> { Parallel.map([], {}.freeze) }.should_not raise_error
    end

    it "executes with given parameters" do
      ruby("spec/cases/parallel_map.rb").should == "-a- -b- -c- -d-"
    end

    it "can dump/load complex objects" do
      ruby("spec/cases/parallel_map_complex_objects.rb").should == "YES"
    end

    it "starts new process immediately when old exists" do
      time_taken do
        ruby("spec/cases/parallel_map_uneven.rb")
      end.should <= 3.5
    end

    it "does not flatten results" do
      Parallel.map([1, 2, 3], in_threads: 2) { |x| [x, x] }.should == [[1, 1], [2, 2], [3, 3]]
    end

    it "can run in threads" do
      result = Parallel.map([1, 2, 3, 4, 5, 6, 7, 8, 9], in_threads: 4) { |x| x + 2 }
      result.should == [3, 4, 5, 6, 7, 8, 9, 10, 11]
    end

    it 'supports all Enumerable-s' do
      ruby("spec/cases/parallel_map_range.rb").should == '[1, 2, 3, 4, 5]'
    end

    it 'handles nested arrays and nil correctly' do
      ruby("spec/cases/map_with_nested_arrays_and_nil.rb").should == '[nil, [2, 2], [[3], [3]]]'
    end

    worker_types.each do |type|
      it "does not queue new work when one fails in #{type}" do
        out = `METHOD=map WORKER_TYPE=#{type} ruby spec/cases/with_exception.rb 2>&1`
        without_ractor_warning(out).should =~ /\A\d{4} raised\z/
      end

      it "does not queue new work when one raises Break in #{type}" do
        out = `METHOD=map WORKER_TYPE=#{type} ruby spec/cases/with_break.rb 2>&1`
        without_ractor_warning(out).should =~ /\A\d{4} Parallel::Break raised - result nil\z/
      end

      it "stops all workers when a start hook fails with #{type}" do
        out = `METHOD=map WORKER_TYPE=#{type} ruby spec/cases/with_exception_in_start.rb 2>&1`
        out = without_ractor_warning(out)
        if type == "ractors"
          # TODO: running ractors should be interrupted
          out.should =~ /\A.*raised.*\z/
          out.should_not =~ /5/ # stopped at 4
        else
          out.should =~ /\A\d{3} raised\z/
        end
      end

      it "does not add new work when a finish hook fails with #{type}" do
        out = `METHOD=map WORKER_TYPE=#{type} ruby spec/cases/with_exception_in_finish.rb 2>&1`
        without_ractor_warning(out).should =~ /\A\d{4} raised\z/
      end

      it "does not call the finish hook when a worker fails with #{type}" do
        out = `METHOD=map WORKER_TYPE=#{type} ruby spec/cases/with_exception_before_finish.rb 2>&1`
        without_ractor_warning(out).should == '3 called'
      end

      it "does not call the finish hook when a worker raises Break in #{type}" do
        out = `METHOD=map WORKER_TYPE=#{type} ruby spec/cases/with_break_before_finish.rb 2>&1`
        without_ractor_warning(out).should =~ /\A\d{3}(finish hook called){3} Parallel::Break raised\z/
      end

      it "does not call the finish hook when a start hook fails with #{type}" do
        out = `METHOD=map WORKER_TYPE=#{type} ruby spec/cases/with_exception_in_start_before_finish.rb 2>&1`
        if type == "ractors"
          # we are calling on the main thread, so everything sleeps
          without_ractor_warning(out).should == "start 0\n"
        else
          out.split("\n").sort.join("\n").should == <<~OUT.rstrip
            call 3
            finish 2
            start 0
            start 1
            start 2
            start 3
          OUT
        end
      end

      it "can return from break with #{type}" do
        out = `METHOD=map WORKER_TYPE=#{type} ruby spec/cases/with_break.rb hi 2>&1`
        out.should =~ /^\d{4} Parallel::Break raised - result "hi"$/
      end

      it "sets Parallel.worker_number with 4 #{type}" do
        skip if type == "ractors" # not supported
        out = `METHOD=map WORKER_TYPE=#{type} ruby spec/cases/with_worker_number.rb 2>&1`
        out.should =~ /\A[0123]+\z/
        ['0', '1', '2', '3'].each { |number| out.should include number }
      end

      it "sets Parallel.worker_number with 0 #{type}" do
        skip if type == "ractors" # not supported
        type_key = :"in_#{type}"
        result = Parallel.map([1, 2, 3, 4, 5, 6, 7, 8, 9], type_key => 0) { |_x| Parallel.worker_number }
        result.uniq.should == [0]
        Parallel.worker_number.should be_nil
      end

      it "can run with 0 by not using #{type}" do
        Thread.should_not_receive(:exclusive)
        Process.should_not_receive(:fork)
        result = Parallel.map([1, 2, 3, 4, 5, 6, 7, 8, 9], "in_#{type}": 0) { |x| x + 2 }
        result.should == [3, 4, 5, 6, 7, 8, 9, 10, 11]
      end

      it "can call finish hook in order #{type}" do
        out = `METHOD=map WORKER_TYPE=#{type} ruby spec/cases/finish_in_order.rb 2>&1`
        without_ractor_warning(out).should == <<~OUT
          finish nil 0 nil
          finish false 1 false
          finish 2 2 "F2"
          finish 3 3 "F3"
          finish 4 4 "F4"
        OUT
      end
    end

    it "notifies when an item of work is dispatched to a worker process" do
      monitor = double('monitor', call: nil)
      monitor.should_receive(:call).once.with(:first, 0)
      monitor.should_receive(:call).once.with(:second, 1)
      monitor.should_receive(:call).once.with(:third, 2)
      Parallel.map([:first, :second, :third], start: monitor, in_processes: 3) {}
    end

    it "notifies when an item of work is dispatched with 0 processes" do
      monitor = double('monitor', call: nil)
      monitor.should_receive(:call).once.with(:first, 0)
      monitor.should_receive(:call).once.with(:second, 1)
      monitor.should_receive(:call).once.with(:third, 2)
      Parallel.map([:first, :second, :third], start: monitor, in_processes: 0) {}
    end

    it "notifies when an item of work is completed by a worker process" do
      monitor = double('monitor', call: nil)
      monitor.should_receive(:call).once.with(:first, 0, 123)
      monitor.should_receive(:call).once.with(:second, 1, 123)
      monitor.should_receive(:call).once.with(:third, 2, 123)
      Parallel.map([:first, :second, :third], finish: monitor, in_processes: 3) { 123 }
    end

    it "notifies when an item of work is completed with 0 processes" do
      monitor = double('monitor', call: nil)
      monitor.should_receive(:call).once.with(:first, 0, 123)
      monitor.should_receive(:call).once.with(:second, 1, 123)
      monitor.should_receive(:call).once.with(:third, 2, 123)
      Parallel.map([:first, :second, :third], finish: monitor, in_processes: 0) { 123 }
    end

    it "notifies when an item of work is dispatched to a threaded worker" do
      monitor = double('monitor', call: nil)
      monitor.should_receive(:call).once.with(:first, 0)
      monitor.should_receive(:call).once.with(:second, 1)
      monitor.should_receive(:call).once.with(:third, 2)
      Parallel.map([:first, :second, :third], start: monitor, in_threads: 3) {}
    end

    it "notifies when an item of work is dispatched with 0 threads" do
      monitor = double('monitor', call: nil)
      monitor.should_receive(:call).once.with(:first, 0)
      monitor.should_receive(:call).once.with(:second, 1)
      monitor.should_receive(:call).once.with(:third, 2)
      Parallel.map([:first, :second, :third], start: monitor, in_threads: 0) {}
    end

    it "notifies when an item of work is completed by a threaded worker" do
      monitor = double('monitor', call: nil)
      monitor.should_receive(:call).once.with(:first, 0, 123)
      monitor.should_receive(:call).once.with(:second, 1, 123)
      monitor.should_receive(:call).once.with(:third, 2, 123)
      Parallel.map([:first, :second, :third], finish: monitor, in_threads: 3) { 123 }
    end

    it "notifies when an item of work is completed with 0 threads" do
      monitor = double('monitor', call: nil)
      monitor.should_receive(:call).once.with(:first, 0, 123)
      monitor.should_receive(:call).once.with(:second, 1, 123)
      monitor.should_receive(:call).once.with(:third, 2, 123)
      Parallel.map([:first, :second, :third], finish: monitor, in_threads: 0) { 123 }
    end

    it "spits out a useful error when a worker dies before read" do
      ruby("spec/cases/map_with_killed_worker_before_read.rb 2>&1").should include "DEAD"
    end

    it "spits out a useful error when a worker dies before write" do
      ruby("spec/cases/map_with_killed_worker_before_write.rb 2>&1").should include "DEAD"
    end

    it "raises DeadWorker when using exit so people learn to not kill workers and do not crash main process" do
      ruby("spec/cases/exit_in_process.rb 2>&1").should include "Yep, DEAD"
    end

    it "rescues the Exception raised in child process" do
      ruby("spec/cases/exception_raised_in_process.rb 2>&1").should include "Yep, rescued the exception"
    end

    it 'raises EOF (not DeadWorker) when a worker raises EOF in process' do
      ruby("spec/cases/eof_in_process.rb 2>&1").should include 'Yep, EOF'
    end

    it "threads can be killed instantly" do
      mutex = Mutex.new
      state = [nil, nil]
      children = [nil, nil]
      thread = Thread.new do
        parent = Thread.current
        Parallel.map([0, 1], in_threads: 2) do |i|
          mutex.synchronize { children[i] = Thread.current }
          mutex.synchronize { state[i] = :ready }
          parent.join
          mutex.synchronize { state[i] = :error }
        end
      end
      Thread.pass while state.any?(&:nil?)
      thread.kill
      Thread.pass while children.any?(&:alive?)
      state[0].should == :ready
      state[1].should == :ready
    end

    it "processes can be killed instantly" do
      pipes = [IO.pipe, IO.pipe]
      thread = Thread.new do
        Parallel.map([0, 1, 2, 3], in_processes: 2) do |i|
          pipes[i % 2][0].close unless pipes[i % 2][0].closed?
          Marshal.dump('finish', pipes[i % 2][1])
          sleep 1
          nil
        end
      end
      [0, 1].each do |i|
        Marshal.load(pipes[i][0]).should == 'finish'
      end
      pipes.each { |pipe| pipe[1].close }
      thread.kill
      pipes.each do |pipe|
        begin
          ret = Marshal.load(pipe[0])
        rescue EOFError
          ret = :error
        end
        ret.should == :error
      end
      pipes.each { |pipe| pipe[0].close }
    end

    it "synchronizes :start and :finish" do
      out = ruby("spec/cases/synchronizes_start_and_finish.rb")
      ['a', 'b', 'c'].each do |letter|
        out.sub! letter.downcase * 10, 'OK'
        out.sub! letter.upcase * 10, 'OK'
      end
      out.should == "OK\n" * 6
    end

    it 'is equivalent to serial map' do
      l = Array.new(10_000) { |i| i }
      Parallel.map(l, { in_threads: 4 }) { |x| x + 1 }.should == l.map { |x| x + 1 }
    end

    it 'can work in isolation' do
      out = ruby("spec/cases/map_isolation.rb")
      out.should == "1\n2\n3\n4\nOK"
    end

    it 'sets Parallel.worker_number when run with isolation' do
      out = ruby("spec/cases/map_worker_number_isolation.rb")
      out.should == "0,1\nOK"
    end

    it 'can use Timeout' do
      out = ruby("spec/cases/timeout_in_threads.rb")
      out.should == "OK\n"
    end
  end

  describe ".map_with_index" do
    it "yields object and index" do
      ruby("spec/cases/map_with_index.rb 2>&1").should == 'a0b1'
    end

    it "does not crash with empty set" do
      ruby("spec/cases/map_with_index_empty.rb 2>&1").should == ''
    end

    it "can run with 0 threads" do
      Thread.should_not_receive(:exclusive)
      Parallel.map_with_index([1, 2, 3, 4, 5, 6, 7, 8, 9], in_threads: 0) do |x, _i|
        x + 2
      end.should == [3, 4, 5, 6, 7, 8, 9, 10, 11]
    end

    it "can run with 0 processes" do
      Process.should_not_receive(:fork)
      Parallel.map_with_index([1, 2, 3, 4, 5, 6, 7, 8, 9], in_processes: 0) do |x, _i|
        x + 2
      end.should == [3, 4, 5, 6, 7, 8, 9, 10, 11]
    end
  end

  describe ".flat_map" do
    it "yields object and index" do
      ruby("spec/cases/flat_map.rb 2>&1").should == '["a", ["a"], "b", ["b"]]'
    end
  end

  describe ".filter_map" do
    it "yields object" do
      ruby("spec/cases/filter_map.rb 2>&1").should == '["a", "c"]'
    end
  end

  describe ".any?" do
    it "returns true if any result is truthy" do
      ruby("spec/cases/any_true.rb").split(',').should == ['true'] * 3 * 2
    end

    it "returns false if all results are falsy" do
      ruby("spec/cases/any_false.rb").split(',').should == ['false'] * 3 * 3
    end
  end

  describe ".all?" do
    it "returns true if all results are truthy" do
      ruby("spec/cases/all_true.rb").split(',').should == ['true'] * 3 * 3
    end

    it "returns false if any result is falsy" do
      ruby("spec/cases/all_false.rb").split(',').should == ['false'] * 3 * 2
    end
  end

  describe ".each" do
    it "returns original array, works like map" do
      ruby("spec/cases/each.rb").should == 'a b c d'
    end

    it "passes result to :finish callback :in_processes`" do
      monitor = double('monitor', call: nil)
      monitor.should_receive(:call).once.with(:first, 0, 123)
      monitor.should_receive(:call).once.with(:second, 1, 123)
      monitor.should_receive(:call).once.with(:third, 2, 123)
      Parallel.each([:first, :second, :third], finish: monitor, in_processes: 3) { 123 }
    end

    it "passes result to :finish callback :in_threads`" do
      monitor = double('monitor', call: nil)
      monitor.should_receive(:call).once.with(:first, 0, 123)
      monitor.should_receive(:call).once.with(:second, 1, 123)
      monitor.should_receive(:call).once.with(:third, 2, 123)
      Parallel.each([:first, :second, :third], finish: monitor, in_threads: 3) { 123 }
    end

    it "does not use marshal_dump" do
      ruby("spec/cases/no_dump_with_each.rb 2>&1").should == 'no dump for resultno dump for each'
    end

    it "does not slow down with lots of GC work in threads" do
      Benchmark.realtime { ruby("spec/cases/no_gc_with_each.rb 2>&1") }.should <= 10
    end

    it "can modify in-place" do
      ruby("spec/cases/each_in_place.rb").should == 'ab'
    end

    worker_types.each do |type|
      it "works with SQLite in #{type}" do
        out = `WORKER_TYPE=#{type} ruby spec/cases/each_with_ar_sqlite.rb 2>&1`
        out.gsub!(/.* deprecated; use BigDecimal.*\n/, '')
        skip "unsupported" if type == "ractors"
        without_ractor_warning(out).should == "Parent: X\nParallel: XXX\nParent: X\n"
      end

      it "stops all workers when one fails in #{type}" do
        `METHOD=each WORKER_TYPE=#{type} ruby spec/cases/with_exception.rb 2>&1`.should =~ /^\d{4} raised$/
      end

      it "stops all workers when one raises Break in #{type}" do
        out = `METHOD=each WORKER_TYPE=#{type} ruby spec/cases/with_break.rb 2>&1`
        without_ractor_warning(out).should =~ /^\d{4} Parallel::Break raised - result nil$/
      end

      it "stops all workers when a start hook fails with #{type}" do
        out = `METHOD=each WORKER_TYPE=#{type} ruby spec/cases/with_exception_in_start.rb 2>&1`
        without_ractor_warning(out).should =~ /^\d{3} raised$/
      end

      it "does not add new work when a finish hook fails with #{type}" do
        out = `METHOD=each WORKER_TYPE=#{type} ruby spec/cases/with_exception_in_finish.rb 2>&1`
        without_ractor_warning(out).should =~ /^\d{4} raised$/
      end

      it "does not call the finish hook when a worker fails with #{type}" do
        out = `METHOD=each WORKER_TYPE=#{type} ruby spec/cases/with_exception_before_finish.rb 2>&1`
        without_ractor_warning(out).should == '3 called'
      end

      it "does not call the finish hook when a worker raises Break in #{type}" do
        out = `METHOD=each WORKER_TYPE=#{type} ruby spec/cases/with_break_before_finish.rb 2>&1`
        out.should =~ /^\d{3}(finish hook called){3} Parallel::Break raised$/
      end

      it "does not call the finish hook when a start hook fails with #{type}" do
        out = `METHOD=each WORKER_TYPE=#{type} ruby spec/cases/with_exception_in_start_before_finish.rb 2>&1`
        if type == "ractors"
          # we are calling on the main thread, so everything sleeps
          without_ractor_warning(out).should == "start 0\n"
        else
          out.split("\n").sort.join("\n").should == <<~OUT.rstrip
            call 3
            finish 2
            start 0
            start 1
            start 2
            start 3
          OUT
        end
      end

      it "sets Parallel.worker_number with #{type}" do
        skip "unsupported" if type == "ractors"
        out = `METHOD=each WORKER_TYPE=#{type} ruby spec/cases/with_worker_number.rb 2>&1`
        out.should =~ /\A[0123]+\z/
        ['0', '1', '2', '3'].each { |number| out.should include number }
      end
    end

    it "re-raises exceptions in work_direct" do
      `METHOD=each WORKER_TYPE=threads WORKER_SIZE=0 ruby spec/cases/with_exception.rb 2>&1`
        .should =~ /^1 raised$/
    end

    it "handles Break in work_direct" do
      `METHOD=each WORKER_TYPE=threads WORKER_SIZE=0 ruby spec/cases/with_break.rb 2>&1`
        .should =~ /^1 Parallel::Break raised - result nil$/
    end
  end

  describe ".each_with_index" do
    it "yields object and index" do
      ["a0b1", "b1a0"].should include ruby("spec/cases/each_with_index.rb 2>&1")
    end
  end

  describe "progress" do
    it "takes the title from :progress" do
      ruby("spec/cases/progress.rb 2>&1").sub(/=+/, '==').strip.should == "Doing stuff: |==|"
    end

    it "takes true from :progress" do
      `TITLE=true ruby spec/cases/progress.rb 2>&1`.sub(/=+/, '==').strip.should == "Progress: |==|"
    end

    it "works with :finish" do
      ruby("spec/cases/progress_with_finish.rb 2>&1").strip.sub(/=+/, '==').gsub(
        /\n+/,
        "\n"
      ).should == "Doing stuff: |==|\n100"
    end

    it "takes the title from :progress[:title] and passes options along" do
      ruby("spec/cases/progress_with_options.rb 2>&1").should =~ /Reticulating Splines ;+ \d+ ;+/
    end
  end

  ["lambda", "queue"].each do |thing|
    describe thing do
      let(:result) { "ITEM-1\nITEM-2\nITEM-3\n" }

      worker_types.each do |type|
        it "runs in #{type}" do
          out = ruby("spec/cases/with_#{thing}.rb #{type} 2>&1")
          without_ractor_warning(out).should == result
        end
      end

      it "refuses to use progress" do
        lambda {
          Parallel.map(-> {}, progress: "xxx") { raise "Ooops" } # rubocop:disable Lint/UnreachableLoop
        }.should raise_error("Progressbar can only be used with array like items")
      end
    end
  end

  it "fails when running with a prefilled queue without stop since there are no threads to fill it" do
    error = (RUBY_VERSION >= "2.0.0" ? "No live threads left. Deadlock?" : "deadlock detected (fatal)")
    ruby("spec/cases/fatal_queue.rb 2>&1").should include error
  end

  describe "GC" do
    def normalize(result)
      result = result.sub(/\{(.*)\}/, "\\1").split(", ")
      result.reject! { |x| x =~ /^(Hash|Array|String)=>(1|-1|-2)$/ }
      result.reject! { |x| x =~ /^(Thread::Mutex)=>(1)$/ } if RUBY_VERSION >= "3.3"
      result
    end

    worker_types.each do |type|
      it "does not leak memory in #{type}" do
        pending if RUBY_ENGINE == 'jruby' # lots of objects ... GC does not seem to work ...
        options = (RUBY_ENGINE == 'jruby' ? "-X+O" : "")
        result = ruby("#{options} spec/cases/profile_memory.rb #{type} 2>&1").strip.split("\n").last
        normalize(result).should == []
      end
    end
  end
end
