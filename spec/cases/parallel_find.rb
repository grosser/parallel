require './spec/cases/helper'
STDOUT.sync = true # otherwise results can go weird...

result = ""
[{in_processes: 2}, {in_threads: 2}].each do |options|
  x = ["bob", "alice", "ellcs", "grosser"]
  result = Parallel.find(x, options) do |s|
    s.include?("ll")
  end
end

print result
