This is a very simple approach to parallel testing inspired by [pivotal labs](http://pivotallabs.com/users/miked/blog/articles/849-parallelize-your-rspec-suite)
not as capeable as [deep-test](http://github.com/qxjit/deep-test/tree/master) but hey: it is *easy to set up and works*!

Setup
=====

    script/plugin install git://github.com/grosser/parallel_specs.git

1.Copy your test environment inside `config/database.yml` once for every cpu you got ('test'+number).

    test:
      adapter: mysql
      database: xxx_test
      username: root

    test2:
      adapter: mysql
      database: xxx_test2
      username: root

2.For each environment, create the databases and fill it with structure

    mysql -u root -> create database xxx_test2;
    rake db:reset RAILS_ENV=test2

3.Run like hell :D

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
 - find a less hack approach (without manual creating so many envs)
 - Rails 2.3: 1/1000 tests randomly fails because of `Mysql::Error: SAVEPOINT active_record_1 does not exist: ROLLBACK TO SAVEPOINT active_record_1`


Author
======
[Michael Grosser](http://pragmatig.wordpress.com)  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...