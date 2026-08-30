# frozen_string_literal: true
require './spec/cases/helper'

in_worker_type = :"in_#{ENV.fetch('WORKER_TYPE')}"

class EachReturnsSourceCallback
  def self.call(item)
    item * 2
  end
end

source = [1, 2]
options = { in_worker_type => 2, finish: ->(*) {} }
result =
  if in_worker_type == :in_ractors
    Parallel.each(source, options.merge(ractor: [EachReturnsSourceCallback, :call]))
  else
    Parallel.each(source, options) { |item| EachReturnsSourceCallback.call(item) }
  end
print(result.equal?(source) ? "OK" : "FAIL")
