require File.expand_path('spec/spec_helper')

Parallel.each((0..200).to_a, :in_processes=>200) do |x|
  sleep 1
end
print 'OK'