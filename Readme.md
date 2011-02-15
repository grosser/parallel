Run any code in parallel Processes(> use all CPUs) or Threads(> speedup blocking operations).<br/>
Best suited for map-reduce or e.g. parallel downloads/uploads.

Install
=======
    sudo gem install parallel

Usage
=====
    # 2 CPUs -> work in 2 processes (a,b + c)
    results = Parallel.map(['a','b','c']) do |one_letter|
      expensive_calculation(letter)
    end

    # 3 Processes -> finished after 1 run
    results = Parallel.map(['a','b','c'], :in_processes=>3){|one_letter| ... }

    # 3 Threads -> finished after 1 run
    results = Parallel.map(['a','b','c'], :in_threads=>3){|one_letter| ... }

Same can be done with `each`
    Parallel.each(['a','b','c']){|one_letter| ... }
or `each_with_index` or `map_with_index`

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


Processes/Threads are workers, they grab the next piece of work when they finish

TODO
====
 - JRuby / Windows support <-> possible ?

Authors
=======

### [Contributors](http://github.com/grosser/parallel/contributors)
 - [Przemyslaw Wroblewski](http://github.com/lowang)
 - [TJ Holowaychuk](http://vision-media.ca/)
 - [Masatomo Nakano](http://twitter.com/masatomo2)
 - [Fred Wu](http://fredwu.me)
 - [mikezter](http://github.com/mikezter)
 - [Jeremy Durham](http://www.jeremydurham.com)
 - [Nick Gauthier](http://www.ngauthier.com)

[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
Hereby placed under public domain, do what you want, just do not hold me accountable...