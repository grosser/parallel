require './spec/cases/helper'

begin
  Parallel.map([1]){ raise EOFError }
rescue EOFError
  puts 'Yep, EOF'
else
  puts 'WHOOOPS'
end
