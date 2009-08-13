require 'spec/spec_helper.rb'

Parallel.in_processes(2) do
  sleep 10
  puts "I should have been killed earlier..."
end