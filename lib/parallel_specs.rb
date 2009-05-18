module ParallelSpecs
  extend self

  def with_copied_envs(root, num_processes)
    envs = []
    2.upto(num_processes){|i| envs << "#{root}/config/environments/test#{i}.rb"}
    envs.each{|f| `cp #{root}/config/environments/test.rb #{f}`}
    yield
    envs.each{|f| `rm #{f}`}
  end
end