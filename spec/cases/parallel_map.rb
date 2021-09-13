# frozen_string_literal: true
require './spec/cases/helper'

result = Parallel.map(['a', 'b', 'c', 'd']) do |x|
  "-#{x}-"
end
print result * ' '
