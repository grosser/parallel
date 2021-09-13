# frozen_string_literal: true
require './spec/cases/helper'

result = Parallel.map([1, 2, [3]]) do |x|
  [x, x] if x != 1
end

print result.inspect
