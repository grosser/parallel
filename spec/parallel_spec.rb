require File.dirname(__FILE__) + '/spec_helper'

describe Parallel do
  describe :in_processes do
    before do
      @cpus = Parallel.processor_count
    end

    it "executes with detected cpus" do
      `ruby spec/cases/parallel_with_detected_cpus.rb`.should == "HELLO\n" * @cpus
    end

    it "executes with detected cpus when nil was given" do
      `ruby spec/cases/parallel_with_nil_uses_detected_cpus.rb`.should == "HELLO\n" * @cpus
    end

    it "set ammount of parallel processes" do
      `ruby spec/cases/parallel_with_set_processes.rb`.should == "HELLO\n" * 5
    end

    it "does not influence outside data" do
      `ruby spec/cases/parallel_influence_outside_data.rb`.should == "yes"
    end

    it "kills the processes when the main process gets killed through ctrl+c" do
      t = Time.now
      lambda{
        Thread.new do
          `ruby spec/cases/parallel_start_and_kill.rb`
        end
        sleep 1
        running_processes = `ps -f`.split("\n").map{ |line| line.split(/\s+/) }
        uid_index         = running_processes.detect{ |line| line.include?("UID") }.index("UID") + 1
        parent            = running_processes.detect{ |line| line.grep(/(0|)0:00(:|.)00/).any? and line.include?("ruby") }[uid_index]
        `kill -2 #{parent}` #simulates Ctrl+c
      }.should_not change{`ps`.split("\n").size}
      Time.now.should be_close(t, 3)
    end

    it "saves time" do
      t = Time.now
      `ruby spec/cases/parallel_sleeping_2.rb`
      Time.now.should be_close(t, 3)
    end

    it "raises when one of the processes raises" do
      pending 'there is some kind of error, but not the original...'
      `ruby spec/cases/parallel_raise.rb`.should == 'TEST'
    end

    it 'can handle to high fork rate' do
      `ruby spec/cases/parallel_high_fork_rate.rb`.should == 'OK'
    end

    it 'it does not leave processes behind while running' do
      `ruby spec/cases/cloeses_processes_at_runtime.rb`.should == 'OK'
    end
  end

  describe :in_threads do
    it "saves time" do
      t = Time.now
      Parallel.in_threads(3){ sleep 2 }
      Time.now.should be_close(t, 3)
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
      t = Time.now
      `ruby spec/cases/parallel_map_sleeping.rb`
      Time.now.should be_close(t, 3)
    end

    it "executes with given parameters" do
      `ruby spec/cases/parallel_map.rb`.should == "-a- -b- -c- -d-"
    end

    it "starts new process imediatly when old exists" do
      t = Time.now
      `ruby spec/cases/parallel_map_uneven.rb`
      Time.now.should be_close(t, 3)
    end

    it "does not flatten results" do
      Parallel.map([1,2,3], :in_threads=>2){|x| [x,x]}.should == [[1,1],[2,2],[3,3]]
    end

    it "can run in threads" do
      Parallel.map([1,2,3,4,5,6,7,8,9], :in_threads=>4){|x| x+2 }.should == [3,4,5,6,7,8,9,10,11]
    end

    it 'supports ranges' do
      `ruby spec/cases/parallel_map_range.rb`.should == '12345'
    end
  end

  describe :map_with_index do
    it "yields object and index" do
      `ruby spec/cases/map_with_index.rb 2>&1`.should == 'a0b1'
    end

    it "does not crash with empty set" do
      `ruby spec/cases/map_with_index_empty.rb 2>&1`.should == ''
    end
  end

  describe :each do
    it "returns original array, works like map" do
      `ruby spec/cases/each.rb`.should == 'a b c d'
    end

    it "does not use marshal_dump" do
      `ruby spec/cases/no_dump_with_each.rb 2>&1`.should == 'not dumpable'
    end
  end

  describe :each_with_index do
    it "yields object and index" do
      `ruby spec/cases/each_with_index.rb 2>&1`.should == 'a0b1'
    end
  end

  describe :in_groups_of do
    it "works for empty" do
      Parallel.send(:in_groups_of, [], 3).should == []
    end

    it "works for smaller then count" do
      Parallel.send(:in_groups_of, [1,2], 3).should == [[1,2]]
    end

    it "works for count" do
      Parallel.send(:in_groups_of, [1,2,3], 3).should == [[1,2,3]]
    end

    it "works for larger than count" do
      Parallel.send(:in_groups_of, [1,2,3,4], 3).should == [[1,2,3],[4]]
    end
  end
end