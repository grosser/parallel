# frozen_string_literal: true
require 'parallel'
require 'benchmark'
require 'timeout'

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :should }
  config.mock_with(:rspec) { |c| c.syntax = :should }
  config.around { |example| Timeout.timeout(30, &example) }
  config.include(
    Module.new do
      def ruby(cmd)
        `#{RbConfig.ruby} #{cmd}`
      end
    end
  )
end
