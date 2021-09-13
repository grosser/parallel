# frozen_string_literal: true
require './spec/cases/helper'

Parallel.map([1, 2, 3], in_processes: 2) do
  puts "I finished..."
end

sleep 10
