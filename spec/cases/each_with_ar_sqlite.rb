# frozen_string_literal: true
require './spec/cases/helper'
require "active_record"
require "sqlite3"
require "tempfile"
$stdout.sync = true
in_worker_type = "in_#{ENV.fetch('WORKER_TYPE')}".to_sym

Tempfile.create("db") do |temp|
  ActiveRecord::Schema.verbose = false
  ActiveRecord::Base.establish_connection(
    adapter: "sqlite3",
    database: temp.path
  )

  class User < ActiveRecord::Base # rubocop:disable Lint/ConstantDefinitionInBlock
  end

  # create tables
  unless User.table_exists?
    ActiveRecord::Schema.define(version: 1) do
      create_table :users do |t|
        t.string :name
      end
    end
  end

  User.delete_all

  3.times { User.create!(name: "X") }

  puts "Parent: #{User.first.name}"

  Parallel.each([1], in_worker_type => 1) do
    puts "Parallel (#{in_worker_type}): #{User.all.map(&:name).join}"
  end

  puts "Parent: #{User.first.name}"
end
