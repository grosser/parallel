#this file has to be run on its own or it messes up all the other tests...
#spec spec/forking_spec_single.rb

require File.dirname(__FILE__) + '/spec_helper'

describe ParallelTests do
  describe :in_parallel do
    it "executes with parameters and returns the output" do
      text = "HELLO"
      result = ParallelTests.in_parallel(3) do |i|
        "#{i}:#{text}"
      end
      result.should == ["0:HELLO","1:HELLO","2:HELLO"]
    end
  end
end