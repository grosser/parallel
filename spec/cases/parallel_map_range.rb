require File.expand_path('spec/spec_helper')

result = Parallel.map(1..5) do |x|
  x
end
print result.inspect