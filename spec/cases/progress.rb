# frozen_string_literal: true
require './spec/cases/helper'

title = (ENV["TITLE"] == "true" ? true : "Doing stuff")
Parallel.map(1..10, progress: title) do
  sleep 1 if $stdout.tty? # for debugging
end
