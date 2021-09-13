# frozen_string_literal: true
require './spec/cases/helper'

method = ENV.fetch('METHOD')
in_worker_type = "in_#{ENV.fetch('WORKER_TYPE')}".to_sym

class ParallelTestError < StandardError
end

begin
  finish = lambda do |_item, _index, _result|
    print " called"
  end

  Parallel.public_send(method, 1..10, in_worker_type => 4, finish: finish) do |x|
    if x != 3
      sleep 0.2
      raise ParallelTestError
    end
    print x
    x
  end
rescue ParallelTestError
  nil
end
