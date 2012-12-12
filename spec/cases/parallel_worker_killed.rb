require File.expand_path('spec/spec_helper')
require 'singleton'

class WorkerPool
  include Singleton
  attr_accessor :worker_pool
  def initialize
    @worker_pool = []
  end
end

module Parallel
  def self.create_workers(items, options, &block)
    workers = []
    Array.new(options[:count]).each do
      workers << worker(items, options.merge(:started_workers => workers), &block)
    end

    pids = workers.map{|worker| worker[:pid] }
    kill_on_ctrl_c(pids)
    WorkerPool.instance.worker_pool << workers
    workers
  end
end

Parallel.each_with_index([1,2], :in_processes => 3) do |argument, index|
  Process.kill("SIGKILL", Process.pid)
end
puts "heh"
