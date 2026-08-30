# frozen_string_literal: true
require './spec/cases/helper'

class FinishCallback
  def self.call(item)
    raise "boom" if item == 2
    sleep 0.2
    item
  end
end

before = ObjectSpace.each_object(Ractor).to_a
begin
  Parallel.map([1, 2], in_ractors: 2, ractor: [FinishCallback, :call])
rescue RuntimeError => e
  raise unless e.message == "boom"
end

assert_ractors_stopped(before)
print "OK"
