require File.dirname(__FILE__) + '/spec_helper'

FAKE_RAILS_ROOT = '/tmp/pspecs/fixtures'

describe ParallelSpecs do
  def size_of(group)
    group.inject(0) { |sum, spec| sum += File.stat(spec).size }
  end
  
  describe :specs_in_groups_of do
    before :all do
      system "rm -rf #{FAKE_RAILS_ROOT}; mkdir -p #{FAKE_RAILS_ROOT}/spec/temp"

      1.upto(100) do |i|
        size = 100 * i
        File.open("#{FAKE_RAILS_ROOT}/spec/temp/x#{i}_spec.rb", 'w') { |f| f.puts 'x' * size }
      end
    end

    it "finds all specs" do
      found = ParallelSpecs.specs_in_groups(FAKE_RAILS_ROOT, 1)
      all = [ Dir["#{FAKE_RAILS_ROOT}/spec/**/*_spec.rb"] ]
      (found.flatten - all.flatten).should == []
    end

    it "partitions them into groups by equal size" do
      groups = ParallelSpecs.specs_in_groups(FAKE_RAILS_ROOT, 2)
      groups.size.should == 2
      group0 = size_of(groups[0])
      group1 = size_of(groups[1])
      diff = group0 * 0.1
      group0.should be_close(group1, diff)
    end
    
    it 'should partition correctly with a group size of 4' do
      groups = ParallelSpecs.specs_in_groups(FAKE_RAILS_ROOT, 4)
      groups.size.should == 4
      group_size = size_of(groups[0])
      diff = group_size * 0.1     
      group_size.should be_close(size_of(groups[1]), diff)
      group_size.should be_close(size_of(groups[2]), diff)
      group_size.should be_close(size_of(groups[3]), diff)
    end

    it 'should partition correctly with an uneven group size' do
      groups = ParallelSpecs.specs_in_groups(FAKE_RAILS_ROOT, 3)
      groups.size.should == 3
      group_size = size_of(groups[0])
      diff = group_size * 0.1
      group_size.should be_close(size_of(groups[1]), diff)
      group_size.should be_close(size_of(groups[2]), diff)
    end
  end

  describe :run_tests do
    it "uses TEST_ENV_NUMBER=blank when called for process 0" do
      ParallelSpecs.should_receive(:open).with{|x|x=~/TEST_ENV_NUMBER= /}.and_return mock(:gets=>false)
      ParallelSpecs.run_tests(['xxx'],0)
    end

    it "uses TEST_ENV_NUMBER=2 when called for process 1" do
      ParallelSpecs.should_receive(:open).with{|x| x=~/TEST_ENV_NUMBER=2/}.and_return mock(:gets=>false)
      ParallelSpecs.run_tests(['xxx'],1)
    end

    it "runs with color when called from cmdline" do
      ParallelSpecs.should_receive(:open).with{|x| x=~/RSPEC_COLOR=1/}.and_return mock(:gets=>false)
      $stdout.should_receive(:tty?).and_return true
      ParallelSpecs.run_tests(['xxx'],1)
    end

    it "runs without color when not called from cmdline" do
      ParallelSpecs.should_receive(:open).with{|x| x !~ /RSPEC_COLOR/}.and_return mock(:gets=>false)
      $stdout.should_receive(:tty?).and_return false
      ParallelSpecs.run_tests(['xxx'],1)
    end

    it "returns the output" do
      io = open('spec/spec_helper.rb')
      ParallelSpecs.stub!(:print)
      ParallelSpecs.should_receive(:open).and_return io
      ParallelSpecs.run_tests(['xxx'],1).should =~ /\$LOAD_PATH << File/
    end
  end

  describe :find_results do
    it "finds multiple results in spec output" do
      output = <<EOF
....F...
..
failute fsddsfsd
...
ff.**..
0 examples, 0 failures, 0 pending
ff.**..
1 examples, 1 failures, 1 pending
EOF

      ParallelSpecs.find_results(output).should == ['0 examples, 0 failures, 0 pending','1 examples, 1 failures, 1 pending']
    end

    it "is robust against scrambeled output" do
      output = <<EOF
....F...
..
failute fsddsfsd
...
ff.**..
0 exFampl*es, 0 failures, 0 pend.ing
ff.**..
1 exampF.les, 1 failures, 1 pend.ing
EOF

      ParallelSpecs.find_results(output).should == ['0 examples, 0 failures, 0 pending','1 examples, 1 failures, 1 pending']
    end
  end

  describe :failed do
    it "fails with single failed specs" do
      ParallelSpecs.failed?(['0 examples, 0 failures, 0 pending','1 examples, 1 failures, 1 pending']).should == true
    end

    it "fails with multiple failed specs" do
      ParallelSpecs.failed?(['0 examples, 1 failures, 0 pending','1 examples, 1 failures, 1 pending']).should == true
    end

    it "does not fail with successful specs" do
      ParallelSpecs.failed?(['0 examples, 0 failures, 0 pending','1 examples, 0 failures, 1 pending']).should == false
    end
  end
end