This is a very simple approach to parallel testing inspired by [pivotal labs](http://pivotallabs.com/users/miked/blog/articles/849-parallelize-your-rspec-suite)
not as capeable as [deep-test](http://github.com/qxjit/deep-test/tree/master) but hey: it is *easy to set up and works*!

Setup
=====

    script/plugin install git://github.com/grosser/parallel_specs.git

Copy your test environment inside `config/database.yml` once for every cpu you got ('test'+number).

    test:
      adapter: mysql
      database: xxx_test
      username: root

    test2:
      adapter: mysql
      database: xxx_test2
      username: root

For each environment, create the databases
    mysql -u root -> create database xxx_test2;

Run like hell :D  

    (Make sure your `spec/spec_helper.rb` does not set `ENV['RAILS_ENV']` to 'test')

    rake spec:parallel:prepare[2] #db:reset for each env

    rake spec:parallel[1] --> 86 seconds
    rake spec:parallel[2] --> 47 seconds
    rake spec:parallel[4] --> 26 seconds
    ...

Example output
--------------

    running specs in 2 processes
    93 specs per process
    starting process 1
    starting process 2
    ... test output ...
    Took 47.319378 seconds


TODO
====
 - sync the output, so that results do not appear all at once
 - grab the 'xxx examples ..' line and display them at the bottom
 - find a less hacky approach (without manual creation so many envs)


Author
======
[Michael Grosser](http://pragmatig.wordpress.com)  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...