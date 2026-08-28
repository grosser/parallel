# frozen_string_literal: true
require './spec/cases/helper'

# raise file limit so we don't hit EMFILE
_soft, hard = Process.getrlimit(Process::RLIMIT_NOFILE)
Process.setrlimit(Process::RLIMIT_NOFILE, hard, hard)

Parallel.each((0..200).to_a, in_processes: 200) do |_x|
  sleep 0.1
end
print 'OK'
