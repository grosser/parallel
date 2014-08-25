require File.expand_path('spec/spec_helper')

type = case ARGV[0]
when "PROCESSES" then :in_processes
when "THREADS" then :in_threads
else
  raise "Use PROCESSES or THREADS"
end
options = {type => 2, :mutex => Mutex.new}

all = ['too soon']
produce = lambda { all.shift || Parallel::Stop }
Thread.new do
  options[:mutex].synchronize do
    all.replace(['locked'])
    sleep 1
    all.replace([1,2,3])
  end
end

sleep 0.1

puts Parallel.map(produce, options) { |(i, id)| "ITEM-#{i}" }
