require File.expand_path('spec/spec_helper')

describe Parallel do
  def time_taken
    t = Time.now.to_f
    yield
    Time.now.to_f - t
  end

  def kill_process_with_name(file)
    running_processes = `ps -f`.split("\n").map{ |line| line.split(/\s+/) }
    pid_index = running_processes.detect { |p| p.include?("UID") }.index("UID") + 1
    parent_pid = running_processes.detect { |p| p.include?(file) and not p.include?("sh") }[pid_index]
    `kill -2 #{parent_pid}`
  end

  describe ".processor_count" do
    it "returns a number" do
      (1..999).should include(Parallel.processor_count)
    end

    if RUBY_PLATFORM =~ /darwin10/
      it 'works if hwprefs in not available' do
        Parallel.should_receive(:hwprefs_available?).and_return false
        (1..999).should include(Parallel.processor_count)
      end
    end

    it "defaults to 1 if we don't know better" do
      `ruby spec/cases/host_os_override_processor_count.rb 2>/dev/null`.to_i.should == 1
    end
  end

  describe ".physical_processor_count" do
    it "returns a number" do
      (1..999).should include(Parallel.physical_processor_count)
    end

    it "is half or same as normal cpu" do
      pending if ENV["TRAVIS"]
      [Parallel.processor_count, Parallel.processor_count / 2].should include Parallel.physical_processor_count
    end
  end

  describe ".in_processes" do
    def cpus
      Parallel.processor_count
    end

    it "executes with detected cpus" do
      `ruby spec/cases/parallel_with_detected_cpus.rb`.should == "HELLO\n" * cpus
    end

    it "executes with detected cpus when nil was given" do
      `ruby spec/cases/parallel_with_nil_uses_detected_cpus.rb`.should == "HELLO\n" * cpus
    end

    it "set amount of parallel processes" do
      `ruby spec/cases/parallel_with_set_processes.rb`.should == "HELLO\n" * 5
    end

    it "does not influence outside data" do
      `ruby spec/cases/parallel_influence_outside_data.rb`.should == "yes"
    end

    it "kills the processes when the main process gets killed through ctrl+c" do
      time_taken{
        lambda{
          t = Thread.new { `ruby spec/cases/parallel_start_and_kill.rb PROCESS` }
          sleep 1
          kill_process_with_name("spec/cases/parallel_start_and_kill.rb") #simulates Ctrl+c
          sleep 1
          puts t.value
        }.should_not change{`ps`.split("\n").size}
      }.should <= 3
    end

    it "kills the threads when the main process gets killed through ctrl+c" do
      time_taken{
        lambda{
          Thread.new { `ruby spec/cases/parallel_start_and_kill.rb THREAD` }
          sleep 1
          kill_process_with_name("spec/cases/parallel_start_and_kill.rb") #simulates Ctrl+c
          sleep 1
        }.should_not change{`ps`.split("\n").size}
      }.should <= 3
    end

    it "does not kill anything on ctrl+c when everything has finished" do
      time_taken do
        t = Thread.new { `ruby spec/cases/parallel_fast_exit.rb 2>&1` }
        sleep 2
        kill_process_with_name("spec/cases/parallel_fast_exit.rb") #simulates Ctrl+c
        sleep 1
        result = t.value
        result.scan(/I finished/).size.should == 3
        result.should_not include("Parallel execution interrupted")
      end.should <= 4
    end

    it "saves time" do
      time_taken{
        `ruby spec/cases/parallel_sleeping_2.rb`
      }.should < 3.5
    end

    it "raises when one of the processes raises" do
      `ruby spec/cases/parallel_raise.rb`.strip.should == 'TEST'
    end

    it "can raise an undumpable exception" do
      `ruby spec/cases/parallel_raise_undumpable.rb`.strip.should include('Undumpable Exception')
    end

    it 'can handle to high fork rate' do
      `ruby spec/cases/parallel_high_fork_rate.rb`.should == 'OK'
    end

    it 'does not leave processes behind while running' do
      `ruby spec/cases/closes_processes_at_runtime.rb`.should == 'OK'
    end

    it "does not open unnecessary pipes" do
      open_pipes = `lsof | grep pipe | wc -l`.to_i
      max_pipes = `ruby spec/cases/count_open_pipes.rb`.to_i
      (max_pipes - open_pipes).should < 400
    end
  end

  describe ".in_threads" do
    it "saves time" do
      time_taken{
        Parallel.in_threads(3){ sleep 2 }
      }.should < 3
    end

    it "does not create new processes" do
      lambda{ Thread.new{ Parallel.in_threads(2){sleep 1} } }.should_not change{`ps`.split("\n").size}
    end

    it "returns results as array" do
      Parallel.in_threads(4){|i| "XXX#{i}"}.should == ["XXX0",'XXX1','XXX2','XXX3']
    end

    it "raises when a thread raises" do
      lambda{ Parallel.in_threads(2){|i| raise "TEST"} }.should raise_error("TEST")
    end
  end

  describe ".map" do
    it "saves time" do
      time_taken{
      `ruby spec/cases/parallel_map_sleeping.rb`
      }.should <= 3.5
    end

    it "executes with given parameters" do
      `ruby spec/cases/parallel_map.rb`.should == "-a- -b- -c- -d-"
    end

    it "can dump/load complex objects" do
      `ruby spec/cases/parallel_map_complex_objects.rb`.should == "YES"
    end

    it "starts new process imediatly when old exists" do
      time_taken{
      `ruby spec/cases/parallel_map_uneven.rb`
      }.should <= 3.5
    end

    it "does not flatten results" do
      Parallel.map([1,2,3], :in_threads=>2){|x| [x,x]}.should == [[1,1],[2,2],[3,3]]
    end

    it "can run in threads" do
      Parallel.map([1,2,3,4,5,6,7,8,9], :in_threads=>4){|x| x+2 }.should == [3,4,5,6,7,8,9,10,11]
    end

    it 'supports all Enumerable-s' do
      `ruby spec/cases/parallel_map_range.rb`.should == '[1, 2, 3, 4, 5]'
    end

    it 'handles nested arrays and nil correctly' do
      `ruby spec/cases/map_with_nested_arrays_and_nil.rb`.should == '[nil, [2, 2], [[3], [3]]]'
    end

    it 'stops all workers when one fails in process' do
      `ruby spec/cases/map_with_processes_and_exceptions.rb 2>&1`.should =~ /^\d{4} raised$/
    end

    it 'stops all workers when one fails in thread' do
      `ruby spec/cases/map_with_threads_and_exceptions.rb 2>&1`.should =~ /^\d{0,4} raised$/
    end

    it 'stops all workers when one raises Break in process' do
      `ruby spec/cases/map_with_processes_and_break.rb 2>&1`.should =~ /^\d{4} Parallel::Break raised - result nil$/
    end

    it 'stops all workers when one raises Break in thread' do
      `ruby spec/cases/map_with_threads_and_break.rb 2>&1`.should =~ /^\d{4} Parallel::Break raised - result nil$/
    end

    it "can run with 0 threads" do
      Thread.should_not_receive(:exclusive)
      Parallel.map([1,2,3,4,5,6,7,8,9], :in_threads => 0){|x| x+2 }.should == [3,4,5,6,7,8,9,10,11]
    end

    it "can run with 0 processes" do
      Process.should_not_receive(:fork)
      Parallel.map([1,2,3,4,5,6,7,8,9], :in_processes => 0){|x| x+2 }.should == [3,4,5,6,7,8,9,10,11]
    end

    it "notifies when an item of work is dispatched to a worker process" do
      monitor = double('monitor', :call => nil)
      monitor.should_receive(:call).once.with(:first, 0)
      monitor.should_receive(:call).once.with(:second, 1)
      monitor.should_receive(:call).once.with(:third, 2)
      Parallel.map([:first, :second, :third], :start => monitor, :in_processes => 3) {}
    end

    it "notifies when an item of work is completed by a worker process" do
      monitor = double('monitor', :call => nil)
      monitor.should_receive(:call).once.with(:first, 0)
      monitor.should_receive(:call).once.with(:second, 1)
      monitor.should_receive(:call).once.with(:third, 2)
      Parallel.map([:first, :second, :third], :finish => monitor, :in_processes => 3) {}
    end

    it "notifies when an item of work is dispatched to a threaded worker" do
      monitor = double('monitor', :call => nil)
      monitor.should_receive(:call).once.with(:first, 0)
      monitor.should_receive(:call).once.with(:second, 1)
      monitor.should_receive(:call).once.with(:third, 2)
      Parallel.map([:first, :second, :third], :start => monitor, :in_threads => 3) {}
    end

    it "notifies when an item of work is completed by a threaded worker" do
      monitor = double('monitor', :call => nil)
      monitor.should_receive(:call).once.with(:first, 0)
      monitor.should_receive(:call).once.with(:second, 1)
      monitor.should_receive(:call).once.with(:third, 2)
      Parallel.map([:first, :second, :third], :finish => monitor, :in_threads => 3) {}
    end

    it "spits out a useful error when a worker dies before read" do
      `ruby spec/cases/map_with_killed_worker_before_read.rb 2>&1`.should include "DEAD"
    end

    it "spits out a useful error when a worker dies before write" do
      `ruby spec/cases/map_with_killed_worker_before_write.rb 2>&1`.should include "DEAD"
    end
  end

  describe ".map_with_index" do
    it "yields object and index" do
      `ruby spec/cases/map_with_index.rb 2>&1`.should == 'a0b1'
    end

    it "does not crash with empty set" do
      `ruby spec/cases/map_with_index_empty.rb 2>&1`.should == ''
    end

    it "can run with 0 threads" do
      Thread.should_not_receive(:exclusive)
      Parallel.map_with_index([1,2,3,4,5,6,7,8,9], :in_threads => 0){|x,i| x+2 }.should == [3,4,5,6,7,8,9,10,11]
    end

    it "can run with 0 processes" do
      Process.should_not_receive(:fork)
      Parallel.map_with_index([1,2,3,4,5,6,7,8,9], :in_processes => 0){|x,i| x+2 }.should == [3,4,5,6,7,8,9,10,11]
    end
  end

  describe ".each" do
    it "returns original array, works like map" do
      `ruby spec/cases/each.rb`.should == 'a b c d'
    end

    it "does not use marshal_dump" do
      `ruby spec/cases/no_dump_with_each.rb 2>&1`.should == 'no dump for resultno dump for each'
    end
  end

  describe ".each_with_index" do
    it "yields object and index" do
      `ruby spec/cases/each_with_index.rb 2>&1`.should == 'a0b1'
    end
  end
end
