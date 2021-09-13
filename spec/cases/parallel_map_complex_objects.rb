# frozen_string_literal: true
require './spec/cases/helper'

object = ["\nasd#{File.read('Gemfile')}--#{File.read('Rakefile')}" * 100, 12_345, { b: :a }]

result = Parallel.map([1, 2]) do |_x|
  object
end
print 'YES' if result.inspect == [object, object].inspect
