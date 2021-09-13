# frozen_string_literal: true
require './spec/cases/helper'

result = Parallel.map(1..5) do |x|
  x
end
print result.inspect
