# frozen_string_literal: true
require './spec/cases/helper'

queue = Queue.new
queue.push 1
queue.push 2
queue.push 3
Parallel.map(queue, in_threads: 2) { |(i, _id)| "ITEM-#{i}" }
