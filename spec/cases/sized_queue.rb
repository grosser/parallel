require File.expand_path('spec/spec_helper')

queue = SizedQueue.new 10

Thread.new do
  begin
    (1..40).each do |very_large_object|
      queue << very_large_object # quickly generates large objects
      print "produced"
    end
    queue << Parallel::EndOfIteration
  rescue Exception => e
    STDERR.print e.inspect
  end
end

finish = lambda {|item,index,result|
  print "consumed"
}

Parallel.each(queue, :finish => finish, :in_threads => 20) do |item|
  sleep 0.1
  - item
end
