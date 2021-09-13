# frozen_string_literal: true
require './spec/cases/helper'
$stdout.sync = true # otherwise results can go weird...

results = []

[{ in_processes: 2 }, { in_threads: 2 }, { in_threads: 0 }].each do |options|
  x = [nil, nil, nil, nil, nil, nil, nil, nil]
  results << Parallel.any?(x, options) do |y|
    y
  end

  x = 10.times
  results << Parallel.any?(x, options) do |_y|
    false
  end

  # Empty array should return false
  x = []
  results << Parallel.any?(x, options) do |y|
    y == 42
  end
end

print results.join(',')
