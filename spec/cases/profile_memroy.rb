def count_objects
  old = Hash.new(0)
  cur = Hash.new(0)
  GC.start
  ObjectSpace.each_object { |o| old[o.class] += 1 }
  yield
  GC.start
  GC.start
  ObjectSpace.each_object { |o| cur[o.class] += 1 }
  Hash[cur.map{|k,v| [k, v - old[k]] }].reject{|k,v|v==0}
end

require File.expand_path('spec/spec_helper')

items = Array.new(1000)
options = {"in_#{ARGV[0]}".to_sym => 2}

puts(count_objects { Parallel.map(items, options) {} })

puts(count_objects { Parallel.map(items, options) {} })

