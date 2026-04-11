# frozen_string_literal: true
require './spec/cases/helper'

method = ENV.fetch('METHOD')
in_worker_type = :"in_#{ENV.fetch('WORKER_TYPE')}"

Parallel.public_send(method, 1..20, in_worker_type => 4) do
  sleep 0.02 # so all workers get started
  print Parallel.worker_number
end
