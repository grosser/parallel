# frozen_string_literal: true
require './spec/cases/helper'

start = lambda { |item, _index|
  print item * 5
  sleep rand * 0.2
  puts item * 5
}
finish = lambda { |_item, _index, result|
  print result * 5
  sleep rand * 0.2
  puts result * 5
}
Parallel.map(['a', 'b', 'c'], start: start, finish: finish) do |i|
  sleep rand * 0.2
  i.upcase
end
