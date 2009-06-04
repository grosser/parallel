Rake tasks to run specs in parallel, to use multiple CPUs and speedup test runtime.

Setup
=====

    script/plugin install git://github.com/grosser/parallel_specs.git

Add <%= ENV['TEST_ENV_NUMBER'] %> to the database name for the test environment in `config/database.yml`,  
it is '' for process 1, and '2' for process 2.

    test:
      adapter: mysql
      database: xxx_test<%= ENV['TEST_ENV_NUMBER'] %>
      username: root

For each environment, create the databases
    mysql -u root -> create database xxx_test2;

Run like hell :D  

    rake spec:parallel:prepare[2] #db:reset for each database

    rake spec:parallel[1] --> 86 seconds
    rake spec:parallel    --> 47 seconds (default = 2)
    rake spec:parallel[4] --> 26 seconds
    ...

Example output
--------------

    2 processes: 178 specs in  (89 specs per process)
    Starting process 1
    Starting process 2
    ... test output ...
    Took 47.319378 seconds


TIPS
====
 - `./script/generate rspec` if you are running rspec from gems (this plugin uses script/spec which may fail if rspec files are outdated)
 - with zsh this would be `rake "spec:parallel:prepare[3]"`


TODO
====
 - sync the output, so that results do not appear all at once (using sh and system did not work so far, since they could not be interrupted once started(Ctrl+C handler))
 - find out how many CPUs the user has [here](http://stackoverflow.com/questions/891537/ruby-detect-number-of-cpus-installed)
 - grab the 'xxx examples ..' line and display them at the bottom


Authors
=======
inspired by [pivotal labs](http://pivotallabs.com/users/miked/blog/articles/849-parallelize-your-rspec-suite)

###Contributors
 - [Joakim Kolsjö](http://www.rubyblocks.se) -- joakim.kolsjo<$at$>gmail.com

[Michael Grosser](http://pragmatig.wordpress.com)  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...