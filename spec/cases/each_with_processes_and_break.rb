require './spec/cases/helper'

result = Parallel.each(1..100, :in_processes => 4) do |x|
  sleep 0.1 # so all processes get started
  print x
  raise Parallel::Break if x == 1
  sleep 0.1 # so now no work gets queued before Parallel::Break is raised
  x
end
print " Parallel::Break raised - result #{result.inspect}"
