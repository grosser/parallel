require './spec/cases/helper'
require "active_record"
require "sqlite3"
STDOUT.sync = true
in_worker_type = "in_#{ENV.fetch('WORKER_TYPE')}".to_sym

ActiveRecord::Schema.verbose = false
params = { adapter: "sqlite3", database: "parallel_with_ar_test.sqlite3" }
ActiveRecord::Base.establish_connection(params)

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

# https://www.sqlite.org/faq.html
# Under Unix, you should not carry an open SQLite database across a fork() system call into the child process.
ActiveRecord::Base.connection.disconnect!

print "Parallel (#{in_worker_type}): "
Parallel.each([1], in_worker_type => 1) do
  ActiveRecord::Base.establish_connection(params)
  puts User.all.map(&:name).join
end

ActiveRecord::Base.establish_connection(params)
print "\nParent: "
puts User.first.name

# Delete the sqlite3 file.  :memory: was neat, but once you disconnect, it's just gone.
`rm parallel_with_ar_test.sqlite3`