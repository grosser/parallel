require File.expand_path('spec/spec_helper')

begin
  output = "FAIL"
  Parallel.in_processes(count: 2, error_handler: proc{|e| output = "TEST" }) do
    raise "FAIL"
  end
  puts output
rescue RuntimeError
  puts $!.message
end

