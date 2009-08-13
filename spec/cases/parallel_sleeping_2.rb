require 'spec/spec_helper.rb'

Parallel.in_parallel(5) do
  sleep 2
end