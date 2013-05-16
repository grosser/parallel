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

Try either of those to get working parallel AR

```Ruby
Parallel.each(User.all, :in_threads => 8) do |user|
  ActiveRecord::Base.connection_pool.with_connection do
    user.update_attribute(:some_attribute, some_value)
  end
end

Parallel.each(User.all, :in_processes => 8) do |user|
  ActiveRecord::Base.connection.reconnect!
  user.update_attribute(:some_attribute, some_value)
end
```

### Break

```Ruby
Parallel.map(User.all) do |user|
  raise Parallel::Break # -> stop all execution
end
```

### Progress / ETA

```Bash
gem install ruby-progressbar
```

```Ruby
require 'ruby-progressbar'
progress = ProgressBar.create(:title => "The Progress", :total => 100)
Parallel.map(1..100, :finish => lambda { |item, i| progress.increment }) { sleep 1 }
```

Tips
====
 - [Benchmark/Test] Disable threading/forking with `:in_threads => 0` or `:in_processes => 0`, great to test performance or to debug parallel issues

TODO
====
 - JRuby / Windows support <-> possible ?

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

[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://travis-ci.org/grosser/parallel.png)](https://travis-ci.org/grosser/parallel)
