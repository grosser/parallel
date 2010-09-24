require File.expand_path('spec/spec_helper')

x = Parallel.in_processes(nil) do
  "HELLO"
end
puts x