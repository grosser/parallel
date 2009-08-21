require File.dirname(__FILE__) + '/spec_helper'

describe ParallelSpecs do
  test_tests_in_groups(ParallelSpecs, 'spec', '_spec.rb')

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

    it "runs script/spec when script/spec can be found" do
      File.should_receive(:exist?).with('script/spec').and_return true
      ParallelSpecs.should_receive(:open).with{|x| x =~ %r{script/spec}}.and_return mock(:gets=>false)
      ParallelSpecs.run_tests(['xxx'],1)
    end

    it "runs spec when script/spec cannot be found" do
      ParallelSpecs.should_receive(:open).with{|x| x !~ %r{script/spec}}.and_return mock(:gets=>false)
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
1 example, 1 failure, 1 pending
EOF

      ParallelSpecs.find_results(output).should == ['0 examples, 0 failures, 0 pending','1 example, 1 failure, 1 pending']
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
      ParallelSpecs.failed?(['0 examples, 0 failures, 0 pending','1 examples, 1 failure, 1 pending']).should == true
    end

    it "fails with multiple failed specs" do
      ParallelSpecs.failed?(['0 examples, 1 failure, 0 pending','1 examples, 111 failures, 1 pending']).should == true
    end

    it "does not fail with successful specs" do
      ParallelSpecs.failed?(['0 examples, 0 failures, 0 pending','1 examples, 0 failures, 1 pending']).should == false
    end

    it "does fail with 10 failures" do
      ParallelSpecs.failed?(['0 examples, 10 failures, 0 pending','1 examples, 0 failures, 1 pending']).should == true
    end

  end
end