Run any code in parallel Processes(> use all CPUs) or Threads(> speedup blocking operations).  
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

###Contributors (alphabetical)
 - [TJ Holowaychuk](http://vision-media.ca/) -- tj<$at$>vision-media.ca

[Michael Grosser](http://pragmatig.wordpress.com)  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...