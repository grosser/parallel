require File.expand_path('spec/spec_helper')

class NotDumpable
  def marshal_dump
    raise "NOOOO"
  end

  def to_s
    'not dumpable'
  end
end

Parallel.each([NotDumpable.new]) do |x|
  print 'not dumpable'
  x
end