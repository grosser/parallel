Rake tasks to run specs in parallel, to use multiple CPUs and speedup test runtime.

Setup
=====

    script/plugin install git://github.com/joakimk/parallel_specs.git (this version)
    script/plugin install git://github.com/grosser/parallel_specs.git (the original)

<<<<<<< HEAD:README.markdown
Add <%= ENV['INSTANCE'] %> to the database name for the test environment in `config/database.yml`:

    test:
      adapter: mysql
      database: xxx_test<%= ENV['INSTANCE'] %>
=======
Add <%= ENV['TEST_ENV_NUMBER'] %> to the database name for the test environment in `config/database.yml`,  
it is '' for process 1, and '2' for process 2.

    test:
      adapter: mysql
      database: xxx_test<%= ENV['TEST_ENV_NUMBER'] %>
>>>>>>> ee32430dcd947dab05f79890382d838bd11a9592:README.markdown
      username: root

For each environment, create the databases
    mysql -u root -> create database xxx_test2;

Run like hell :D  

<<<<<<< HEAD:README.markdown
    rake spec:parallel:prepare[2] #db:reset for each test database
=======
    (Make sure your `spec/spec_helper.rb` does not set `ENV['RAILS_ENV']` to 'test')

    rake spec:parallel:prepare[2] #db:reset for each database
>>>>>>> ee32430dcd947dab05f79890382d838bd11a9592:README.markdown

    rake spec:parallel[1] --> 86 seconds
    rake spec:parallel    --> 47 seconds (default = 2)
    rake spec:parallel[4] --> 26 seconds
    ...

Example output
--------------

<<<<<<< HEAD:README.markdown
    Running specs in 2 processes
    93 specs per process
=======
    2 processes: 178 specs in  (89 specs per process)
    Starting process 1
    Starting process 2
>>>>>>> ee32430dcd947dab05f79890382d838bd11a9592:README.markdown
    ... test output ...
    Took 47.319378 seconds


TODO
====
 - find out how many CPUs the user has [here](http://stackoverflow.com/questions/891537/ruby-detect-number-of-cpus-installed)
 - sync the output, so that results do not appear all at once
 - grab the 'xxx examples ..' line and display them at the bottom
<<<<<<< HEAD:README.markdown

Authors
======
inspired by [pivotal labs](http://pivotallabs.com/users/miked/blog/articles/849-parallelize-your-rspec-suite)  
=======


Authors
=======
inspired by [pivotal labs](http://pivotallabs.com/users/miked/blog/articles/849-parallelize-your-rspec-suite)

###Contributors
 - [Joakim Kolsjö](http://www.rubyblocks.se) -- joakim.kolsjo<$at$>gmail.com

>>>>>>> ee32430dcd947dab05f79890382d838bd11a9592:README.markdown
[Michael Grosser](http://pragmatig.wordpress.com)  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...

Additional code by:
[Joakim Kolsjö](http://www.rubyblocks.se)
joakim.kolsjo<$at$>gmail.com
