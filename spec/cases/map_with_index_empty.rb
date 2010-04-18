require 'spec/spec_helper.rb'

result = Parallel.map_with_index([]) do |x, i|
  "#{x}#{i}"
end
print result * ''