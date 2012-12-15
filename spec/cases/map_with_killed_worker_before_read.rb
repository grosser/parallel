require File.expand_path('spec/spec_helper')

begin
  Parallel.map([1,2,3]) do |x, i|
    Process.kill("SIGKILL", Process.pid)
  end
rescue Parallel::DeadWorker
  puts "DEAD"
end
