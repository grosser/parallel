require 'spec/spec_helper.rb'

Parallel.in_processes(5) do
  sleep 2
end