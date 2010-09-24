require File.expand_path('spec/spec_helper')

result = Parallel.map_with_index([]) do |x, i|
  "#{x}#{i}"
end
print result * ''