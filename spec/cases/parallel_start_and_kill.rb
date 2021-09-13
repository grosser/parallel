# frozen_string_literal: true
require './spec/cases/helper'

method = case ARGV[0]
         when "PROCESS" then :in_processes
         when "THREAD" then :in_threads
         else raise "Learn to use this!"
end

options = {}
options[:count] = 2
if ARGV.length > 1
  options[:interrupt_signal] = ARGV[1].to_s
  trap('SIGINT') { puts 'Wrapper caught SIGINT' } if ARGV[1] != 'SIGINT'
end

Parallel.send(method, options) do
  sleep 5
  puts "I should have been killed earlier..."
end
