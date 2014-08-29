require File.expand_path('spec/spec_helper')

type = case ARGV[0]
when "PROCESSES" then :in_processes
when "THREADS" then :in_threads
else
  raise "Use PROCESSES or THREADS"
end

all = [3,2,1]
produce = lambda { all.pop || Parallel::Stop }
puts Parallel.map(produce, type => 2) { |(i, id)| "ITEM-#{i}" }
