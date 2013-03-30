require File.expand_path('spec/spec_helper')

result = Parallel.map(1..100, :in_threads => 4) do |x|
  sleep 0.1 # so all threads get started
  print x
  raise Parallel::Break if x == 1
  sleep 0.1 # so no now work gets queued before Parallel::Break is raised
end
print " Parallel::Break raised - result #{result.inspect}"
