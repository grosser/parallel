require 'spec/spec_helper.rb'

class NotDumpable
  def marshal_dump
    raise "NOOOO"
  end

  def to_s
    'not dumpable'
  end
end

Parallel.each([NotDumpable.new]) do |x|
  puts 'not dumpable'
  x
end