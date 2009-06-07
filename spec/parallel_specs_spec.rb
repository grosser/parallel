require File.dirname(__FILE__)+'/spec_helper'

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
      ParallelSpecs.specs_in_groups(FAKE_RAILS_ROOT,1).should == 
                                    [ Dir["#{FAKE_RAILS_ROOT}/spec/**/*_spec.rb"] ]
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
end
