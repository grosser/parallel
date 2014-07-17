require File.expand_path('spec/spec_helper')

results = Parallel.map([1,2,3]) do |x|
  if x == 1 # -> stop all sub-processes, killing them instantly
    sleep 0.1
    raise Parallel::Kill
  elsif x == 3
    sleep 100
  else
    x
  end
end

puts "Works #{results.inspect}"
