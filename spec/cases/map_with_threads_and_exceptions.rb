require File.expand_path('spec/spec_helper')

class Parallel
  def self.wait_for_threads(threads)
    print ' all joined'
  end
end

begin
  Parallel.map(1..100, :in_threads => 4) do |x|
    print x
    raise 'foo' if x == 1
  end
rescue
  print ' raised'
end