require File.expand_path('spec/spec_helper')

Parallel.in_processes(2) do
  sleep 10
  puts "I should have been killed earlier..."
end