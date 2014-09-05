require './spec/cases/helper'

Parallel.map(1..50, :progress => "Doing stuff") do
  sleep 1 if $stdout.tty? # for debugging
end
