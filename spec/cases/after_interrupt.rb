# frozen_string_literal: true
require './spec/cases/helper'

Parallel.map([1, 2], in_processes: 2) {}

puts Signal.trap(:SIGINT, "IGNORE")
