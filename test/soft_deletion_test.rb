require File.expand_path '../test_helper', __FILE__

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

  def self.successfully_soft_deletes
    context "successfully soft deleted" do
      setup do
        @category.soft_delete!
      end

      should "mark itself as deleted" do
        assert_deleted @category
      end

      should "soft delete its dependent associations" do
        assert_deleted @forum
      end
    end
  end

  def self.successfully_bulk_soft_deletes
    context "successfully bulk soft deleted" do
      setup do
        Category.soft_delete_all!(@category)
      end

      should "mark itself as deleted" do
        assert_deleted @category
      end

      should "soft delete its dependent associations" do
        assert_deleted @forum
      end
    end
  end

  setup do
    clear_callbacks Category, :soft_delete
  end

  context ".before_soft_delete" do
    should "be called on soft-deletion" do
      Category.before_soft_delete :foo
      category = Category.create!
      category.expects(:foo)
      category.soft_delete!
    end
  end

  context ".after_soft_delete" do
    should "be called after soft-deletion" do
      Category.after_soft_delete :foo
      category = Category.create!
      category.expects(:foo)
      category.soft_delete!
    end

    should "be called after bulk soft-deletion" do
      Category.after_soft_delete :foo
      category = Category.create!
      category.expects(:foo)
      Category.soft_delete_all!(category)
    end

    should "be call multiple after soft-deletion" do
      Category.after_soft_delete :foo, :bar
      category = Category.create!
      category.expects(:foo)
      category.expects(:bar)
      category.soft_delete!
    end

    should "not be called after normal destroy" do
      Category.after_soft_delete :foo
      category = Category.create!
      category.expects(:foo).never
      category.destroy
    end
  end

  context "without dependent associations" do
    should "only soft-delete itself" do
      category = NACategory.create!
      category.soft_delete!
      assert_deleted category
    end
  end

  context "with independent associations" do
    should "not delete associations" do
      category = IDACategory.create!
      forum = category.forums.create!
      category.soft_delete!
      assert_deleted forum
    end
  end

  context "with dependent has_one association" do
    setup do
      @category = HOACategory.create!
      @forum = @category.create_forum
    end

    successfully_soft_deletes
    successfully_bulk_soft_deletes
  end

  context "with dependent association that doesn't have soft deletion" do
    setup do
      @category = DACategory.create!
      @forum = @category.destroyable_forums.create!
    end

    context "successfully soft deleted" do
      setup do
        @category.soft_delete!
      end

      should "mark itself as deleted" do
        assert_deleted @category
      end

      should "not destroy dependent association" do
        assert DestroyableForum.exists?(@forum.id)
      end
    end
  end

  context "with dependent has_many associations" do
    setup do
      @category = Category.create!
      @forum = @category.forums.create!
    end

    context "failing to soft delete" do
      setup do
        @category.stubs(:valid?).returns(false)
        assert_raise(ActiveRecord::RecordInvalid) { @category.soft_delete! }
      end

      should "not mark itself as deleted" do
        assert_not_deleted @category
      end

      should "not soft delete its dependent associations" do
        assert_not_deleted @forum
      end
    end

    successfully_soft_deletes
    successfully_bulk_soft_deletes

    context "being restored from soft deletion" do
      setup do
        @category.soft_delete!
        Category.with_deleted do
          @category.reload
          @category.soft_undelete!
          @category.reload
        end
      end

      should "not mark itself as deleted" do
        assert_not_deleted @category
      end

      should "restore its dependent associations" do
        assert_not_deleted @forum
      end
    end
  end

  context "a soft-deleted has-many category that nullifies forum references on delete" do
    should "nullify those references" do
      category = NDACategory.create!
      forum = category.forums.create!
      category.soft_delete!
      assert_deleted forum
      #assert_nil forum.category_id # TODO
    end
  end

  context "without deleted_at column" do
    should "default scope should not provoke an error" do
      assert_nothing_raised do
        OriginalCategory.create!
      end
    end
  end

  context ".soft_delete_all!" do
    setup do
      @categories = 2.times.map { Category.create! }
    end

    context "by id" do
      setup do
        Category.soft_delete_all!(@categories.map(&:id))
      end

      should "delete all models" do
        @categories.each do |category|
          assert_deleted category
        end
      end
    end

    context "by model" do
      setup do
        Category.soft_delete_all!(@categories)
      end

      should "delete all models" do
        @categories.each do |category|
          assert_deleted category
        end
      end
    end
  end

  context "overwritten default scope" do
    should "find even with deleted_at" do
      forum = Cat1Forum.create(:deleted_at => Time.now)
      assert Cat1Forum.find_by_id(forum.id)
    end

    should "not find by new scope" do
      # create! does not work here on rails 2
      forum = Cat1Forum.new
      forum.category_id = 2
      forum.save!
      assert_nil Cat1Forum.find_by_id(forum.id)
    end
  end

  context "validations" do
    should "fail when validations fail" do
      forum = ValidatedForum.create!(:category_id => 1)
      forum.category_id = nil
      assert_raise ActiveRecord::RecordInvalid do
        forum.soft_delete!
      end
      assert_not_deleted forum
    end

    should "pass when validations pass" do
      forum = ValidatedForum.create!(:category_id => 1)
      forum.soft_delete!
      assert_deleted forum
    end
  end

  context "#soft_delete" do
    should "return true if it succeeds" do
      forum = ValidatedForum.create!(:category_id => 1)
      assert_equal true, forum.soft_delete
      assert_deleted forum
    end

    should "return false if validations fail" do
      forum = ValidatedForum.create!(:category_id => 1)
      forum.category_id = nil
      assert_equal false, forum.soft_delete
      assert_not_deleted forum
    end

    should "return true if validations are prevented and it succeeds" do
      forum = ValidatedForum.create!(:category_id => 1)
      forum.category_id = nil
      skip_validations = (ActiveRecord::VERSION::MAJOR == 2 ? false : {:validate => false})
      assert_equal true, forum.soft_delete(skip_validations)
      assert_deleted forum
    end
  end
end
