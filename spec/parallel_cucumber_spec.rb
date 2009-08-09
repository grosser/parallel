require File.dirname(__FILE__) + '/spec_helper'

describe ParallelCucumber do
  test_tests_in_groups(ParallelCucumber, 'features', ".feature")

  describe :run_tests do
    it "uses TEST_ENV_NUMBER=blank when called for process 0" do
      ParallelCucumber.should_receive(:open).with{|x|x=~/TEST_ENV_NUMBER= /}.and_return mock(:gets=>false)
      ParallelCucumber.run_tests(['xxx'],0)
    end

    it "uses TEST_ENV_NUMBER=2 when called for process 1" do
      ParallelCucumber.should_receive(:open).with{|x| x=~/TEST_ENV_NUMBER=2/}.and_return mock(:gets=>false)
      ParallelCucumber.run_tests(['xxx'],1)
    end

    it "returns the output" do
      io = open('spec/spec_helper.rb')
      ParallelCucumber.stub!(:print)
      ParallelCucumber.should_receive(:open).and_return io
      ParallelCucumber.run_tests(['xxx'],1).should =~ /\$LOAD_PATH << File/
    end
  end

  describe :find_results do
    it "finds multiple results in test output" do
      output = <<EOF
And I should not see "/en/"                                       # features/step_definitions/webrat_steps.rb:87

7 scenarios (3 failed, 4 passed)
33 steps (3 failed, 2 skipped, 28 passed)
/apps/rs/features/signup.feature:2
    Given I am on "/"                                           # features/step_definitions/common_steps.rb:12
    When I click "register"                                     # features/step_definitions/common_steps.rb:6
    And I should have "2" emails                                # features/step_definitions/user_steps.rb:25

4 scenarios (4 passed)
40 steps (40 passed)

EOF
      ParallelCucumber.find_results(output).should == ["33 steps (3 failed, 2 skipped, 28 passed)", "40 steps (40 passed)"]
    end
  end

  describe :failed do
    it "fails with single failed" do
      ParallelCucumber.failed?(['40 steps (40 passed)','33 steps (3 failed, 2 skipped, 28 passed)']).should == true
    end

    it "fails with multiple failed tests" do
      ParallelCucumber.failed?(['33 steps (3 failed, 2 skipped, 28 passed)','33 steps (3 failed, 2 skipped, 28 passed)']).should == true
    end

    it "does not fail with successful tests" do
      ParallelCucumber.failed?(['40 steps (40 passed)','40 steps (40 passed)']).should == false
    end

    it "does not fail with 0 failures" do
      ParallelCucumber.failed?(['40 steps (40 passed 0 failed)','40 steps (40 passed)']).should == false
    end

    it "does fail with 10 failures" do
      ParallelCucumber.failed?(['40 steps (40 passed 10 failed)','40 steps (40 passed)']).should == true
    end
  end
end