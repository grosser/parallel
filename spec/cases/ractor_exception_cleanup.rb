# frozen_string_literal: true
require './spec/cases/helper'

class RaisingCallback
  def self.call(_item)
    raise "boom"
  end
end

before = ObjectSpace.each_object(Ractor).to_a
begin
  Parallel.map([1], in_ractors: 1, ractor: [RaisingCallback, :call])
rescue RuntimeError => error
  raise unless error.message == "boom"
end

deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2
loop do
  workers = ObjectSpace.each_object(Ractor).to_a - before
  break if workers.empty? || workers.all? { |worker| worker.inspect.include?("terminated") }
  raise "ractor worker did not terminate" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
  Thread.pass
end

print "OK"
