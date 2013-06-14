require File.expand_path('spec/spec_helper')

method = case ARGV[0]
when "PROCESS" then :in_processes
when "THREAD" then :in_threads
else raise "Learn to use this!"
end

Parallel.send(method, 2) do
  sleep 10
  puts "I should have been killed earlier..."
end
