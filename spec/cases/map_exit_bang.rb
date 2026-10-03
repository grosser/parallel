# frozen_string_literal: true
require './spec/cases/helper'

at_exit { puts "AT_EXIT #{Process.pid}" }

result = Parallel.map([1, 2, 3, 4], in_processes: 2, exit!: true) { |i| i * 2 }
puts(result == [2, 4, 6, 8] ? "OK" : "FAIL: #{result.inspect}")
