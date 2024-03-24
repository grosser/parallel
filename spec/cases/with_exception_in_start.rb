# frozen_string_literal: true
require './spec/cases/helper'

method = ENV.fetch('METHOD')
in_worker_type = :"in_#{ENV.fetch('WORKER_TYPE')}"

class ParallelTestError < StandardError
end

class Callback
  def self.call(x)
    $stdout.sync = true
    print x
    sleep 0.2 # so now no work gets queued before exception is raised
    x
  end
end

begin
  start = lambda do |_item, _index|
    @started = (@started ? @started + 1 : 1)
    sleep 0.01 # a bit of time for ractors to work
    raise ParallelTestError, 'foo' if @started == 4
  end

  options = { in_worker_type => 4, start: start }
  if in_worker_type == :in_ractors
    Parallel.public_send(method, 1..10, options.merge(ractor: [Callback, :call]))
  else
    Parallel.public_send(method, 1..10, options) { |x| Callback.call x }
  end
rescue ParallelTestError
  print ' raised'
end
