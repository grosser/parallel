# frozen_string_literal: true
require './spec/cases/helper'

Parallel.map([1, 2, 1, 2]) do |x|
  sleep 2 if x == 1
end
