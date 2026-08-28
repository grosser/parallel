# frozen_string_literal: true
require './spec/cases/helper'

class DiscardedResultCallback
  def self.call(item)
    -> { item }
  end
end

source = [1, 2]
result = Parallel.each(
  source,
  in_ractors: 2,
  ractor: [DiscardedResultCallback, :call]
)
print(result.equal?(source) ? "OK" : "FAIL")
