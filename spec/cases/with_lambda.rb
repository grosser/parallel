# frozen_string_literal: true
require './spec/cases/helper'

$stdout.sync = true
type = :"in_#{ARGV.fetch(0)}"
all = [3, 2, 1]
produce = -> { all.pop || Parallel::Stop }

class Callback
  def self.call(x)
    $stdout.sync = true
    "ITEM-#{x}"
  end
end

if type == :in_ractors
  puts(Parallel.map(produce, type => 2, ractor: [Callback, :call]))
else
  puts(Parallel.map(produce, type => 2) { |(i, _id)| Callback.call i })
end
