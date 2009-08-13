require 'spec/spec_helper.rb'

x = Parallel.in_parallel(5) do
  "HELLO"
end
puts x