# frozen_string_literal: true
require './spec/cases/helper'
$stdout.sync = true # otherwise results can go weird...

x = ['a', 'b', 'c', 'd']
result = Parallel.each(x) do |y|
  sleep 0.1 if y == 'a'
end
print result * ' '
