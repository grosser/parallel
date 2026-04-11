# frozen_string_literal: true
require './spec/cases/helper'
count = ->(*) { Dir.children("/dev/fd").size }

if ENV["SELF_TEST"]
  # verify that count detects newly opened pipes
  create = 5
  before = count.call
  pipes = create.times.map { IO.pipe }
  after = count.call
  expected = before + (create * 2)
  raise "expected #{expected} fds but got #{after}" unless after == expected
  pipes.each do |r, w|
    r.close
    w.close
  end
end

start = count.call
results = Parallel.map(Array.new(20), in_processes: 20, &count)
puts results.max - start
