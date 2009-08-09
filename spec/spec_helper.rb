# ---- requirements
$LOAD_PATH << File.expand_path("../lib", File.dirname(__FILE__))

FAKE_RAILS_ROOT = '/tmp/pspecs/fixtures'

require 'parallel_specs'
require 'parallel_cucumber'

def size_of(group)
  group.inject(0) { |sum, test| sum += File.stat(test).size }
end

def test_tests_in_groups(klass, folder, suffix)
  test_root = "#{FAKE_RAILS_ROOT}/#{folder}"

  describe :tests_in_groups do
    before :all do
      system "rm -rf #{FAKE_RAILS_ROOT}; mkdir -p #{test_root}/temp"

      1.upto(100) do |i|
        size = 100 * i
        File.open("#{test_root}/temp/x#{i}#{suffix}", 'w') { |f| f.puts 'x' * size }
      end
    end

    it "finds all tests" do
      found = klass.tests_in_groups(test_root, 1)
      all = [ Dir["#{test_root}/**/*#{suffix}"] ]
      (found.flatten - all.flatten).should == []
    end

    it "partitions them into groups by equal size" do
      groups = klass.tests_in_groups(test_root, 2)
      groups.size.should == 2
      group0 = size_of(groups[0])
      group1 = size_of(groups[1])
      diff = group0 * 0.1
      group0.should be_close(group1, diff)
    end

    it 'should partition correctly with a group size of 4' do
      groups = klass.tests_in_groups(test_root, 4)
      groups.size.should == 4
      group_size = size_of(groups[0])
      diff = group_size * 0.1
      group_size.should be_close(size_of(groups[1]), diff)
      group_size.should be_close(size_of(groups[2]), diff)
      group_size.should be_close(size_of(groups[3]), diff)
    end

    it 'should partition correctly with an uneven group size' do
      groups = klass.tests_in_groups(test_root, 3)
      groups.size.should == 3
      group_size = size_of(groups[0])
      diff = group_size * 0.1
      group_size.should be_close(size_of(groups[1]), diff)
      group_size.should be_close(size_of(groups[2]), diff)
    end
  end
end