# frozen_string_literal: true
require './spec/cases/helper'

method = ENV.fetch('METHOD')
in_worker_type = :"in_#{ENV.fetch('WORKER_TYPE')}"

class ParallelTestError < StandardError
end

class Callback
  def self.call(x)
    $stdout.sync = true
    if x != 3
      sleep 0.2
      raise ParallelTestError
    end
    print x
    x
  end
end

begin
  finish = lambda do |_item, _index, _result|
    print " called"
  end

  options = { in_worker_type => 4, finish: finish }
  if in_worker_type == :in_ractors
    Parallel.public_send(method, 1..10, options.merge(ractor: [Callback, :call]))
  else
    Parallel.public_send(method, 1..10, options) { |x| Callback.call x }
  end
rescue ParallelTestError
  nil
end
