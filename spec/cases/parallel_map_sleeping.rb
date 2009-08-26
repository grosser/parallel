require 'spec/spec_helper.rb'

Parallel.map(['a','b','c','d']) do |x|
  sleep 1
end