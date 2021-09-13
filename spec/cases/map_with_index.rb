# frozen_string_literal: true
require './spec/cases/helper'

result = Parallel.map_with_index(['a', 'b']) do |x, i|
  "#{x}#{i}"
end
print result * ''
