# frozen_string_literal: true
require './spec/cases/helper'

sum = 0
finish = ->(_item, _index, result) { sum += result }

Parallel.map(1..50, progress: "Doing stuff", finish: finish) do
  sleep 1 if $stdout.tty? # for debugging
  2
end

puts sum
