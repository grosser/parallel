require './spec/cases/helper'
STDOUT.sync = true # otherwise results can go weird...

result = "i should be nil"
[{in_processes: 2}, {in_threads: 2}].each do |options|
  x = ["bob", "alice", "ellcs", "grosser"]
  result = Parallel.first_result(x, options) do |o|
    # nothing matches
    false
  end
end

print result.inspect
