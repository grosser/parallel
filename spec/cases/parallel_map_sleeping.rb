require './spec/cases/helper'

Parallel.map(['a','b','c','d']) do |x|
  sleep 1
end
