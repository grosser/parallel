# frozen_string_literal: true
require './spec/cases/helper'

result = Parallel.filter_map(['a', 'b', 'c']) do |x|
  x if x != 'b'
end
print result.inspect
