# frozen_string_literal: true
require './spec/cases/helper'

parent_pid = Process.pid
killer_pid = fork do
  sleep 1
  Process.kill(:INT, parent_pid)
end
Process.detach(killer_pid)

Parallel.each([0.1, 5], in_processes: 1, isolation: true) do |sec|
  sleep sec
end
