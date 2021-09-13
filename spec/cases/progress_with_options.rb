# frozen_string_literal: true
require './spec/cases/helper'

# ruby-progressbar ignores the format string you give it
# unless the output is a TTY.  When running in the test,
# the output is not a TTY, so we cannot test that the format
# string you pass overrides parallel's default.  So, we pretend
# that stdout is a TTY to test that the options are merged
# in the correct way.
tty_stdout = $stdout
class << tty_stdout
  def tty?
    true
  end
end

parallel_options = {
  progress: {
    title: "Reticulating Splines",
    progress_mark: ';',
    format: "%t %w",
    output: tty_stdout
  }
}

Parallel.map(1..50, parallel_options) do
  2
end
