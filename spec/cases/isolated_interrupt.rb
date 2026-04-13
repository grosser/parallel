# frozen_string_literal: true
require './spec/cases/helper'

# Queue two items to be processed in a single worker with isolation enabled.
# Shortly after work begins on the second item, send the process the interrupt signal.
# The process should terminate nearly immediately, indicating the replacement process
# was killed rather than completing work on the second item.

parent_pid = Process.pid
killer_pid = fork do
  sleep 1
  Process.kill(:INT, parent_pid)
end
Process.detach(killer_pid)

Parallel.each([0.1, 5], in_processes: 1, isolation: true) do |sec|
  sleep sec
end
