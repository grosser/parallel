require 'bundler/setup'
require 'bundler/gem_tasks'
require 'bump/tasks'
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = '--backtrace --color'
end

task :default => :spec
