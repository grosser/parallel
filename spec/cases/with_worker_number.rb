# frozen_string_literal: true
require './spec/cases/helper'

method = ENV.fetch('METHOD')
in_worker_type = "in_#{ENV.fetch('WORKER_TYPE')}".to_sym

Parallel.public_send(method, 1..100, in_worker_type => 4) do
  sleep 0.1 # so all workers get started
  print Parallel.worker_number
end
