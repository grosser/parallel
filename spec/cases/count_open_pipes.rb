require './spec/cases/helper'
count = ->(*) { `lsof | grep pipe | wc -l`.to_i }
start = count.()
results = Parallel.map(Array.new(20), :in_processes => 20, &count)
puts results.max - start
