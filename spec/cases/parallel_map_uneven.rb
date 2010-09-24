require File.expand_path('spec/spec_helper')

Parallel.map([1,2,1,2]) do |x|
  sleep 2 if x == 1
end