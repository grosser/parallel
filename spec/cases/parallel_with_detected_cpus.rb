require 'spec/spec_helper.rb'

x = Parallel.in_processes do
  "HELLO"
end
puts x