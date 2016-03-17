require './spec/cases/helper'
STDOUT.sync = true # otherwise results can go weird...

Parallel.tasks do |tasks|
  tasks.add{puts 'one task'}
  tasks.add{system("echo 'another task'")}
end
