require File.expand_path('spec/spec_helper')

begin
  Parallel.map([1]){ exit }
rescue Parallel::DeadWorker
  puts "Yep, DEAD"
else
  puts "WHOOOPS"
end
