require File.expand_path('spec/spec_helper')

result = Parallel.map(['a','b','c','d']) do |x|
  "-#{x}-"
end
print result * ' '