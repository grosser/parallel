require File.join(File.dirname(__FILE__), 'parallel_tests')

class ParallelCucumber < ParallelTests
  def self.run_tests(test_files, process_number)
    cmd = "export TEST_ENV_NUMBER=#{test_env_number(process_number)} ; script/cucumber #{test_files*' '}"
    execute_command(cmd)
  end

  protected

  def self.test_result_seperator
    ' '
  end

  def self.line_is_result?(line)
    line =~ /^\d+ steps/
  end
  
  def self.line_is_failure?(line)
    line =~ /^\d+ steps.*(\d{2,}|[1-9]) failed/
  end

  def self.find_tests(root)
    Dir["#{root}**/**/*.feature"]
  end
end