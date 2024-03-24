# frozen_string_literal: true

require './spec/cases/helper'

class Callback
  def self.call(item)
    sleep rand * 0.01
    item.is_a?(Numeric) ? "F#{item}" : item
  end
end

method = ENV.fetch('METHOD')
in_worker_type = :"in_#{ENV.fetch('WORKER_TYPE')}"
$stdout.sync = true

items = [nil, false, 2, 3, 4]
finish = ->(item, index, result) { puts "finish #{item.inspect} #{index} #{result.inspect}" }
options = { in_worker_type => 4, finish: finish, finish_in_order: true }
if in_worker_type == :in_ractors
  Parallel.public_send(method, items, options.merge(ractor: [Callback, :call]))
else
  Parallel.public_send(method, items, options) { |item| Callback.call(item) }
end
