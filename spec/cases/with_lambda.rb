# frozen_string_literal: true
require './spec/cases/helper'

type = case ARGV[0]
       when "PROCESSES" then :in_processes
       when "THREADS" then :in_threads
       else
         raise "Use PROCESSES or THREADS"
end

all = [3, 2, 1]
produce = -> { all.pop || Parallel::Stop }
puts Parallel.map(produce, type => 2) { |(i, _id)| "ITEM-#{i}" }
