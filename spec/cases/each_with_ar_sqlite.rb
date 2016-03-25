require './spec/cases/helper'
require "active_record"
require "sqlite3"
STDOUT.sync = true

ActiveRecord::Schema.verbose = false
ENV["DATABASE_URL"] = "sqlite3:parallel_with_ar_test.sqlite3"

require "./spec/cases/each_with_ar_generic"

# Delete the sqlite3 file.  :memory: was neat, but once you disconnect, it's just gone.
`rm parallel_with_ar_test.sqlite3`
