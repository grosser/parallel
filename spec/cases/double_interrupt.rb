# frozen_string_literal: true
require './spec/cases/helper'

Signal.trap :SIGINT do
  sleep 0.5
  puts "YES"
  exit 0
end

Parallel.map(Array.new(20), in_processes: 2) do
  sleep 10
  puts "I should be killed earlier"
end
