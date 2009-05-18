namespace :spec do
  def parallel_with_copied_envs(num_processes)
    plugin_root = File.join(File.dirname(__FILE__), '..')
    rails_root =  File.join(plugin_root, '..', '..', '..')

    require File.join(plugin_root, 'lib', 'parallel_specs')

    num_processes = (num_processes||1).to_i
    ParallelSpecs.with_copied_envs(rails_root, num_processes) do
      yield(num_processes)
    end
  end

  namespace :parallel do
    desc "prepare parallel test running by calling db:reset for every env needed with spec:parallel:"
    task :prepare, :count do |t,args|
      parallel_with_copied_envs(args[:count]) do |num_processes|
        num_processes.times do |i|
          env = "test#{i==0?'':i+1}"
          puts "Preparing #{env}"
          `RAILS_ENV=#{env} ; rake db:reset`
        end
      end
    end
  end

  desc "run specs in parallel with spec:parallel[count]"
  task :parallel, :count do |t,args|
    parallel_with_copied_envs(args[:count]) do |num_processes|
      puts "running specs in #{num_processes} processes"
      start = Time.now
      #find all specs and partition them into groups
      specs = (Dir["spec/**/*_spec.rb"]).sort
      specs_per_group = specs.size/num_processes
      puts "#{specs_per_group} specs per process"

      groups = []
      num_processes.times do |i|
        specs_per_group.times do |j|
          groups[i] ||=[]
          groups[i] << specs[j+i]
        end
      end

      #run each of the groups
      pids = []
      num_processes.times do |i|
        puts "starting process #{i+1}"
        pids << Process.fork do
          puts `RAILS_ENV=test#{i==0?'':i+1}; spec -O spec/spec.opts #{groups[i]*' '}`
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