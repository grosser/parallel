require File.expand_path('spec/spec_helper')

Parallel.map(['a','b','c','d']) do |x|
  sleep 1
end