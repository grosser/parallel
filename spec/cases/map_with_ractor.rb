# frozen_string_literal: true
require './spec/cases/helper'

class Callback
  def self.call(arg)
    "#{arg}x"
  end
end

result = Parallel.map(ENV['INPUT'].chars, in_ractors: Integer(ENV["COUNT"] || 2), ractor: [Callback, :call])
print result * ''
