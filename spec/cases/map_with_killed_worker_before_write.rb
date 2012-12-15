require File.expand_path('spec/spec_helper')

Parallel::Worker.class_eval do
  alias_method :work_without_kill, :work
  def work(*args)
    Process.kill("SIGKILL", pid)
    sleep 0.5
    work_without_kill(*args)
  end
end

begin
  Parallel.map([1,2,3]) do |x, i|
    Process.kill("SIGKILL", Process.pid)
  end
rescue Parallel::DeadWorker
  puts "DEAD"
end
