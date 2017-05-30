require 'minitest/autorun'
$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'parallel'
require 'parallel/queue'

class TestParallelQueue < Minitest::Test

  def test_blocks
    q = ParallelQueue.new

    itemsA = %w[a:3:b x:55:x K:981:foo:tra]
    itemsB = %w[a|5|b x|11|x K|187|foo|tra]

    itemsA.each {|item|
      q.push {
        item.split(':')[1].to_i
      }
    }
    itemsB.each {|item|
      q.push {
        item.split('|')[1].to_i
      }
    }
    results = q.run.sort
    assert_equal([3,5,11,55,187,981],results)
  end

  def test_procs
    q = ParallelQueue.new

    myProc       = lambda {|r| Math.sqrt(r)}
    pressure     = lambda {|z|
      1013.25*Math.exp((-1)*(1.602769777072154)*Math.log((Math.exp(z/10000.0)*213.15+75.0)/288.15))
    }
    temperature  = lambda {|z|
      213.0+75.0*Math.exp((-1)*z/10000.0)-273.15
    }
    vectorLength = lambda {|x,y,z| Math.sqrt(x*x + y*y + z*z) }

    q.push(myProc,4.0)
    q.push(Math,:sqrt,16.0)
    [0,10,20,50,100,200,500,1000].map(&:to_f).each {|z|
      q.push(pressure,z)
      q.push(temperature,z)
    }
    q.push(Math,:sqrt,529.0)
    q.push(vectorLength,0,1,0)
    q.push(vectorLength,0,1,1)
    q.push(vectorLength,1,1,1)

    results = q.run(2).map {|f| f.round(2)}
    assert_equal(
      [1.0,1.41,1.73,2.0, 4.0, 7.71, 11.19, 13.36, 14.1, 14.48, 14.7, 14.78, 14.85, 23.0, 898.6, 954.56, 989.45, 1001.29, 1007.26, 1010.85, 1012.05, 1013.25],
      results.sort
    )
  end
end
