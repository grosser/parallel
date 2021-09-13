# frozen_string_literal: true
require './spec/cases/helper'

begin
  Parallel.in_processes(2) do
    raise "TEST"
  end
  puts "FAIL"
rescue RuntimeError
  puts $!.message
end
