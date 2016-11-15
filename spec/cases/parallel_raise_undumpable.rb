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
  puts "NOTHING WAS RAISED"
rescue
  puts $!.message
  puts "BACKTRACE: #{$!.backtrace.first}"
end
