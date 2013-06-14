require File.expand_path('spec/spec_helper')

Parallel.map([1,2,3], :in_processes => 2) do
  puts "I finished..."
end

sleep 10
