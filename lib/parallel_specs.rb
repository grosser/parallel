module ParallelSpecs
  extend self

  #find all specs and partition them into groups
  def specs_in_groups(root, num)
    specs = (Dir["#{root}/spec/**/*_spec.rb"]).sort
    
    groups = []
    num.times{|i| groups[i]=[]}
    
    loop do
      num.times do |i|
        return groups if specs.empty?
        groups[i] << specs.shift
      end
    end
  end

  def run_tests(test_files, process_number)
    cmd = "export RAILS_ENV=test ; export TEST_ENV_NUMBER=#{process_number==0?'':process_number+1} ; export RSPEC_COLOR=1 ; script/spec -O spec/spec.opts #{test_files*' '}"
    f = open("|#{cmd}")
    while out = f.gets(".")
      print out
    end
  end
end