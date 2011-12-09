require File.expand_path('spec/spec_helper')

results = Parallel.map(Array.new(20), :in_processes => 20) do
  `lsof | grep pipe | wc -l`.to_i
end
puts results.max
