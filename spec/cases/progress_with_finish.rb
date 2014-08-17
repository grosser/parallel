require File.expand_path('spec/spec_helper')

sum = 0
finish = lambda { |item, index, result| sum += result }

Parallel.map(1..50, :progress => "Doing stuff", :finish => finish) do
  sleep 1 if $stdout.tty? # for debugging
  2
end

puts sum
