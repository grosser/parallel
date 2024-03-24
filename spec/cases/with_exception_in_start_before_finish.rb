# frozen_string_literal: true
require './spec/cases/helper'

method = ENV.fetch('METHOD')
in_worker_type = :"in_#{ENV.fetch('WORKER_TYPE')}"
$stdout.sync = true

class ParallelTestError < StandardError
end

class Callback
  def self.call(x)
    $stdout.sync = true
    puts "call #{x}"
    x
  end
end

begin
  start = lambda do |item, index|
    puts "start #{index}"
    if item != 3
      sleep 0.2
      raise ParallelTestError
    end
  end

  finish = lambda do |_item, index, _result|
    puts "finish #{index}"
  end

  options = { in_worker_type => 4, start: start, finish: finish }

  if in_worker_type == :in_ractors
    Parallel.public_send(method, 1..10, options.merge(ractor: [Callback, :call]))
  else
    Parallel.public_send(method, 1..10, options) { |x| Callback.call x }
  end
rescue ParallelTestError
  nil
end
