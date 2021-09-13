# frozen_string_literal: true
require './spec/cases/helper'

method = ENV.fetch('METHOD')
in_worker_type = "in_#{ENV.fetch('WORKER_TYPE')}".to_sym

begin
  finish = lambda do |x, _index, _result|
    raise 'foo' if x == 1
  end

  Parallel.public_send(method, 1..100, in_worker_type => 4, finish: finish) do |x|
    sleep 0.1 # so all workers get started
    print x
    sleep 0.2 unless x == 1 # so now no work gets queued before exception is raised
    x
  end
rescue StandardError
  print ' raised'
end
