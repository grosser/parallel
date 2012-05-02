require 'soft_deletion'

require 'active_support/test_case'
require 'shoulda'
require 'redgreen'

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
end

# setup models
class Forum < ActiveRecord::Base
  include SoftDeletion
  belongs_to :category
end

class Category < ActiveRecord::Base
  include SoftDeletion
  has_many :forums, :dependent => :destroy
end

class NoAssociationCategory < ActiveRecord::Base
  include SoftDeletion
  set_table_name 'categories'
end

# Independent association
class IDACategory < ActiveRecord::Base
  include SoftDeletion
  set_table_name 'categories'
  has_many :forums, :dependent => :destroy, :foreign_key => :category_id
end

# Nullified dependent association
class NDACategory < ActiveRecord::Base
  include SoftDeletion
  set_table_name 'categories'
  has_many :forums, :dependent => :destroy, :foreign_key => :category_id
end

class SoftDeletionTest < ActiveSupport::TestCase
  def assert_deleted(resource)
    resource.class.with_deleted do
      resource.reload
      assert resource.deleted?
    end
  end

  def assert_not_deleted(resource)
    resource.reload
    assert !resource.deleted?
  end

  setup do
    # clear callbacks
    Category.class_eval{ @after_soft_delete_callbacks = nil }
  end

  context ".after_soft_delete" do
    should "be called after soft-deletion" do
      Category.after_soft_delete :foo
      category = Category.create!
      category.expects(:foo)
      category.soft_delete!
    end

    should "not be called after normal destroy" do
      # TODO clear all callbacks
      Category.after_soft_delete :foo
      category = Category.create!
      category.expects(:foo).never
      category.destroy
    end
  end

  context 'without dependent associations' do
    should 'only soft-delete itself' do
      category = NoAssociationCategory.create!
      category.soft_delete!
      assert_deleted category
    end
  end

  context 'with independent associations' do
    should 'not delete associations' do
      category = IDACategory.create!
      forum = category.forums.create!
      category.soft_delete!
      assert_deleted forum
    end
  end

  context 'with dependent associations' do
    setup do
      @category = Category.create!
      @forum = @category.forums.create!
    end

    context 'failing to soft delete' do
      setup do
        @category.stubs(:valid?).returns(false)
        assert_raise(ActiveRecord::RecordInvalid) { @category.soft_delete! }
      end

      should 'not mark itself as deleted' do
        assert_not_deleted @category
      end

      should 'not soft delete its dependent associations' do
        assert_not_deleted @forum
      end
    end

    context 'successfully soft deleted' do
      setup do
        @category.soft_delete!
      end

      should 'mark itself as deleted' do
        assert_deleted @category
      end

      should 'soft delete its dependent associations' do
        assert_deleted @forum
      end
    end

    context 'being restored from soft deletion' do
      setup do
        @category.soft_delete!
        Category.with_deleted do
          @category.reload
          @category.soft_undelete!
          @category.reload
        end
      end

      should 'not mark itself as deleted' do
        assert_not_deleted @category
      end

      should 'restore its dependent associations' do
        assert_not_deleted @forum
      end
    end
  end

  context 'a soft-deleted has-many category that nullifies forum references on delete' do
    should 'nullify those references' do
      category = NDACategory.create!
      forum = category.forums.create!
      category.soft_delete!
      assert_deleted forum
      #assert_nil forum.category_id # TODO
    end
  end
end
