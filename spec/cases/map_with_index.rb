require 'spec/spec_helper.rb'

result = Parallel.map_with_index(['a','b']) do |x, i|
  "#{x}#{i}"
end
print result * ''