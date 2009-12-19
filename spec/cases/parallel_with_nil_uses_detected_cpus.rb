require 'spec/spec_helper.rb'

x = Parallel.in_processes(nil) do
  "HELLO"
end
puts x