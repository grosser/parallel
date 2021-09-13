# frozen_string_literal: true
require './spec/cases/helper'

process_diff do
  Parallel.each((0..10).to_a, in_processes: 5) { |a| raise unless a * 2 }
end
