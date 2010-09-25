require File.expand_path('spec/spec_helper')

result = Parallel.map([1,2,[3]]) do |x|
  [x, x] if x != 1
end

print result.inspect