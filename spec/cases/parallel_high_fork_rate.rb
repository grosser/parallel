# frozen_string_literal: true
require './spec/cases/helper'

Parallel.each((0..200).to_a, in_processes: 200) do |_x|
  sleep 1
end
print 'OK'
