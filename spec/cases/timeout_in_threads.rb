# frozen_string_literal: true
require './spec/cases/helper'
require 'timeout'

Parallel.each([1], in_threads: 1) do |_i|
  Timeout.timeout(0.1) { sleep 0.2 }
rescue Timeout::Error
  puts "OK"
else
  puts "BROKEN"
end
