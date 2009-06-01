namespace :spec do
  def parallel_with_copied_envs(num_processes)
    plugin_root = File.join(File.dirname(__FILE__), '..')
    require File.join(plugin_root, 'lib', 'parallel_specs')

    num_processes = (num_processes||2).to_i
    ParallelSpecs.with_copied_envs(RAILS_ROOT, num_processes) do
      yield(num_processes)
    end
  end

  namespace :parallel do
    desc "prepare parallel test running by calling db:reset for every test database needed with spec:parallel:"
    task :prepare, :count do |t,args|
      parallel_with_copied_envs(args[:count]) do |num_processes|
        num_processes.times do |i|
          puts "Preparing test database #{i+1}"
          `export INSTANCE=#{i==0?'':i+1}; export RAILS_ENV=test; rake db:reset`
        end
      end
    end
  end

  desc "run specs in parallel with spec:parallel[count]"
  task :parallel, :count do |t,args|
    parallel_with_copied_envs(args[:count]) do |num_processes|
      puts "running specs in #{num_processes} processes"
      start = Time.now

      groups = ParallelSpecs.specs_in_groups(RAILS_ROOT, num_processes)
      puts "#{groups.sum{|g|g.size}} specs in #{groups[0].size} specs per process"

      #run each of the groups
      pids = []
      num_processes.times do |i|
        puts "starting process #{i+1}"
        pids << Process.fork do
          sh "export INSTANCE=#{i==0?'':i+1}; script/spec -O spec/spec.opts #{groups[i]*' '}"
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
end
