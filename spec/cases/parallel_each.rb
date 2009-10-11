require 'spec/spec_helper.rb'
STDOUT.sync = true # otherwise results can go weird...

x = ['a','b','c','d']
result = Parallel.each(x) do |x|
  sleep 0.1 if x == 'a'
  print "-#{x}-"
end
print result * ' '