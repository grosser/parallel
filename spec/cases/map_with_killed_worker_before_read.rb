# frozen_string_literal: true
require './spec/cases/helper'

begin
  Parallel.map([1, 2, 3]) do |_x, _i|
    Process.kill("SIGKILL", Process.pid)
  end
rescue Parallel::DeadWorker
  puts "DEAD"
end
