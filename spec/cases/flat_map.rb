# frozen_string_literal: true
require './spec/cases/helper'

result = Parallel.flat_map(['a', 'b']) do |x|
  [x, [x]]
end
print result.inspect
