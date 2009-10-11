Run any kind of code in parallel Processes or Threads, to speedup computation by factor #{your_cpus} X.

 - Child processes are killed when your main process is killed through Ctrl+c or kill -2
 - Processes/threads are workers, they grab the next piece of work when they finish

Install
=======
    sudo gem install parallel

Usage
=====
### Processes
 - Speedup through multiple CPUs
 - Speedup for blocking operations
 - Protects global data
 - Extra memory used

### Threads
 - Speedup for blocking operations
 - Global data can be modified
 - No extra memory used

    # 2 CPUs -> finished after 2 runs (a,b + c)
    results = Parallel.map(['a','b','c']) do |one_letter|
      expensive_calculation(letter)
    end

    # 3 Processes -> finished after 1 run
    results = Parallel.map(['a','b','c'], :in_processes=>3){|one_letter| ... }

    # 3 Threads -> finished after 1 run
    results = Parallel.map(['a','b','c'], :in_threads=>3){|one_letter| ... }

Same can be done with `each`
    Parallel.each(['a','b','c']){|one_letter| ... }

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