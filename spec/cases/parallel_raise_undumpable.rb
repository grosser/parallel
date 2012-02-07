require File.expand_path('spec/spec_helper')
require 'stringio'

class MyException < Exception
  def initialize(object)
    @object = object
  end
end

begin
  Parallel.in_processes(2) do
    raise MyException.new(StringIO.new)
  end
  puts "FAIL"
rescue RuntimeError
  puts $!.message
end