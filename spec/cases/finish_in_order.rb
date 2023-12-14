# frozen_string_literal: true

require './spec/cases/helper'

class Callback
  def self.call(_item)
    sleep rand * 0.01
  end
end

method = ENV.fetch('METHOD')
in_worker_type = "in_#{ENV.fetch('WORKER_TYPE')}".to_sym
$stdout.sync = true

items = 1..9
finish = ->(item, _index, _result) { puts "finish #{item}" }
options = { in_worker_type => 4, finish: finish, finish_in_order: true }
if in_worker_type == :in_ractors
  Parallel.public_send(method, items, options.merge(ractor: [Callback, :call]))
else
  Parallel.public_send(method, items, options) { |item| Callback.call(item) }
end
