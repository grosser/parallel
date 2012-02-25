require File.expand_path('spec/spec_helper')

object = ["\nasd#{File.read('Gemfile')}--#{File.read('Rakefile')}"*100, 12345, {:b=>:a}]

result = Parallel.map([1,2]) do |x|
  object
end
print 'YES' if result.inspect == [object, object].inspect
