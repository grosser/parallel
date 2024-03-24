# frozen_string_literal: true
def count_objects
  old = Hash.new(0)
  cur = Hash.new(0)
  GC.start
  ObjectSpace.each_object { |o| old[o.class] += 1 }
  yield
  GC.start
  GC.start
  ObjectSpace.each_object { |o| cur[o.class] += 1 }
  cur.to_h { |k, v| [k, v - old[k]] }.reject { |_k, v| v == 0 }
end

class Callback
  def self.call(x); end
end

require './spec/cases/helper'

items = Array.new(1000)
options = { "in_#{ARGV[0]}".to_sym => 2 }

# TODO: not sure why this fails without 2.times in threading mode :(

call = lambda do
  if ARGV[0] == "ractors"
    Parallel.map(items, options.merge(ractor: [Callback, :call]))
    sleep 0.1 # ractors need a bit to shut down
  else
    Parallel.map(items, options) {}
  end
end

puts(count_objects { 2.times { call.call } }.inspect)

puts(count_objects { 2.times { call.call } }.inspect)
