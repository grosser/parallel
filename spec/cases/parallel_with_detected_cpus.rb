require './spec/cases/helper'

x = Parallel.in_processes do
  "HELLO"
end
puts x
