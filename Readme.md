Explicit soft deletion for ActiveRecord via deleted_at and default scope.

Install
=======
    gem install soft_deletion
Or

    rails plugin install git://github.com/grosser/soft_deletion.git


Usage
=====
    # mix into any model ...
    class User < ActiveRecord::Base
      include SoftDeletion
      has_many :products
    end

    # soft delete them including all dependencies that are marked as :destroy, :delete_all, :nullify
    user = User.first
    user.products.count == 10
    user.soft_delete!
    user.deleted? # true

    # use special with_deleted scope to find them ...
    user.reload # ActiveRecord::RecordNotFound
    User.with_deleted do
      user.reload # there it is ...
      user.products.count == 0
    end

    # soft undelete them all
    user.soft_undelete!
    user.products.count == 10

TODO
====
 - Rails 3 from with inspiration from https://github.com/JackDanger/permanent_records/blob/master/lib/permanent_records.rb
 - maybe stuff from https://github.com/smoku/soft_delete


Author
======
[ZenDesk](http://zendesk.com)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://secure.travis-ci.org/grosser/soft_deletion.png)](http://travis-ci.org/grosser/soft_deletion)
