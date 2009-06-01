Rake tasks to run specs in parallel, to use multiple CPUs and speedup test runtime.

Setup
=====

    script/plugin install git://github.com/joakimk/parallel_specs.git (this version)
    script/plugin install git://github.com/grosser/parallel_specs.git (the original)

Add <%= ENV['INSTANCE'] %> to the database name for the test environment in `config/database.yml`:

    test:
      adapter: mysql
      database: xxx_test<%= ENV['INSTANCE'] %>
      username: root

For each environment, create the databases
    mysql -u root -> create database xxx_test2;

Run like hell :D  

    rake spec:parallel:prepare[2] #db:reset for each test database

    rake spec:parallel[1] --> 86 seconds
    rake spec:parallel    --> 47 seconds (default = 2)
    rake spec:parallel[4] --> 26 seconds
    ...

Example output
--------------

    Running specs in 2 processes
    93 specs per process
    ... test output ...
    Took 47.319378 seconds


TODO
====
 - find out how many CPUs the user has
 - sync the output, so that results do not appear all at once
 - grab the 'xxx examples ..' line and display them at the bottom

Authors
======
inspired by [pivotal labs](http://pivotallabs.com/users/miked/blog/articles/849-parallelize-your-rspec-suite)  
[Michael Grosser](http://pragmatig.wordpress.com)  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...

Additional code by:
[Joakim Kolsjö](http://www.rubyblocks.se)
joakim.kolsjo<$at$>gmail.com
