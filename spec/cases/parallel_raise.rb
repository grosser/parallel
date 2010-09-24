require File.expand_path('spec/spec_helper')

begin
  Parallel.in_processes(2) do
    raise "TEST"
  end
  puts "FAIL"
rescue RuntimeError
  puts $!.message
end