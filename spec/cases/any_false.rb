require './spec/cases/helper'
STDOUT.sync = true # otherwise results can go weird...

results = []

[{in_processes: 2}, {in_threads: 2}, {in_threads: 0}].each do |options|
  x = [nil,nil,nil,nil,nil,nil,nil,nil]
  results << Parallel.any?(x, options) do |x|
    x
  end

  x = 10.times
  results << Parallel.any?(x, options) do |x|
    false
  end

  # Empty array should return false
  x = []
  results << Parallel.any?(x, options) do |x|
    x == 42
  end
end

print results.join(',')
