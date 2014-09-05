require './spec/cases/helper'
STDOUT.sync = true # otherwise results can go weird...

x = ['a','b','c','d']
result = Parallel.each(x) do |x|
  sleep 0.1 if x == 'a'
end
print result * ' '
