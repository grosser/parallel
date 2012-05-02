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

class SoftDeletionTest < ActiveSupport::TestCase
  context ".after_soft_delete" do
    should "be called after soft-deletion" do
      Category.after_soft_delete :foo
      category = Category.create!
      category.expects(:foo)
      category.soft_delete!
    end

    should "not be called after deletion/destroy" do
      # TODO clear all callbacks
      Category.after_soft_delete :foo
      category = Category.create!
      category.does_not_expects(:foo)
      category.soft_delete!
    end
  end

  context 'A soft deletable record with dependent associations' do
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
        category = Category.find_by_id @category
        assert category
        assert_equal false, category.deleted?
      end

      should 'not soft delete its dependent associations' do
        forum = Forum.find_by_id(@forum)
        assert forum
        assert_equal false, forum.deleted?
      end

    end

    context 'successfully soft deleted' do
      setup do
        @category.soft_delete!
      end

      should 'mark itself as deleted' do
        Category.with_deleted do
          @category.reload
          assert_equal true, @category.deleted?
        end
      end

      should 'soft delete its dependent associations' do
        Forum.with_deleted do
          @forum.reload
          assert_equal true, @forum.deleted?
        end
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
        assert_equal false, @category.deleted?
      end

      should 'restore its dependent associations' do
        @forum.reload
        assert_equal false, @forum.deleted?
      end
    end
  end

  context 'a soft-deleted has-many category that nullifies forum references on delete' do
    setup do
      Category.has_many :nullify_forums, :class_name => Forum.name, :dependent => :nullify,
        :foreign_key => :category_id
      @category = Category.new
      @category.stubs(:save).returns(true)
      @forum = Forum.new
      @category.stubs(:nullify_forums).returns([@forum])
    end

    should 'nullify those references' do
      @category.expects(:save!).returns(true)
      @forum.expects(:update_attribute).with(:category_id, nil)
      @category.soft_delete!
    end
  end
end
