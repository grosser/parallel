require File.dirname(__FILE__) + '/spec_helper'

describe ParallelTests do
  test_tests_in_groups(ParallelTests, 'test', '_test.rb')

  describe :run_tests do
    it "uses TEST_ENV_NUMBER=blank when called for process 0" do
      ParallelTests.should_receive(:open).with{|x|x=~/TEST_ENV_NUMBER= /}.and_return mock(:gets=>false)
      ParallelTests.run_tests(['xxx'],0)
    end

    it "uses TEST_ENV_NUMBER=2 when called for process 1" do
      ParallelTests.should_receive(:open).with{|x| x=~/TEST_ENV_NUMBER=2/}.and_return mock(:gets=>false)
      ParallelTests.run_tests(['xxx'],1)
    end

    it "returns the output" do
      io = open('spec/spec_helper.rb')
      ParallelTests.stub!(:print)
      ParallelTests.should_receive(:open).and_return io
      ParallelTests.run_tests(['xxx'],1).should =~ /\$LOAD_PATH << File/
    end
  end

  describe :find_results do
    it "finds multiple results in test output" do
      output = <<EOF
Loaded suite /opt/ruby-enterprise/lib/ruby/gems/1.8/gems/rake-0.8.4/lib/rake/rake_test_loader
Started
..............
Finished in 0.145069 seconds.

10 tests, 20 assertions, 0 failures, 0 errors
Loaded suite /opt/ruby-enterprise/lib/ruby/gems/1.8/gems/rake-0.8.4/lib/rake/rake_test_loader
Started
..............
Finished in 0.145069 seconds.

14 tests, 20 assertions, 0 failures, 0 errors

EOF

      ParallelTests.find_results(output).should == ['10 tests, 20 assertions, 0 failures, 0 errors','14 tests, 20 assertions, 0 failures, 0 errors']
    end

    it "is robust against scrambeled output" do
      output = <<EOF
Loaded suite /opt/ruby-enterprise/lib/ruby/gems/1.8/gems/rake-0.8.4/lib/rake/rake_test_loader
Started
..............
Finished in 0.145069 seconds.

10 tests, 20 assertions, 0 failures, 0 errors
Loaded suite /opt/ruby-enterprise/lib/ruby/gems/1.8/gems/rake-0.8.4/lib/rake/rake_test_loader
Started
..............
Finished in 0.145069 seconds.

14 te.dsts, 20 assertions, 0 failures, 0 errors
EOF

      ParallelTests.find_results(output).should == ['10 tests, 20 assertions, 0 failures, 0 errors','14 tedsts, 20 assertions, 0 failures, 0 errors']
    end
  end

  describe :failed do
    it "fails with single failed" do
      ParallelTests.failed?(['10 tests, 20 assertions, 0 failures, 0 errors','10 tests, 20 assertions, 1 failure, 0 errors']).should == true
    end

    it "fails with single error" do
      ParallelTests.failed?(['10 tests, 20 assertions, 0 failures, 1 errors','10 tests, 20 assertions, 0 failures, 0 errors']).should == true
    end

    it "fails with failed and error" do
      ParallelTests.failed?(['10 tests, 20 assertions, 0 failures, 1 errors','10 tests, 20 assertions, 1 failures, 1 errors']).should == true
    end

    it "fails with multiple failed tests" do
      ParallelTests.failed?(['10 tests, 20 assertions, 2 failures, 0 errors','10 tests, 1 assertion, 1 failures, 0 errors']).should == true
    end

    it "does not fail with successful tests" do
      ParallelTests.failed?(['10 tests, 20 assertions, 0 failures, 0 errors','10 tests, 20 assertions, 0 failures, 0 errors']).should == false
    end

    it "does fail with 10 failures" do
      ParallelTests.failed?(['10 tests, 20 assertions, 10 failures, 0 errors','10 tests, 20 assertions, 0 failures, 0 errors']).should == true
    end
  end
end