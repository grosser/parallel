# frozen_string_literal: true
require 'bundler/setup'
require 'parallel'

def process_diff
  cmd = "ps uxw|grep ruby|wc -l"

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
