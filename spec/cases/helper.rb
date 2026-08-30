# frozen_string_literal: true
require 'bundler/setup'
require 'parallel'

def process_diff
  called_from = caller(1)[0].split(":").first # forks will have the source file in their name
  cmd = "ps uxw|grep #{called_from}|wc -l"

  processes_before = `#{cmd}`.to_i

  yield

  sleep 0.5

  processes_after = `#{cmd}`.to_i

  if processes_before == processes_after
    print 'OK'
  else
    print "FAIL: before:#{processes_before} -- after:#{processes_after}"
  end
end

# poll since ractors terminate asynchronously after being stopped
def assert_ractors_stopped(before)
  deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2
  loop do
    workers = ObjectSpace.each_object(Ractor).to_a - before
    break if workers.empty? || workers.all? { |worker| worker.inspect.include?("terminated") }
    raise "ractor worker did not terminate" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
    Thread.pass
  end
end
