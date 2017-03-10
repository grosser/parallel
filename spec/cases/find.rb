require './spec/cases/helper'
STDOUT.sync = true # otherwise results can go weird...

results = []
[{in_processes: 2}, {in_threads: 2}, {in_threads: 0}].each do |options|
  x = ['red','blue','green','yellow','purple']
  results << Parallel.find(x, options) do |s|
    s.include?('ee')
  end
end
print results.join(',')
