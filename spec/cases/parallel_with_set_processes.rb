require File.expand_path('spec/spec_helper')

x = Parallel.in_processes(5) do
  "HELLO"
end
puts x