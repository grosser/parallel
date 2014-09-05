require './spec/cases/helper'

results = Parallel.map(Array.new(20), :in_processes => 20) do
  `lsof | grep pipe | wc -l`.to_i
end
puts results.max
