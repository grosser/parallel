require './spec/cases/helper'

begin
  finish = lambda do |x, _index, _result|
    raise 'foo' if x == 1
  end

  Parallel.map(1..100, :in_processes => 4, finish: finish) do |x|
    sleep 0.1 # so all processes get started
    print x
    sleep 0.1 unless x == 1 # so now no work gets queued before exception is raised
    x
  end
rescue
  print ' raised'
end
