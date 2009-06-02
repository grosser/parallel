namespace :spec do
  namespace :parallel do
    desc "prepare parallel test running by calling db:reset for every env needed with spec:parallel:"
    task :prepare, :count do |t,args|
      num_processes = (args[:count] || 2).to_i
      num_processes.times do |i|
        puts "Preparing database #{i+1}"
        `export TEST_ENV_NUMBER=#{i==0?'':i+1} ; rake db:reset`
      end
    end
  end

  desc "run specs in parallel with spec:parallel[count]"
  task :parallel, :count do |t,args|
    start = Time.now

    plugin_root = File.join(File.dirname(__FILE__), '..')
    require File.join(plugin_root, 'lib', 'parallel_specs')

    num_processes = (args[:count] || 2).to_i
    groups = ParallelSpecs.specs_in_groups(RAILS_ROOT, num_processes)
    puts "#{num_processes} processes: #{groups.sum{|g|g.size}} specs in  (#{groups[0].size} specs per process)"

    #run each of the groups
    pids = []
    num_processes.times do |i|
      puts "Starting process #{i+1}"
      pids << Process.fork do
        puts `export TEST_ENV_NUMBER=#{i==0?'':i+1}; spec -O spec/spec.opts #{groups[i]*' '}`
      end
    end

    #handle user interrup
    interrupt_handler = lambda do
      STDERR.puts "interrupt, exiting ..."
      pids.each { |pid| Process.kill "KILL", pid }
      exit 1
    end
    Signal.trap 'SIGINT', interrupt_handler

    #wait for everybody to finish
    pids.each{ Process.wait }

    #report total time taken
    puts "Took #{Time.now - start} seconds"
  end
end
