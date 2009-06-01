require File.dirname(__FILE__)+'/spec_helper'

FAKE_RAILS_ROOT = File.dirname(__FILE__)+'/fixtures'

describe ParallelSpecs do
  def fixture_exist? file
    File.exist?("#{FAKE_RAILS_ROOT}/#{file}")
  end

  describe :specs_in_groups_of do
    it "finds all specs" do
      ParallelSpecs.specs_in_groups(FAKE_RAILS_ROOT,1).should == [["./spec/fixtures/spec/a/x2_spec.rb","./spec/fixtures/spec/x1_spec.rb"]]
    end

    it "partitions them into groups" do
      ParallelSpecs.specs_in_groups(FAKE_RAILS_ROOT,2).should == [["./spec/fixtures/spec/a/x2_spec.rb"],["./spec/fixtures/spec/x1_spec.rb"]]
    end

    it "leaves spots empty when spec number does not match" do
      ParallelSpecs.specs_in_groups(FAKE_RAILS_ROOT,3).should == [["./spec/fixtures/spec/a/x2_spec.rb"],["./spec/fixtures/spec/x1_spec.rb"],[]]
    end
  end
end