# frozen_string_literal: true
require './spec/cases/helper'
$stdout.sync = true # otherwise results can go weird...

method = ENV.fetch('METHOD')
in_worker_type = "in_#{ENV.fetch('WORKER_TYPE')}".to_sym
worker_size = (ENV['WORKER_SIZE'] || 4).to_i

result = Parallel.public_send(method, 1..100, in_worker_type => worker_size) do |x|
  sleep 0.1 # so all workers get started
  print x
  raise Parallel::Break, *ARGV if x == 1
  sleep 0.2 # so now no work gets queued before Parallel::Break is raised
  x
end
print " Parallel::Break raised - result #{result.inspect}"
