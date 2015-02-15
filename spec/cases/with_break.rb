require './spec/cases/helper'

method = ENV['METHOD']
in_worker_type = "in_#{ENV['WORKER_TYPE']}".to_sym

result = Parallel.public_send(method, 1..100, in_worker_type => 4) do |x|
  sleep 0.1 # so all workers get started
  print x
  raise Parallel::Break if x == 1
  sleep 0.1 # so now no work gets queued before Parallel::Break is raised
  x
end
print " Parallel::Break raised - result #{result.inspect}"
