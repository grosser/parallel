# frozen_string_literal: true
require './spec/cases/helper'
$stdout.sync = true # otherwise results can go weird...

method = ENV.fetch('METHOD')
in_worker_type = "in_#{ENV.fetch('WORKER_TYPE')}".to_sym
worker_size = (ENV['WORKER_SIZE'] || 4).to_i

begin
  Parallel.public_send(method, 1..100, in_worker_type => worker_size) do |x|
    sleep 0.1 # so all workers get started
    print x
    raise 'foo' if x == 1
    sleep 0.2 # so now no work gets queued before exception is raised
    x
  end
rescue StandardError
  print ' raised'
end
