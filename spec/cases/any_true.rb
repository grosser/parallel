require './spec/cases/helper'
STDOUT.sync = true # otherwise results can go weird...

results = []

[{in_processes: 2}, {in_threads: 2}, {in_threads: 0}].each do |options|
  x = [nil,nil,nil,nil,42,nil,nil,nil]
  results << Parallel.any?(x, options) do |x|
    x
  end

  x = [true,true,true,false,true,true,true]
  results << Parallel.any?(x, options) do |x|
    x
  end
end

print results.join(',')
