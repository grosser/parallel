# frozen_string_literal: true
require './spec/cases/helper'

Parallel.map(['a', 'b', 'c', 'd']) do |_x|
  sleep 1
end
