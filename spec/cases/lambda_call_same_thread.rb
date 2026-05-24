# frozen_string_literal: true
require './spec/cases/helper'

runner_thread = nil
all = [3, 2, 1]
my_proc = proc {
  runner_thread ||= Thread.current
  if Thread.current != runner_thread
    raise "proc is called in different thread!"
  end

  all.pop || Parallel::Stop
}

class Callback
  def self.call(x)
    $stdout.sync = true
    "ITEM-#{x}"
  end
end
puts(Parallel.map(my_proc, in_threads: 2) { |(i, _id)| Callback.call i })
