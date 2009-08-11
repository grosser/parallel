#this file has to be run on its own or it messes up all the other tests...
#spec spec/forking_spec_single.rb

require File.dirname(__FILE__) + '/spec_helper'

describe Parallel do
  describe :in_parallel do
    it "executes with parameters and returns the output" do
      text = "HELLO"
      result = Parallel.in_parallel(3) do |i|
        "#{i}:#{text}"
      end
      result.should == ["0:HELLO","1:HELLO","2:HELLO"]
    end

    it "saves time" do
      t = Time.now
      Parallel.in_parallel(10) do |i|
        sleep 2
      end
      Time.now.should be_close(t, 5)
    end
  end
end