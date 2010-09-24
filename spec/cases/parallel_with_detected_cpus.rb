require File.expand_path('spec/spec_helper')

x = Parallel.in_processes do
  "HELLO"
end
puts x