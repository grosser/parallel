require File.expand_path('spec/spec_helper')

x = 'yes'

Parallel.in_processes(2) do
  x = 'no'
end
print x