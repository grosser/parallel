require File.dirname(__FILE__) + '/spec_helper'

describe ParallelTests do
  def size_of(group)
    group.inject(0) { |sum, test| sum += File.stat(test).size }
  end

  describe :tests_in_groups_of do
    def spec_root
      "#{FAKE_RAILS_ROOT}/test/"
    end

    before :all do
      system "rm -rf #{FAKE_RAILS_ROOT}; mkdir -p #{FAKE_RAILS_ROOT}/test/temp"

      1.upto(100) do |i|
        size = 100 * i
        File.open("#{FAKE_RAILS_ROOT}/test/temp/x#{i}_test.rb", 'w') { |f| f.puts 'x' * size }
      end
    end

    it "finds all tests" do
      found = ParallelTests.tests_in_groups(spec_root, 1)
      all = [ Dir["#{FAKE_RAILS_ROOT}/test/**/*_test.rb"] ]
      (found.flatten - all.flatten).should == []
    end

    it "partitions them into groups by equal size" do
      groups = ParallelTests.tests_in_groups(spec_root, 2)
      groups.size.should == 2
      group0 = size_of(groups[0])
      group1 = size_of(groups[1])
      diff = group0 * 0.1
      group0.should be_close(group1, diff)
    end

    it 'should partition correctly with a group size of 4' do
      groups = ParallelTests.tests_in_groups(spec_root, 4)
      groups.size.should == 4
      group_size = size_of(groups[0])
      diff = group_size * 0.1
      group_size.should be_close(size_of(groups[1]), diff)
      group_size.should be_close(size_of(groups[2]), diff)
      group_size.should be_close(size_of(groups[3]), diff)
    end

    it 'should partition correctly with an uneven group size' do
      groups = ParallelTests.tests_in_groups(spec_root, 3)
      groups.size.should == 3
      group_size = size_of(groups[0])
      diff = group_size * 0.1
      group_size.should be_close(size_of(groups[1]), diff)
      group_size.should be_close(size_of(groups[2]), diff)
    end
  end

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
  end
end