Run any kind of code in parallel Processes or Threads, to speedup computation by factor #{your_cpus} X.

 - child processes are killed when your main process is killed through Ctrl+c or kill -2

Install
=======
    sudo gem install grosser-parallel -s http://gems.github.com/

Usage
=====
### Processes
 - Speedup through multiple cpus
 - Speedup for blocking operations
 - Protects global data
 - Extra memory used

### Threads
 - Speedup for blocking operations
 - Global data can be modified
 - No extra memory used

Map-Reduce-Style
    # 2 Cpus -> finished after 2 runs (a,b + c)
    results = Parallel.map(['a','b','c']) do |one_letter|
      expensive_calculation(letter)
    end

    # 3 Processes -> finished after 1 run
    results = Parallel.map(['a','b','c'], :in_processes=>3){|one_letter| ... }

    # 3 Threads -> finished after 1 run
    results = Parallel.map(['a','b','c'], :in_threads=>3){|one_letter| ... }


Normal
    #i -> 0...number_of_your_cpus
    results = Parallel.in_processes do |i|
      expensive_computation(data[i])
    end

    #i -> 0...4
    results = Parallel.in_processes(4) do |i|
      expensive_computation(data[i])
    end

    # Threads
    results = Parallel.in_threads(4) do |i|
      blocking_computation(data[i])
    end

TODO
====
 - optimize Parallel.map by not waiting for a group to finish: start new when one process finishes

Author
======
[Michael Grosser](http://pragmatig.wordpress.com)  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...