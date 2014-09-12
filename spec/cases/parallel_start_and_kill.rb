require './spec/cases/helper'

method = case ARGV[0]
when "PROCESS" then :in_processes
when "THREAD" then :in_threads
else raise "Learn to use this!"
end

options = {}
options[:count] = 2
options[:interrupt_signal] = ARGV[1].to_s if ARGV.length > 1
trap('SIGINT') { puts 'Wrapper caught SIGINT' } if ARGV.length > 1 && ARGV[1] != 'SIGINT'

Parallel.send(method, options) do
  sleep 10
  puts "I should have been killed earlier..."
end
