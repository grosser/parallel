require './spec/cases/helper'

begin
  start = lambda do |_item, _index|
    @started = @started ? @started + 1 : 1
    raise 'foo' if @started == 4
  end

  Parallel.map(1..100, :in_processes => 4, start: start) do |x|
    print x
    sleep 0.1 # so now no work gets queued before exception is raised
    x
  end
rescue
  print ' raised'
end
