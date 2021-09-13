# frozen_string_literal: true
require './spec/cases/helper'

begin
  Parallel.map([1]) { exit } # rubocop:disable Lint/UnreachableLoop
rescue Parallel::DeadWorker
  puts "Yep, DEAD"
else
  puts "WHOOOPS"
end
