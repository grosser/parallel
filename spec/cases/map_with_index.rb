# frozen_string_literal: true
require './spec/cases/helper'

class Callback
  def self.call(item, index)
    "#{item}#{index}"
  end
end

type = ENV.fetch("WORKER_TYPE")
result =
  if type == "ractors"
    Parallel.map_with_index(['a', 'b'], in_ractors: 2, ractor: [Callback, :call])
  else
    Parallel.map_with_index(['a', 'b'], "in_#{type}": 2) { |x, i| Callback.call(x, i) }
  end
print result * ''
