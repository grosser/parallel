require './spec/cases/helper'

Parallel.each_with_index(['a','b'], :in_threads => 2) do |x, i|
  print "#{x}#{i}"
end
