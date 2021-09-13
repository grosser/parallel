# frozen_string_literal: true
require './spec/cases/helper'

begin
  Parallel.each([1]) { raise StandardError } # rubocop:disable Lint/UnreachableLoop
rescue Parallel::DeadWorker
  puts "No, DEAD worker found"
rescue Exception # rubocop:disable Lint/RescueException
  puts "Yep, rescued the exception"
else
  puts "WHOOOPS"
end
