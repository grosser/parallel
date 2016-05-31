require './spec/cases/helper'

process_diff do
  result = Parallel.map([1,2,3,4], in_processes: 2, isolation: true) do |i|
    Thread.current[:parallel_worker_number]
  end
  puts result.uniq.sort.join(',')
end
