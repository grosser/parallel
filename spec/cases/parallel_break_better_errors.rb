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
    ex = Parallel::Break.new
    # better_errors sets an instance variable that contains an array of bindings.
    ex.instance_variable_set :@__better_errors_bindings_stack, [ex.send(:binding)]
    raise ex
  end
  puts "NOTHING WAS RAISED"
rescue StandardError
  puts $!.message
  puts "BACKTRACE: #{$!.backtrace.first}"
end
