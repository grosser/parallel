require './spec/cases/helper'
type = case ARGV[0]
when "processes" then :in_processes
when "threads" then :in_threads
else
  raise "Use PROCESSES or THREADS"
end

result = Parallel.reduce(['a','b','c','d','a','b','c','d'], start_with: Set.new) do |y,x|
  y << "-#{x}-"
  y
end
print result.compact.reduce(&:+).sort * ' '
