# frozen_string_literal: true
require './spec/cases/helper'

$stdout.sync = true
method = ENV.fetch('METHOD')
in_worker_type = :"in_#{ENV.fetch('WORKER_TYPE')}"

class ParallelTestError < StandardError
end

class Callback
  def self.call(x)
    $stdout.sync = true
    print x
    sleep 0.2 # let everyone start and print
    sleep 0.2 unless x == 1 # prevent other work from start/finish before exception
    x
  end
end

begin
  finish = lambda do |x, _index, _result|
    raise ParallelTestError, 'foo' if x == 1
  end
  options = { in_worker_type => 4, finish: finish }
  if in_worker_type == :in_ractors
    Parallel.public_send(method, 1..10, options.merge(ractor: [Callback, :call]))
  else
    Parallel.public_send(method, 1..10, options) { |x| Callback.call x }
  end
rescue ParallelTestError
  print ' raised'
end
