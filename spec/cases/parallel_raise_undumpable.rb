require './spec/cases/helper'
require 'stringio'

class MyException < StandardError
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
