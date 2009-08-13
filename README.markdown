Run any kind of code in parallel Processes or Threads, to speedup computation by factor #{your_cpus} X.

 - child processes are killed when your main process is killed through Ctrl+c or kill -2

Install
=======
    sudo gem install grosser-parallel -s http://gems.github.com/

Usage
=====

    #i -> 0..number_of_your_cpus
    results = Parallel.in_processes do |i|
      expensive_computation(data[i])
    end

    #i -> 0..4
    results = Parallel.in_processes(4) do |i|
      expensive_computation(data[i])
    end

    #same with threads (no speedup through multiple cpus, but speedup for blocking operations)
    results = Parallel.in_threads(4) do |i|
      blocking_computation(data[i])
    end

Author
======
[Michael Grosser](http://pragmatig.wordpress.com)  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...