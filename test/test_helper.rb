require 'active_support/test_case'
require 'shoulda'
require 'active_record'

ENV['EMACS'] = 't' # colors for test-unit < 2.4.9

# connect
ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => ":memory:"
)

# create tables
ActiveRecord::Schema.define(:version => 1) do
  create_table :forums do |t|
    t.integer :category_id
    t.timestamp :deleted_at
  end

  create_table :categories do |t|
    t.timestamp :deleted_at
  end

  create_table :original_categories do |t|
  end
end

class ActiveRecord::Base
  def self.silent_set_table_name(name)
    if ActiveRecord::VERSION::MAJOR > 2
      self.table_name = name
    else
      set_table_name name
    end
  end
end

# setup models
require 'soft_deletion'

class Forum < ActiveRecord::Base
  include SoftDeletion
  belongs_to :category
end

class Category < ActiveRecord::Base
  include SoftDeletion
  has_many :forums, :dependent => :destroy
end

# No association
class NACategory < ActiveRecord::Base
  silent_set_table_name 'categories'
  include SoftDeletion
end

# Independent association
class IDACategory < ActiveRecord::Base
  silent_set_table_name 'categories'
  include SoftDeletion
  has_many :forums, :dependent => :destroy, :foreign_key => :category_id
end

# Nullified dependent association
class NDACategory < ActiveRecord::Base
  silent_set_table_name 'categories'
  include SoftDeletion
  has_many :forums, :dependent => :destroy, :foreign_key => :category_id
end

# Has ome association
class HOACategory < ActiveRecord::Base
  silent_set_table_name 'categories'
  include SoftDeletion
  has_one :forum, :dependent => :destroy, :foreign_key => :category_id
end

# Class without column deleted_at
class OriginalCategory < ActiveRecord::Base
  include SoftDeletion
end

# Has many destroyable association
class DACategory < ActiveRecord::Base
  silent_set_table_name 'categories'
  include SoftDeletion
  has_many :destroyable_forums, :dependent => :destroy, :foreign_key => :category_id
end

# Forum that isn't soft deletable for association checing
class DestroyableForum < ActiveRecord::Base
  silent_set_table_name 'forums'
end
