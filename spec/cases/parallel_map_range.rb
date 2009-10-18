require 'spec/spec_helper.rb'

result = Parallel.map(1..5) do |x|
  x
end
print result