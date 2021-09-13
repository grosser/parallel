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
  cur.map { |k, v| [k, v - old[k]] }.to_h.reject { |_k, v| v == 0 }
end

require './spec/cases/helper'

items = Array.new(1000)
options = { "in_#{ARGV[0]}".to_sym => 2 }

# TODO: not sure why this fails without 2.times in threading mode :(

puts(count_objects { 2.times { Parallel.map(items, options) {} } }.inspect)

puts(count_objects { 2.times { Parallel.map(items, options) {} } }.inspect)
