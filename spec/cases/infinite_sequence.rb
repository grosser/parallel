# frozen_string_literal: true

# Reproduction case based on GitHub Issue #211
# Original code provided by @cyclotron3k in the issue
# using a enum that is infinite, so this will hang forever when trying to convert to an array

require 'prime'
require './spec/cases/helper'

private_key = 12344567899

results = []

[{ in_threads: 2 }, { in_threads: 0 }].each do |options|
  primes = Prime.to_enum
  Parallel.each(primes, options) do |prime|
    if private_key % prime == 0
      results << prime.to_s
      raise Parallel::Break
    end
  end
end

print results.join(',')
