require 'spec/spec_helper.rb'

result = Parallel.map(['a','b','c','d']) do |x|
  "-#{x}-"
end
print result * ' '