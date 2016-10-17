require './spec/cases/helper'

begin
  Parallel.reduce([1,2]) do
    raise "TEST"
  end
  puts "FAIL"
rescue RuntimeError
  puts $!.message
end
