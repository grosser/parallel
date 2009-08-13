require 'spec/spec_helper.rb'

x = Parallel.in_processes(5) do
  "HELLO"
end
puts x