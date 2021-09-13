# frozen_string_literal: true
require './spec/cases/helper'

results = Parallel.map([1, 2, 3]) do |x|
  case x
  when 1 # -> stop all sub-processes, killing them instantly
    sleep 0.1
    puts "DEAD"
    raise Parallel::Kill
  when 3
    sleep 10
  else
    x
  end
end

puts "Works #{results.inspect}"
