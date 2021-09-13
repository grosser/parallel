# frozen_string_literal: true
require './spec/cases/helper'
require 'stringio'

class MyException < StandardError
  def initialize(object)
    super()
    @object = object
  end
end

begin
  Parallel.in_processes(2) do
    raise MyException, StringIO.new
  end
  puts "NOTHING WAS RAISED"
rescue StandardError
  puts $!.message
  puts "BACKTRACE: #{$!.backtrace.first}"
end
