namespace :spec do
  namespace :parallel do
    desc "prepare parallel test running by calling db:reset for every test database needed with spec:parallel:"
    task :prepare, :count do |t,args|
      num_processes = (args[:count] || 2).to_i
      num_processes.times do |i|
        puts "Preparing database #{i + 1}"
        `export TEST_ENV_NUMBER=#{i == 0 ? '' : i + 1} ; export RAILS_ENV=test ; rake db:reset`
      end
    end
  end

  desc "run specs in parallel with spec:parallel[count]"
  task :parallel, :count do |t,args|
    require File.join(File.dirname(__FILE__), '..', 'lib', 'parallel_specs')

    start = Time.now

    num_processes = (args[:count] || 2).to_i
    groups = ParallelSpecs.specs_in_groups(RAILS_ROOT, num_processes)

    num_specs = groups.sum { |g| g.size }
    puts "#{num_processes} processes for #{num_specs} specs, ~ #{num_specs / num_processes} specs per process"

    #run each of the groups
    pids = []
    read, write = IO.pipe
    groups.each_with_index do |files, process_number|
      pids << Process.fork do
        write.puts ParallelSpecs.run_tests(files, process_number)
      end
    end

    #handle user interrup (Ctrl+c)
    Signal.trap 'SIGINT' do
      STDERR.puts "Parallel specs interrupted, exiting ..."
      pids.each { |pid| Process.kill("KILL", pid) }
      exit 1
    end

    #wait for processes to finish
    pids.each { Process.wait }


    #parse and print results
    write.close
    results = ParallelSpecs.find_results(read.read)
    read.close
    puts ""
    puts "Results:"
    results.each{|r| puts r}

    #report total time taken
    puts ""
    puts "Took #{Time.now - start} seconds"

    #exit with correct status code
    exit ParallelSpecs.failed?(results) ? 1 : 0
  end
end