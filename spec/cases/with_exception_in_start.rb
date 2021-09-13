# frozen_string_literal: true
require './spec/cases/helper'

method = ENV.fetch('METHOD')
in_worker_type = "in_#{ENV.fetch('WORKER_TYPE')}".to_sym

begin
  start = lambda do |_item, _index|
    @started = @started ? @started + 1 : 1
    raise 'foo' if @started == 4
  end

  Parallel.public_send(method, 1..100, in_worker_type => 4, start: start) do |x|
    print x
    sleep 0.2 # so now no work gets queued before exception is raised
    x
  end
rescue StandardError
  print ' raised'
end
