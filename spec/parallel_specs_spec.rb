require File.dirname(__FILE__)+'/spec_helper'

FAKE_RAILS_ROOT = File.dirname(__FILE__)+'/fixtures/'

describe ParallelSpecs do
  def fixture_exist? file
    File.exist?(FAKE_RAILS_ROOT+file)
  end

  describe :with_copied_envs do
    it "calls the given block" do
      x = 'block not called'
      ParallelSpecs.with_copied_envs(FAKE_RAILS_ROOT, 2) do
        x = 'block called'
      end
      x.should == 'block called'
    end

    it "copies env files for each parallel process" do
      ParallelSpecs.with_copied_envs(FAKE_RAILS_ROOT, 3) do
        fixture_exist?('config/environments/test1.rb').should == false
        fixture_exist?('config/environments/test2.rb').should == true
        fixture_exist?('config/environments/test3.rb').should == true
        fixture_exist?('config/environments/test4.rb').should == false
      end
    end

    it "overwrites existing envs with new copies" do
      env2 = FAKE_RAILS_ROOT+'config/environments/test2.rb'
      File.open(env2,'w'){|f|f.print 'XXX'}

      ParallelSpecs.with_copied_envs(FAKE_RAILS_ROOT, 3) do
        File.read(env2).should_not == "XXX"
      end
    end

    it "adds comments to the copied files" do
      env2 = FAKE_RAILS_ROOT+'config/environments/test2.rb'
      File.open(env2,'w'){|f|f.print 'XXX'}

      ParallelSpecs.with_copied_envs(FAKE_RAILS_ROOT, 3) do
        pending
        File.readlines(env2)[0].should =~ /^#.*OVERWRITTEN/
      end
    end

    it "removes all env files after processing the block" do
      ParallelSpecs.with_copied_envs(FAKE_RAILS_ROOT, 3) do
      end
      
      fixture_exist?('config/environments/test1.rb').should == false
      fixture_exist?('config/environments/test2.rb').should == false
      fixture_exist?('config/environments/test3.rb').should == false
      fixture_exist?('config/environments/test4.rb').should == false
    end
  end
end