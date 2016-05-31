require './spec/cases/helper'

method = ENV.fetch('METHOD')
in_worker_type = "in_#{ENV.fetch('WORKER_TYPE')}".to_sym

result = Parallel.public_send(method, 1..100, in_worker_type => 4) do
  sleep 0.1 # so all workers get started
  print Thread.current[:parallel_worker_number]
  nil
end

