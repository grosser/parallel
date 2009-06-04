module ParallelSpecs
  extend self

  #find all specs and partition them into groups
  def specs_in_groups(root, num)
    specs = (Dir["#{root}/spec/**/*_spec.rb"]).sort
    
    groups = []
    num.times{|i| groups[i]=[]}

    # TODO:
    # - test it
    # - make it work with more than 2
    
    total_size = 0
    specs_with_sizes = []
    specs.each do |file|
      size = File.stat(file).size
      specs_with_sizes << [ size, file ]
      total_size += size
    end
    
    index = 0
    current_size = 0
    specs_with_sizes.each do |spec|
      current_size += spec[0]
      if index == 0 && current_size > total_size / 2
        index += 1
      end
      groups[index] << spec[1]
    end
    
    groups
    # 
    # loop do
    #   num.times do |i|
    #     return groups if specs.empty?
    #     groups[i] << specs.shift
    #   end
    # end
  end
end