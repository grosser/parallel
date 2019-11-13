require './spec/cases/helper'

begin
  Parallel.each([1]){ raise Exception }
rescue Parallel::DeadWorker
  puts "No, DEAD worker found"
rescue Exception
  puts "Yep, rescued the exception"
else
  puts "WHOOOPS"
end
