class ParallelTests
  # finds all tests and partitions them into groups
  def self.tests_in_groups(root, num)
    tests_with_sizes = find_tests_with_sizes(root)

    groups = []
    current_group = current_size = 0
    tests_with_sizes.each do |test, size|
      current_size += size
      # inserts into next group if current is full and we are not in the last group
      if current_size > group_size(tests_with_sizes, num) and num > current_group + 1
        current_size = 0
        current_group += 1
      end
      groups[current_group] ||= []
      groups[current_group] << test
    end
    groups
  end

  def self.run_tests(test_files, process_number)
    require_list = test_files.map { |filename| "\"#{filename}\"" }.join(",")
    cmd = "export RAILS_ENV=test ; export TEST_ENV_NUMBER=#{test_env_number(process_number)} ; ruby -Itest -e '[#{require_list}].each {|f| require f }'"
    execute_command(cmd)
  end

  def self.execute_command(cmd)
    f = open("|#{cmd}")
    all = ''
    while out = f.gets(".")#split by '.' because every test is a '.'
      all+=out
      print out
      STDOUT.flush
    end
    all
  end

  def self.find_results(test_output)
    test_output.split("\n").map {|line|
      line = line.gsub(/\.|F|\*/,'')
      next unless line =~ /\d+ failure/
      line
    }.compact
  end

  def self.failed?(results)
    !! results.detect{|r| r=~ /[1-9] (failure|error)/}
  end

  def self.test_env_number(process_number)
    process_number == 0 ? '' : process_number + 1
  end

  #wait for processes to finish
  def self.wait_for_processes(pids)
    kill_on_ctrl_c(pids)
    pids.each{Process.wait}
  end

  protected
  def self.get_processor_number
    case RUBY_PLATFORM
    when /darwin/
      `hwprefs cpu_count`.to_i
    when /linux/
      `cat /proc/cpuinfo | grep processor | wc -l`.to_i
  end
  
  #handle user interrup (Ctrl+c)
  def self.kill_on_ctrl_c(pids)
    Signal.trap 'SIGINT' do
      STDERR.puts "Parallel execution interrupted, exiting ..."
      pids.each { |pid| Process.kill("KILL", pid) }
      exit 1
    end
  end

  def self.group_size(tests_with_sizes, num_groups)
    total_size = tests_with_sizes.inject(0) { |sum, test| sum += test[1] }
    total_size / num_groups.to_f
  end

  def self.find_tests_with_sizes(root)
    tests = find_tests(root).sort
    tests.map { |test| [ test, File.stat(test).size ] }
  end

  def self.find_tests(root)
    Dir["#{root}**/**/*_test.rb"]
  end
end