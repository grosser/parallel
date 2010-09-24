require File.expand_path('spec/spec_helper')
cmd = "ps uaxw|grep ruby|wc -l"

processes_before = `#{cmd}`.to_i
Parallel.each((0..10).to_a, :in_processes => 5) { |a| a*2 }
processes_after = `#{cmd}`.to_i

if processes_before == processes_after
  print 'OK'
else
  print "FAIL: before:#{processes_before} -- after:#{processes_after}"
end