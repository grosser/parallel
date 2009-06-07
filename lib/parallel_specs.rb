module ParallelSpecs
  extend self

  # finds all specs and partitions them into groups
  def specs_in_groups(root, num)
    specs = (Dir["#{root}/spec/**/*_spec.rb"]).sort
    return [ specs ] if num == 1
              
    specs_with_sizes, total_size = find_sizes(specs)

    groups = []
    num.times { |i| groups[i] = [] }
    
    group_size = (total_size / num.to_f)
        
    i = 0
    current_size = 0
    specs_with_sizes.each do |spec|
      current_size += spec[0]
      i += 1 if current_size > group_size * (i+1)     
      groups[i] << spec[1]
    end
    
    groups
  end

  def run_tests(test_files, process_number)
    cmd = "export RAILS_ENV=test ; export TEST_ENV_NUMBER=#{process_number==0?'':process_number+1} ; export RSPEC_COLOR=1 ; script/spec -O spec/spec.opts #{test_files*' '}"
    f = open("|#{cmd}")
    while out = f.gets(".")
      print out
      STDOUT.flush
    end
  end
  
  private
  
  def find_sizes(specs)
    total_size = 0
    specs_with_sizes = []
    specs.each do |file|
      size = File.stat(file).size
      specs_with_sizes << [ size, file ]
      total_size += size
    end
    return specs_with_sizes, total_size    
  end
end
