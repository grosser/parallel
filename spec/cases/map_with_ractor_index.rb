# frozen_string_literal: true
require './spec/cases/helper'

class IndexedCallback
  def self.call(item, index)
    [item, index]
  end
end

result = Parallel.map_with_index(
  ["a", "b"],
  in_ractors: 2,
  ractor: [IndexedCallback, :call]
)
print result.inspect
