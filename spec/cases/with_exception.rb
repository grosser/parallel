require './spec/cases/helper'

method = ENV.fetch('METHOD')
in_worker_type = "in_#{ENV.fetch('WORKER_TYPE')}".to_sym

begin
  Parallel.public_send(method, 1..100, in_worker_type => 4) do |x|
    sleep 0.1 # so all workers get started
    print x
    raise 'foo' if x == 1
    sleep 1 # so now no work gets queued before exception is raised
    x
  end
rescue
  print ' raised'
end
