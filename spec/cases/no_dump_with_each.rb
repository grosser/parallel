require File.expand_path('spec/spec_helper')

class NotDumpable
  def marshal_dump
    raise "NOOOO"
  end

  def to_s
    'not dumpable'
  end
end

Parallel.each([1]) do
  print 'no dump for result'
  NotDumpable.new
end

Parallel.each([NotDumpable.new]) do
  print 'no dump for each'
  1
end