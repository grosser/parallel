# frozen_string_literal: true
require './spec/cases/helper'
$stdout.sync = true # otherwise results can go weird...

method = ENV.fetch('METHOD')
in_worker_type = "in_#{ENV.fetch('WORKER_TYPE')}".to_sym
worker_size = (ENV['WORKER_SIZE'] || 4).to_i

ARGV.freeze # make ractor happy

class Callback
  def self.call(x)
    $stdout.sync = true
    sleep 0.1 # so all workers get started
    print x
    raise Parallel::Break, *ARGV if x == 1
    sleep 0.2 # so now no work gets queued before Parallel::Break is raised
    x
  end
end

options = { in_worker_type => worker_size }
result =
  if in_worker_type == :in_ractors
    Parallel.public_send(method, 1..10, options.merge(ractor: [Callback, :call]))
  else
    Parallel.public_send(method, 1..10, options) { |x| Callback.call x }
  end
print " Parallel::Break raised - result #{result.inspect}"
