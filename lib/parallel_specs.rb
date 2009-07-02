module ParallelSpecs
  extend self

  # finds all specs and partitions them into groups
  def specs_in_groups(root, num)
    specs_with_sizes = find_specs_with_sizes(root)
    
    groups = []
    current_group = current_size = 0
    specs_with_sizes.each do |spec, size|
      current_size += size
      # inserts into next group if current is full and we are not in the last group
      if current_size > group_size(specs_with_sizes, num) and num > current_group + 1
        current_size = 0
        current_group += 1
      end
      groups[current_group] ||= []
      groups[current_group] << spec
    end
    groups
  end

  def run_tests(test_files, process_number)
    color = ($stdout.tty? ? 'export RSPEC_COLOR=1 ;' : '')#display color when we are in a terminal
    cmd = "export RAILS_ENV=test ; export TEST_ENV_NUMBER=#{process_number==0?'':process_number+1} ; #{color} script/spec -O spec/spec.opts #{test_files*' '}"
    execute_command(cmd)
  end

  def execute_command(cmd)
    f = open("|#{cmd}")
    all = ''
    while out = f.gets(".")#split by '.' because every test is a '.'
      all+=out
      print out
      STDOUT.flush
    end
    all
  end

  private

  def self.group_size(specs_with_sizes, num_groups)
    total_size = specs_with_sizes.inject(0) { |sum, spec| sum += spec[1] }
    total_size / num_groups.to_f
  end

  def self.find_specs_with_sizes(root)
    specs = Dir["#{root}/spec/**/*_spec.rb"].sort
    specs.map { |spec| [ spec, File.stat(spec).size ] }
  end
end
