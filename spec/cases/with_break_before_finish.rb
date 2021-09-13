# frozen_string_literal: true
require './spec/cases/helper'

method = ENV.fetch('METHOD')
in_worker_type = "in_#{ENV.fetch('WORKER_TYPE')}".to_sym

finish = lambda do |_item, _index, _result|
  sleep 0.1
  print "finish hook called"
end

Parallel.public_send(method, 1..100, in_worker_type => 4, finish: finish) do |x|
  sleep 0.1 # let workers start
  raise Parallel::Break if x == 1
  sleep 0.2
  print x
  x
end

print " Parallel::Break raised"
