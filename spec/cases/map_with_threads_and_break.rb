require File.expand_path('spec/spec_helper')

Parallel.map(1..100, :in_threads => 4) do |x|
  sleep 0.1 # so all threads get started
  print x
  break if x == 1
  sleep 0.1 # so no now work gets queued before break is executed
end
print ' broke'
