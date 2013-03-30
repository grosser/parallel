require File.expand_path('spec/spec_helper')

Parallel.map(1..100, :in_processes => 4) do |x|
  sleep 0.1 # so all processes get started
  print x
  break if x == 1
  sleep 0.1 # so no now work gets queued before break is executed
  x
end
print ' broke'
