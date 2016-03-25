require './spec/cases/helper'
require "active_record"
require "mysql2"
STDOUT.sync = true
in_worker_type = "in_#{ENV.fetch('WORKER_TYPE')}".to_sym

database = "parallel_with_ar_test"
ActiveRecord::Schema.verbose = false
ENV["DATABASE_URL"] = "mysql2://root@localhost/#{database}"

# Assumes 'root'@'localhost' has no password
`mysql -u root #{database} -e '' || mysql -u root -e 'create database #{database};'`
ActiveRecord::Base.establish_connection

class User < ActiveRecord::Base
end

# create tables
unless User.table_exists?
  ActiveRecord::Schema.define(:version => 1) do
    create_table :users do |t|
      t.string :name
    end
  end
end

User.delete_all

3.times { User.create!(:name => "X") }

print "Parent: "
puts User.first.name


# Run with both disabled and enabled Parallel (AR workarounds shouldn't break 0)
[0,1].each do |zero_one|
  print "Parallel (#{in_worker_type} => #{zero_one}): "
  Parallel.each([1], in_worker_type => 0) do
    puts User.all.map(&:name).join
  end
end

print "\nParent: "
puts User.first.name
