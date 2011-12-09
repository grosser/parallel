require File.expand_path('spec/spec_helper')

Parallel.in_processes(5) do
  sleep 2
end
