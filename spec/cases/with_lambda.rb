require File.expand_path('spec/spec_helper')

options = (ARGV[0] == "PROCESSES" ? {:in_processes => 2} : {:in_threads => 2})
options[:mutex] = Mutex.new
all = ['too soon']
produce = lambda { all.shift || Parallel::StopIteration }
Thread.new do
  options[:mutex].synchronize do
    all.replace(['locked'])
    sleep 1
    all.replace([1,2,3])
  end
end

sleep 0.1

puts Parallel.map(produce, options) { |(i, id)| "ITEM-#{i}" }
