# frozen_string_literal: true
require './spec/cases/helper'

class UndumpableCauseError < StandardError
  def initialize
    super("bad")
    @binding = binding # can't be dumped when it is the cause
  end
end

begin
  x = Parallel.in_processes(2) do
    raise UndumpableCauseError
  rescue StandardError
    raise Parallel::Break, "hello"
  end
  puts "Result: #{x}"
rescue StandardError => e
  puts "Error: #{e.class}: #{e.message}"
end
