# frozen_string_literal: true
require './spec/cases/helper'
require "active_record"

database = "parallel_with_ar_test"
`mysql #{database} -e '' || mysql -e 'create database #{database}'`

ActiveRecord::Schema.verbose = false
ActiveRecord::Base.establish_connection(
  adapter: "mysql2",
  database: database
)

class User < ActiveRecord::Base
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

User.create!(name: "X")

Parallel.map(1..8) do |i|
  User.create!(name: i)
end

puts "User.count: #{User.count}"

puts User.connection.reconnect!.inspect

Parallel.map(1..8, in_threads: 4) do |i|
  User.create!(name: i)
end

User.create!(name: "X")

puts User.all.map(&:name).sort.join("-")
