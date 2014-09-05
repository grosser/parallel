require './spec/cases/helper'

begin
  Parallel.map(1..100, :in_threads => 4) do |x|
    sleep 0.1 # so all processes get started
    print x
    raise 'foo' if x == 1
    sleep 0.1 # so no now work gets queued before exception is raised
  end
rescue
  print ' raised'
end
