require './spec/cases/helper'
STDOUT.sync = true # otherwise results can go weird...

result = ""
[{in_processes: 2}, {in_threads: 2}].each do |options|
  x = ["bob", "alice", "ellcs", "grosser"]
  result = Parallel.first_result(x, options) do |s|
    s.include?("ll") && s
  end
end

print result
