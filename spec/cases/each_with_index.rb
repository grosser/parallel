require 'spec/spec_helper.rb'

Parallel.each_with_index(['a','b'], :in_threads => 2) do |x, i|
  print "#{x}#{i}"
end