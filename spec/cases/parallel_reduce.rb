require './spec/cases/helper'
type = case ARGV[0]
when "processes" then :in_processes
when "threads" then :in_threads
else
  raise "Use PROCESSES or THREADS"
end

s = [Parallel::Stop,'a','b','c','d','a','b','c','d']
result = Parallel.reduce(-> {s.pop}) do |y,x|
  y||=Set.new
  y << "-#{x}-"
  y
end
print result.compact.reduce(&:+).sort * ' '
