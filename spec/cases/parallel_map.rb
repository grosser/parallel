require './spec/cases/helper'

result = Parallel.map(['a','b','c','d']) do |x|
  "-#{x}-"
end
print result * ' '
