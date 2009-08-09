namespace :parallel do
  desc "prepare parallel test running by calling db:reset for every test database needed with parallel:prepare[num_cpus]"
  task :prepare, :count do |t,args|
    require File.join(File.dirname(__FILE__), '..', 'lib', "parallel_tests")

    num_processes = (args[:count] || ParallelTests.processor_count).to_i
    ParallelTests.in_parallel(num_processes) do |i|
      puts "Preparing database #{i + 1}"
      `export TEST_ENV_NUMBER=#{ParallelTests.test_env_number(i)} ; rake db:test:prepare`
    end
  end

  [
    ["tests", "test", "test"],
    ["specs", "spec", "spec"],
    ["cucumber", "feature", "features"]
  ].each do |lib, name, task|
    desc "run #{name}s in parallel with parallel:#{task}[num_cpus]"
    task task, :count, :path_prefix do |t,args|
      require File.join(File.dirname(__FILE__), '..', 'lib', "parallel_#{lib}")
      klass = eval("Parallel#{lib.capitalize}")

      start = Time.now

      num_processes = (args[:count] || klass.processor_count).to_i
      tests_folder = File.join(RAILS_ROOT, task, args[:path_prefix].to_s)
      groups = klass.tests_in_groups(tests_folder, num_processes)
      num_tests = groups.sum { |g| g.size }
      
      puts "#{num_processes} processes for #{num_tests} #{name}s, ~ #{num_tests / num_processes} #{name}s per process"

      output = ParallelTests.in_parallel(num_processes) do |process_number|
        klass.run_tests(groups[process_number], process_number)
      end

      #parse and print results
      results = klass.find_results(output*"")
      puts ""
      puts "Results:"
      results.each{|r| puts r}

      #report total time taken
      puts ""
      puts "Took #{Time.now - start} seconds"

      #exit with correct status code
      # - rake parallel:test && echo 123 ==> 123 should not show up when test failed
      # - rake parallel:test db:reset ==> works when tests succeed
      abort "#{name.capitalize}s Failed" if klass.failed?(results)
    end
  end
end


#backwards compatability
#spec:parallel:prepare
#spec:parallel
#test:parallel
namespace :spec do
  namespace :parallel do
    task :prepare, :count do |t,args|
      $stderr.puts "WARNING -- Deprecated!  use parallel:prepare"
      Rake::Task['parallel:prepare'].invoke(args[:count])
    end
  end

  task :parallel, :count, :path_prefix do |t,args|
    $stderr.puts "WARNING -- Deprecated! use parallel:spec"
    Rake::Task['parallel:spec'].invoke(args[:count], args[:path_prefix])
  end
end
namespace :test do
  task :parallel, :count, :path_prefix do |t,args|
    $stderr.puts "WARNING -- Deprecated! use parallel:test"
    Rake::Task['parallel:test'].invoke(args[:count], args[:path_prefix])
  end
end