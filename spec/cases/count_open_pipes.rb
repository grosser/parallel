# frozen_string_literal: true
require './spec/cases/helper'
count = ->(*) { `lsof -l | grep pipe | wc -l`.to_i }
start = count.call
results = Parallel.map(Array.new(20), in_processes: 20, &count)
puts results.max - start
