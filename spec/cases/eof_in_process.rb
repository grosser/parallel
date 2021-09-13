# frozen_string_literal: true
require './spec/cases/helper'

begin
  Parallel.map([1]) { raise EOFError } # rubocop:disable Lint/UnreachableLoop
rescue EOFError
  puts 'Yep, EOF'
else
  puts 'WHOOOPS'
end
