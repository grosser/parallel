# frozen_string_literal: true
require './spec/cases/helper'

type = case ARGV[0]
       when "PROCESSES" then :in_processes
       when "THREADS" then :in_threads
       else
         raise "Use PROCESSES or THREADS"
end

queue = Queue.new
Thread.new do
  sleep 0.2
  queue.push 1
  queue.push 2
  queue.push 3
  queue.push Parallel::Stop
end
puts Parallel.map(queue, type => 2) { |(i, _id)| "ITEM-#{i}" }
