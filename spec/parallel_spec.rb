require File.expand_path('spec/spec_helper')

describe Parallel do
  def time_taken
    t = Time.now.to_f
    yield
    Time.now.to_f - t
  end

  describe :processor_count do
    it "returns a number" do
      (1..999).should include(Parallel.processor_count)
    end

    if RUBY_PLATFORM =~ /darwin10/
      it 'works if hwprefs in not available' do
        Parallel.should_receive(:hwprefs_available?).and_return false
        (1..999).should include(Parallel.processor_count)
      end
    end
  end

  describe :in_processes do
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
        Thread.new do
          `ruby spec/cases/parallel_start_and_kill.rb`
        end
        sleep 1
        running_processes = `ps -f`.split("\n").map{ |line| line.split(/\s+/) }
        pid_index = running_processes.detect{ |line| line.include?("UID") }.index("UID") + 1
        parent_pid = running_processes.detect{ |line| line.grep(/(0|)0:00(:|.)00/).any? and line.include?("ruby") }[pid_index]
        `kill -2 #{parent_pid}` #simulates Ctrl+c
        sleep 1
      }.should_not change{`ps`.split("\n").size}
      }.should <= 3
    end

    it "saves time" do
      time_taken{
        `ruby spec/cases/parallel_sleeping_2.rb`
      }.should < 3.5
    end

    it "raises when one of the processes raises" do
      `ruby spec/cases/parallel_raise.rb`.strip.should == 'TEST'
    end

    it 'can handle to high fork rate' do
      `ruby spec/cases/parallel_high_fork_rate.rb`.should == 'OK'
    end

    it 'does not leave processes behind while running' do
      `ruby spec/cases/closes_processes_at_runtime.rb`.should == 'OK'
    end
  end

  describe :in_threads do
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

  describe :map do
    it "saves time" do
      time_taken{
      `ruby spec/cases/parallel_map_sleeping.rb`
      }.should <= 3.5
    end

    it "executes with given parameters" do
      `ruby spec/cases/parallel_map.rb`.should == "-a- -b- -c- -d-"
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

    it 'joins all workers, when one fails in process' do
      `ruby spec/cases/map_with_processes_and_exceptions.rb 2>&1`.should =~ /^\d{4} all joined raised$/
    end

    it 'joins all workers, when one fails in thread' do
      `ruby spec/cases/map_with_threads_and_exceptions.rb 2>&1`.should =~ /^\d{0,4} all joined raised$/
    end

    it "can run with 0 threads" do
      Thread.should_not_receive(:exclusive)
      Parallel.map([1,2,3,4,5,6,7,8,9], :in_threads => 0){|x| x+2 }.should == [3,4,5,6,7,8,9,10,11]
    end

    it "can run with 0 processes" do
      Process.should_not_receive(:fork)
      Parallel.map([1,2,3,4,5,6,7,8,9], :in_processes => 0){|x| x+2 }.should == [3,4,5,6,7,8,9,10,11]
    end
  end

  describe :map_with_index do
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

  describe :each do
    it "returns original array, works like map" do
      `ruby spec/cases/each.rb`.should == 'a b c d'
    end

    it "does not use marshal_dump" do
      `ruby spec/cases/no_dump_with_each.rb 2>&1`.should == 'no dump for resultno dump for each'
    end
  end

  describe :each_with_index do
    it "yields object and index" do
      `ruby spec/cases/each_with_index.rb 2>&1`.should == 'a0b1'
    end
  end
end
