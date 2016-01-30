require 'thread'
# ==============================================================================
# Author: Ralf Mueller, ralf.mueller@mpimet.mpg.de
#         suggestions from Robert Klemme (https://www.ruby-forum.com/topic/68001#86298)
#
# ==============================================================================

class ParallelQueue < Queue
  alias :queue_push :push
  include Parallel::ProcessorCount

  def push (*item, &block)
    queue_push(item   ) unless item.empty?
    queue_push([block]) unless block.nil?
  end
  def run(workers=processor_count)
    queue_push(Parallel::Stop)
    Parallel.map(self,:in_threads => workers) {|task|
      if task.size > 1
        if task[0].kind_of? Proc
          # Expects proc/lambda with arguments,e.g.
          # [mysqrt,2.789]
          # [myproc,x,y,z]
          task[0].call(*task[1..-1])
        else
          # expect an object in task[0] and one of its methods with arguments in task[1] as a symbol
          # e.g. [a,[:attribute=,1] or
          # Math,:exp,0
          task[0].send(task[1],*task[2..-1])
        end
      else
        task[0].call
      end
    }
  end
end
