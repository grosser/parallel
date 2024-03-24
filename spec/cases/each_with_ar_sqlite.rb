# frozen_string_literal: true
require './spec/cases/helper'
require "active_record"
require "sqlite3"
require "tempfile"
$stdout.sync = true
in_worker_type = :"in_#{ENV.fetch('WORKER_TYPE')}"

Tempfile.create("db") do |temp|
  ActiveRecord::Schema.verbose = false
  ActiveRecord::Base.establish_connection(
    adapter: "sqlite3",
    database: temp.path
  )

  class User < ActiveRecord::Base # rubocop:disable Lint/ConstantDefinitionInBlock
  end

  class Callback # rubocop:disable Lint/ConstantDefinitionInBlock
    def self.call(_)
      $stdout.sync = true
      puts "Parallel: #{User.all.map(&:name).join}"
    end
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

  if in_worker_type == :in_ractors
    Parallel.each([1], in_worker_type => 1, ractor: [Callback, :call])
  else
    Parallel.each([1], in_worker_type => 1) { |x| Callback.call x }
  end

  puts "Parent: #{User.first.name}"
end
