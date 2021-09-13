# frozen_string_literal: true
require './spec/cases/helper'

x = 'yes'

Parallel.in_processes(2) do
  x = 'no'
end
print x
