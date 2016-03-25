require './spec/cases/helper'
require "active_record"
require "mysql2"
STDOUT.sync = true

database = "parallel_with_ar_test"
ActiveRecord::Schema.verbose = false
ENV["DATABASE_URL"] = "mysql2://root@localhost/#{database}"

# Assumes 'root'@'localhost' has no password
`mysql -u root #{database} -e '' || mysql -u root -e 'create database #{database};'`

require "./spec/cases/each_with_ar_generic"
