require 'spec/spec_helper.rb'

x = 'yes'

Parallel.in_processes(2) do
  x = 'no'
end
print x