require 'spec/spec_helper.rb'

x = Parallel.in_parallel do
  "HELLO"
end
puts x