require File.expand_path('spec/spec_helper')
queue = Queue.new()
Thread.new do
  [1,2].each {|i|
    queue.push(i)
  }
  queue.close
end

result = Parallel.map(queue, :in_threads => 4) do |x|
  x
end
print result.sort.inspect
