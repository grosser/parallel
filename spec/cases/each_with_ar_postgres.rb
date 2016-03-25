require './spec/cases/helper'
require "active_record"
require "pg"
STDOUT.sync = true

database = "parallel_with_ar_test"
ActiveRecord::Schema.verbose = false
ENV["DATABASE_URL"] = "postgres://postgres@localhost/#{database}"

# Assumes 'postgres' user is SUPERUSER
`createdb #{database}` unless `psql -l | grep parallel_with_ar_test`

require "./spec/cases/each_with_ar_generic"
