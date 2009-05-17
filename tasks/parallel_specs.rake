namespace :spec do
  task :parallel, :count do |t,args|
    start = Time.now

    num_processes = (args[:count]||1).to_i
    puts "running specs in #{num_processes} processes"

    #copy test env for each process, hacky but works :P
    env_files = []
    num_processes.times do |i|
      env_files << "config/environments/test#{i}.rb"
    end
    env_files.each{|f| `cp -f config/environments/test.rb #{f}`}

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
        puts `RAILS_ENV=test#{i==0?'':i}; spec -O spec/spec.opts #{groups[i]*' '}`
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

    #cleanup envs
    env_files.each{|f| `rm #{f}`}

    #report total time taken
    puts "Took #{Time.now - start} seconds"
  end
end