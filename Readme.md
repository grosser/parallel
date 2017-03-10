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
results = Parallel.map(['a','b','c'], in_processes: 3) { |one_letter| ... }

# 3 Threads -> finished after 1 run
results = Parallel.map(['a','b','c'], in_threads: 3) { |one_letter| ... }
```

Same can be done with `each`
```Ruby
Parallel.each(['a','b','c']) { |one_letter| ... }
```
or `each_with_index` or `map_with_index`

Produce one item at a time with `lambda` (anything that responds to `.call`) or `Queue`.

```Ruby
items = [1,2,3]
Parallel.each( -> { items.pop || Parallel::Stop }) { |number| ... }
```

You can also call `any?` or `all?`, which work the same way as `Array#any?` and `Array#all?`.

```Ruby
items = [1,2,3,4,5,6,7]
Parallel.any?(items) { |number| number == 4 }
# => true

items = [1,2,nil,4,5]
Parallel.all?(items)
# => false
```


Processes/Threads are workers, they grab the next piece of work when they finish.

### Processes
 - Speedup through multiple CPUs
 - Speedup for blocking operations
 - Variables are protected from change
 - Extra memory used
 - Child processes are killed when your main process is killed through Ctrl+c or kill -2

### Threads
 - Speedup for blocking operations
 - Variables can be shared/modified
 - No extra memory used

### ActiveRecord

Try any of those to get working parallel AR

```Ruby
# reproducibly fixes things (spec/cases/map_with_ar.rb)
Parallel.each(User.all, in_processes: 8) do |user|
  user.update_attribute(:some_attribute, some_value)
end
User.connection.reconnect!

# maybe helps: explicitly use connection pool
Parallel.each(User.all, in_threads: 8) do |user|
  ActiveRecord::Base.connection_pool.with_connection do
    user.update_attribute(:some_attribute, some_value)
  end
end

# maybe helps: reconnect once inside every fork
Parallel.each(User.all, in_processes: 8) do |user|
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

```Ruby
Parallel.map([1,2,3]) do |x|
  raise Parallel::Kill if x == 1# -> stop all sub-processes, killing them instantly
  sleep 100 # Do stuff
end
```

### Progress / ETA

```Ruby
# gem install ruby-progressbar

Parallel.map(1..50, progress: "Doing stuff") { sleep 1 }

# Doing stuff | ETA: 00:00:02 | ====================               | Time: 00:00:10
```

Use `:finish` or `:start` hook to get progress information.
 - `:start` has item and index
 - `:finish` has item, index, result

They are called on the main process and protected with a mutex.

```Ruby
Parallel.map(1..100, finish: -> (item, i, result) { ... do something ... }) { sleep 1 }
```

### Worker number

Use `Parallel.worker_number` to determine the worker slot in which your
task is running.

```Ruby
Parallel.each(1..5, :in_processes => 2) { |i| puts "Item: #{i}, Worker: #{Parallel.worker_number}" }
Item: 1, Worker: 1
Item: 2, Worker: 0
Item: 3, Worker: 1
Item: 4, Worker: 0
Item: 5, Worker: 1
```

Tips
====

Here are a few notable options.

 - [Benchmark/Test] Disable threading/forking with `in_threads: 0` or `in_processes: 0`, great to test performance or to debug parallel issues
 - [Isolation] Do not reuse previous worker processes: `isolation: true`
 - [Stop all processses with an alternate interrupt signal] `'INT'` (from `ctrl+c`) is caught by default. Catch `'TERM'` (from `kill`) with `interrupt_signal: 'TERM'`

TODO
====
 - Replace Signal trapping with simple `rescue Interrupt` handler

Authors
=======

### [Contributors](https://github.com/grosser/parallel/graphs/contributors)
 - [Przemyslaw Wroblewski](https://github.com/lowang)
 - [TJ Holowaychuk](http://vision-media.ca/)
 - [Masatomo Nakano](https://twitter.com/masatomo2)
 - [Fred Wu](http://fredwu.me)
 - [mikezter](https://github.com/mikezter)
 - [Jeremy Durham](http://www.jeremydurham.com)
 - [Nick Gauthier](http://www.ngauthier.com)
 - [Andrew Bowerman](http://andrewbowerman.com)
 - [Byron Bowerman](http://blog.bm5k.com/)
 - [Mikko Kokkonen](https://github.com/mikian)
 - [brian p o'rourke](https://github.com/bpo)
 - [Norio Sato]
 - [Neal Stewart](https://github.com/n-time)
 - [Jurriaan Pruis](https://github.com/jurriaan)
 - [Rob Worley](https://github.com/robworley)
 - [Tasveer Singh](https://github.com/tazsingh)
 - [Joachim](https://github.com/jmozmoz)
 - [yaoguai](https://github.com/yaoguai)
 - [Bartosz Dziewoński](https://github.com/MatmaRex)
 - [yaoguai](https://github.com/yaoguai)
 - [Guillaume Hain](https://github.com/zedtux)
 - [Adam Wróbel](https://github.com/amw)
 - [Matthew Brennan](https://github.com/mattyb)
 - [Brendan Dougherty](https://github.com/brendar)
 - [Daniel Finnie](https://github.com/danfinnie)
 - [Philip M. White](https://github.com/philipmw)
 - [Arlan Jaska](https://github.com/ajaska)
 - [Sean Walbran](https://github.com/seanwalbran)

[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/parallel.png)](https://travis-ci.org/grosser/parallel)
