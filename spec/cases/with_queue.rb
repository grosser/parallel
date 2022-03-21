# frozen_string_literal: true
require './spec/cases/helper'

type = :"in_#{ARGV.fetch(0)}"

class Callback
  def self.call(x)
    "ITEM-#{x}"
  end
end

queue = Queue.new
Thread.new do
  sleep 0.2
  queue.push 1
  queue.push 2
  queue.push 3
  queue.push Parallel::Stop
end

if type == :in_ractors
  puts(Parallel.map(queue, type => 2, ractor: [Callback, :call]))
else
  puts(Parallel.map(queue, type => 2) { |(i, _id)| Callback.call i })
end
