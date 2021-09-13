# frozen_string_literal: true
require './spec/cases/helper'

x = Parallel.in_processes do
  "HELLO"
end
puts x
