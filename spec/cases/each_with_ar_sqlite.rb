require './spec/cases/helper'
require "active_record"
require "sqlite3"
STDOUT.sync = true

ActiveRecord::Schema.verbose = false
ENV["DATABASE_URL"] = "sqlite3:#{Tempfile.new("db").path}"

require "./spec/cases/each_with_ar_generic"
