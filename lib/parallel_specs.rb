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
end