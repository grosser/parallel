require './spec/cases/helper'
STDOUT.sync = true # otherwise results can go weird...

x = ['a']
Parallel.each(x, :in_threads => 1) { |x| x << 'b' }
print x.first
