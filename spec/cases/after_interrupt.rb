require File.expand_path('spec/spec_helper')

Parallel.map([1, 2], :in_processes => 2) { }

puts Signal.trap(:SIGINT, "IGNORE")


