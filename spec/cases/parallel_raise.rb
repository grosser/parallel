require 'spec/spec_helper.rb'

begin
  Parallel.in_processes(2) do
    raise "TEST"
  end
  puts "FAIL"
rescue RuntimeError
  puts $!.message
end