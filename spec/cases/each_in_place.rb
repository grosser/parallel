# frozen_string_literal: true
require './spec/cases/helper'
$stdout.sync = true # otherwise results can go weird...

x = [+'a']
Parallel.each(x, in_threads: 1) { |y| y << 'b' }
print x.first
