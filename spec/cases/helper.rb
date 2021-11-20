# frozen_string_literal: true
require 'bundler/setup'
require 'parallel'

def process_diff
  called_from = caller(1)[0].split(":").first # forks will have the source file in their name
  cmd = "ps uxw|grep #{called_from}|wc -l"

  processes_before = `#{cmd}`.to_i

  yield

  sleep 1

  processes_after = `#{cmd}`.to_i

  if processes_before == processes_after
    print 'OK'
  else
    print "FAIL: before:#{processes_before} -- after:#{processes_after}"
  end
end
