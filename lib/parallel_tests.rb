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
    while out = f.gets(test_result_seperator)
      all+=out
      print out
      STDOUT.flush
    end
    all
  end

  def self.find_results(test_output)
    test_output.split("\n").map {|line|
      line = line.gsub(/\.|F|\*/,'')
      next unless line_is_result?(line)
      line
    }.compact
  end

  def self.failed?(results)
    !! results.detect{|line| line_is_failure?(line)}
  end

  def self.test_env_number(process_number)
    process_number == 0 ? '' : process_number + 1
  end

  def self.processor_count
    case RUBY_PLATFORM
    when /darwin/
      `hwprefs cpu_count`.to_i
    when /linux/
      `cat /proc/cpuinfo | grep processor | wc -l`.to_i
    end
  end

  #collector for parallel results in string format
  #indicates which process it is through first argument
  #
  # in_parallel(2) do |i| --> i = 0, 1
  #   some_method_that_returns_a_string(i)
  # end
  #
  # - created sub-processes are killed if this process is killed through Ctrl+c
  def self.in_parallel(count)
    #start writing results into n pipes
    reads = []
    writes = []
    pids = []
    count.times do |i|
      reads[i], writes[i] = IO.pipe
      pids << Process.fork{ writes[i].print yield(i) }
    end

    kill_on_ctrl_c(pids)

    #collect results from pipes simultanously
    #otherwise pipes get stuck when to much is written (buffer full)
    out = []
    collectors = []
    count.times do |i|
      collectors << Thread.new do
        writes[i].close

        out[i]=""
        while text = reads[i].gets
          out[i] += text
        end

        reads[i].close
      end
    end

    collectors.each{|c|c.join}

    out
  end

  protected

  def self.test_result_seperator
    "."
  end

  def self.line_is_result?(line)
    line =~ /\d+ failure/
  end
  
  def self.line_is_failure?(line)
    line =~ /(\d{2,}|[1-9]) (failure|error)/
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