Run any code in parallel Processes(> use all CPUs) or Threads(> speedup blocking operations).<br/>
Best suited for map-reduce or e.g. parallel downloads/uploads.

Install
=======

```Bash
gem install parallel
```

Usage
=====

```Ruby
# 2 CPUs -> work in 2 processes (a,b + c)
results = Parallel.map(['a','b','c']) do |one_letter|
  expensive_calculation(one_letter)
end

# 3 Processes -> finished after 1 run
results = Parallel.map(['a','b','c'], :in_processes=>3){|one_letter| ... }

# 3 Threads -> finished after 1 run
results = Parallel.map(['a','b','c'], :in_threads=>3){|one_letter| ... }
```

Same can be done with `each`
```Ruby
Parallel.each(['a','b','c']){|one_letter| ... }
```
or `each_with_index` or `map_with_index`

Processes/Threads are workers, they grab the next piece of work when they finish.

### Processes
 - Speedup through multiple CPUs
 - Speedup for blocking operations
 - Protects global data
 - Extra memory used ( very low on [REE](http://www.rubyenterpriseedition.com/faq.html) through `copy_on_write_friendly` )
 - Child processes are killed when your main process is killed through Ctrl+c or kill -2

### Threads
 - Speedup for blocking operations
 - Global data can be modified
 - No extra memory used

### ActiveRecord

Try any of those to get working parallel AR

```Ruby
# reproducibly fixes things (spec/cases/map_with_ar.rb)
Parallel.each(User.all, :in_processes => 8) do |user|
  user.update_attribute(:some_attribute, some_value)
end
User.connection.reconnect!

# maybe helps: explicitly use connection pool
Parallel.each(User.all, :in_threads => 8) do |user|
  ActiveRecord::Base.connection_pool.with_connection do
    user.update_attribute(:some_attribute, some_value)
  end
end

# maybe helps: reconnect once inside every fork
Parallel.each(User.all, :in_processes => 8) do |user|
  @reconnected ||= User.connection.reconnect! || true
  user.update_attribute(:some_attribute, some_value)
end
```

### Break

```Ruby
Parallel.map(User.all) do |user|
  raise Parallel::Break # -> stops after all current items are finished
end
```

### Kill

Only use if whatever is executing in the sub-command is safe to kill at any point

```
Parallel.map([1,2,3]) do |x|
  raise Parallel::Kill if x == 1# -> stop all sub-processes, killing them instantly
  sleep 100
end
```

### Producing data as it is consumed

You can use [Queue](http://ruby-doc.org/stdlib-2.0.0/libdoc/thread/rdoc/Queue.html),
[SizedQueue](http://ruby-doc.org/stdlib-2.0.0/libdoc/thread/rdoc/SizedQueue.html)
or a lambda to produce data while it is consumed.

#### Lambda
Your lambda will be executed on the main process and protected with a mutex.
Return Parallel::EndOfIteration object to finish processing - your lambda will
not be called again.

```Ruby
i = 0
get_data = -> {
  return Parallel::EndOfIteration if i > 5
  i += 1
}
Parallel.map(get_data) {|item| ...}
```

#### Queue
Push Parallel::EndOfIteration on your queue to finish processing.

```Ruby
queue = Queue.new
Thread.new do
  20.times {|i| queue.push expensive_calculation(i)}
  queue.push Parallel::EndOfIteration
end
Parallel.map(queue) {|item| ...}
```

#### Queues vs Lambdas

Lambdas are easier to implement, but they are always executed on the main
thread. The same thread that runs :start and :finish callbacks and also bears
some general Parallel code overhead. Queues require a little more coding, but
they allow offloading your producer to a separate thread. Lambda is fully
isolated from code running in :start and :finish callbacks, i.e. your item
generating lambda, :start lambda and :finish lambda will run sequentially on the
main thread, isolated by a mutex and thus can share resources. Only the block
passed to `Parallel.each` or `Parallel.map` runs in parallel.

If you want to run your producer code in parallel using queues, but still need
to protect part of it's code from :start and :finish callbacks, create your own
mutex and pass it to Parallel as an option.

```Ruby
mutex = Mutex.new
queue = Queue.new
Thread.new do
  20.times {|i|
    item = expensive_calculation(i)
    mutex.synchronize do
      puts "Generated #{item}"
    end
    queue.push item
  }
  queue.push Parallel::EndOfIteration
end
start = lambda {|item,index|
  # the following puts does not compete with `puts` in the producer code
  puts "Processing #{item}"
}
Parallel.map(queue, :mutex => mutex, :start => start) {|item| ...}
```

### Consuming data from multiple processes without map

Using the results of `map` operation has some drawbacks. Collecting results of
a large iteration may require massive amounts of system memory. Additionally
your main thread cannot act on the results until all data is processed by
workers and returned in an array. You can work around these limitations by
using `:finish` callback. Parallel will execute it with the results of each
iteration when it is completed. Your callback will execute on the main process,
protected with a mutex.

```Ruby
processed = -> item, index, result {
  STDOUT.puts result
}
# work in processes
Parallel.each(1..10, :finish => processed) {|i| sleep 1; i * 2}
```

### Progress / ETA

```Ruby
# gem install ruby-progressbar

Parallel.map(1..50, :progress => "Doing stuff") { sleep 1 }

# Doing stuff | ETA: 00:00:02 | ====================               | Time: 00:00:10
```

Use `:finish` or `:start` hook to get progress information, `:start` has item
and index, `:finish` has item, index, result. These will be called on the main
process and protected with a mutex.

```Ruby
Parallel.map(1..100, :finish => lambda { |item, i, result| ... do something ... }) { sleep 1 }
```

Tips
====
 - [Benchmark/Test] Disable threading/forking with `:in_threads => 0` or `:in_processes => 0`, great to test performance or to debug parallel issues

TODO
====
 - Replace Signal trapping with simple `rescue Interrupt` handler

Authors
=======

### [Contributors](https://github.com/grosser/parallel/contributors)
 - [Przemyslaw Wroblewski](http://github.com/lowang)
 - [TJ Holowaychuk](http://vision-media.ca/)
 - [Masatomo Nakano](http://twitter.com/masatomo2)
 - [Fred Wu](http://fredwu.me)
 - [mikezter](http://github.com/mikezter)
 - [Jeremy Durham](http://www.jeremydurham.com)
 - [Nick Gauthier](http://www.ngauthier.com)
 - [Andrew Bowerman](http://andrewbowerman.com)
 - [Byron Bowerman](http://me.bm5k.com/)
 - [Mikko Kokkonen](https://github.com/mikian)
 - [brian p o'rourke](https://github.com/bpo)
 - [Norio Sato]
 - [Neal Stewart](https://github.com/n-time)
 - [Jurriaan Pruis](http://github.com/jurriaan)
 - [Rob Worley](http://github.com/robworley)
 - [Tasveer Singh](https://github.com/tazsingh)
 - [Joachim](https://github.com/jmozmoz)
 - [yaoguai](https://github.com/yaoguai)
 - [Bartosz Dziewoński](https://github.com/MatmaRex)
 - [yaoguai](https://github.com/yaoguai)
 - [Guillaume Hain](https://github.com/zedtux)

[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/parallel.png)](https://travis-ci.org/grosser/parallel)
