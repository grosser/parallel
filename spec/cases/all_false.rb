# frozen_string_literal: true
require './spec/cases/helper'
$stdout.sync = true # otherwise results can go weird...

results = []

[{ in_processes: 2 }, { in_threads: 2 }, { in_threads: 0 }].each do |options|
  x = [nil, nil, nil, nil, nil, nil, nil, nil]
  results << Parallel.all?(x, options) do |y|
    y
  end

  x = [42, 42, 42, 42, 42, 42, 42, 5, 42, 42, 42]
  results << Parallel.all?(x, options) do |y|
    y == 42
  end
end

print results.join(',')
