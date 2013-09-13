require File.expand_path('spec/spec_helper')

Parallel.each(1..1000, :in_threads => 2) do |i|
  "xxxx" * 1_000_000
end
