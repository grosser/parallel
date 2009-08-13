require 'spec/spec_helper.rb'

x = 'yes'

Parallel.in_parallel(2) do
  x = 'no'
end
print x