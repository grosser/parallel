require './spec/cases/helper'

method = ENV.fetch('METHOD')
in_worker_type = "in_#{ENV.fetch('WORKER_TYPE')}".to_sym

begin
  start = lambda do |_item, _index|
    if _item != 3
      sleep 0.2
      raise 'foo'
    end
  end

  finish = lambda do |_item, _index, _result|
    print " called"
  end

  Parallel.public_send(method, 1..10, in_worker_type => 4, start: start, finish: finish) do |x|
    print x
    x
  end
rescue
end
