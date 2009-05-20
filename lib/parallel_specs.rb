module ParallelSpecs
  extend self

  def with_copied_envs(root, num_processes)
    envs = []
    2.upto(num_processes){|i| envs << "#{root}/config/environments/test#{i}.rb"}
    envs.each do |file|
      File.open(file, 'w') do |f|
        f.puts "#DO NOT MODIFY--WILL BE OVERWRITTEN!!!"
        f.puts File.read("#{root}/config/environments/test.rb")
      end
    end
    yield
    envs.each{|f| `rm #{f}`}
  end

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
end