# frozen_string_literal: true
require './spec/cases/helper'

class SlowCallback
  def self.call(item)
    sleep 0.1
    item
  end
end

items = [1, 2, 3]
producer = lambda do
  item = items.shift
  raise "boom" if item == 3
  item || Parallel::Stop
end

before = ObjectSpace.each_object(Ractor).to_a
begin
  Parallel.map(producer, in_ractors: 2, ractor: [SlowCallback, :call])
rescue RuntimeError => e
  raise unless e.message == "boom"
end

assert_ractors_stopped(before)
print "OK"
