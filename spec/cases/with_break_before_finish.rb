# frozen_string_literal: true
require './spec/cases/helper'

method = ENV.fetch('METHOD')
in_worker_type = :"in_#{ENV.fetch('WORKER_TYPE')}"
$stdout.sync = true

class Callback
  def self.call(x)
    $stdout.sync = true
    sleep 0.1 # let workers start
    raise Parallel::Break if x == 1
    sleep 0.2
    print x
    x
  end
end

finish = lambda do |_item, _index, _result|
  sleep 0.1
  print "finish hook called"
end

options = { in_worker_type => 4, finish: finish }
if in_worker_type == :in_ractors
  Parallel.public_send(method, 1..10, options.merge(ractor: [Callback, :call]))
else
  Parallel.public_send(method, 1..10, options) { |x| Callback.call x }
end
print " Parallel::Break raised"
