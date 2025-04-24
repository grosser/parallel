# frozen_string_literal: true
require './spec/cases/helper'

def generate_proc
  count = 0
  proc {
    raise StopIteration if 3 <= count
    count += 1
  }
end

class Callback
  def self.call(x)
    $stdout.sync = true
    "ITEM-#{x}"
  end
end

[{ in_processes: 2 }, { in_threads: 2 }, { in_threads: 0 }].each do |options|
  puts(Parallel.map(generate_proc, options) { |(i, _id)| Callback.call i })
end
