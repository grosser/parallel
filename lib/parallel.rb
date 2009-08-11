class Parallel
  def self.in_parallel(count=nil)
    count ||= processor_count

    #start writing results into n pipes
    reads = []
    writes = []
    pids = []
    count.times do |i|
      reads[i], writes[i] = IO.pipe
      pids << Process.fork{ Marshal.dump(yield(i), writes[i]) } #write serialized result
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

    out.map{|x| Marshal.load(x)} #deserialize
  end

  def self.processor_count
    case RUBY_PLATFORM
    when /darwin/
      `hwprefs cpu_count`.to_i
    when /linux/
      `cat /proc/cpuinfo | grep processor | wc -l`.to_i
    end
  end

  private

  #handle user interrup (Ctrl+c)
  def self.kill_on_ctrl_c(pids)
    Signal.trap 'SIGINT' do
      STDERR.puts "Parallel execution interrupted, exiting ..."
      pids.each { |pid| Process.kill("KILL", pid) }
      exit 1
    end
  end
end