Rake tasks to run tests or specs in parallel, to use multiple CPUs and speedup test runtime.
[more documentation and great illustrations](http://giantrobots.thoughtbot.com/2009/7/24/make-your-test-suite-uncomfortably-fast)

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

    rake parallel:prepare[2] #db:reset for each database

    rake parallel:spec[1] --> 86 seconds
    #OR for Test::Unit
    rake parallel:test[1]

    rake parallel:spec    --> 47 seconds (default = 2)
    rake parallel:spec[4] --> 26 seconds
    ...

Example output
--------------
    2 processes for 210 specs, ~ 105 specs per process
    ... test output ...

    Results:
    877 examples, 0 failures, 11 pending
    843 examples, 0 failures, 1 pending

    Took 29.925333 seconds

TIPS
====
 - 'script/spec_server' or [spork](http://github.com/timcharper/spork/tree/master) do not work in parallel
 - `./script/generate rspec` if you are running rspec from gems (this plugin uses script/spec which may fail if rspec files are outdated)
 - with zsh this would be `rake "parallel:prepare[3]"`

TODO
====
 - find out how many CPUs the user has [here](http://stackoverflow.com/questions/891537/ruby-detect-number-of-cpus-installed)
 - build parallel:bootstrap [idea/basics](http://github.com/garnierjm/parallel_specs/commit/dd8005a2639923dc5adc6400551c4dd4de82bf9a)
 - make 'parallel:spec:models' work [idea/example](http://gist.github.com/157251)

Authors
====
inspired by [pivotal labs](http://pivotallabs.com/users/miked/blog/articles/849-parallelize-your-rspec-suite)  

###Contributors
 - [Joakim Kolsjö](http://www.rubyblocks.se) -- joakim.kolsjo<$at$>gmail.com
 - [Jason Morrison](http://jayunit.net) -- jason.p.morrison<$at$>gmail.com

[Michael Grosser](http://pragmatig.wordpress.com)  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...
