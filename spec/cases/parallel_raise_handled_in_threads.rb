require File.expand_path('spec/spec_helper')

begin
  output = "FAIL"
  Parallel.map([1,2,3,4], error_handler: proc{|e| output = "TEST" }) do
    raise "FAIL"
  end
  puts output
rescue RuntimeError
  puts $!.message
end
