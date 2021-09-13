# frozen_string_literal: true
require 'bundler/setup'
require 'bundler/gem_tasks'
require 'bump/tasks'
require "rspec/core/rake_task"
require 'rspec-rerun/tasks'

task default: ["spec", "rubocop"]

desc "Run tests"
task spec: "rspec-rerun:spec"

desc "Run rubocop"
task :rubocop do
  sh "rubocop --parallel"
end
