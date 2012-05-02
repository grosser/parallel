require 'soft_deletion/version'
require 'soft_deletion/dependency'

module SoftDeletion
  # Examples:
  # Restoring a deleted forum and its entries:
  #
  # Forum.with_deleted do
  #   forum = Forum.find 1
  #   forum.soft_undelete!
  # end
  #
  def self.included(base)
    unless base.ancestors.include?(ActiveRecord::Base)
      raise "You can only include this if #{base} extends ActiveRecord::Base"
    end
    base.extend(ClassMethods)
    base.send(:default_scope, :conditions => base.soft_delete_default_scope_conditions)
    base.define_callbacks :after_soft_delete
  end

  module ClassMethods
    def soft_delete_default_scope_conditions
      {:deleted_at => nil}
    end

    def soft_delete_dependents
      self.reflect_on_all_associations.
        select { |a| [:destroy, :delete_all, :nullify].include?(a.options[:dependent]) }.
        map(&:name) || []
    end

    def with_deleted
      with_exclusive_scope do
        yield self
      end
    end
  end

  def deleted?
    deleted_at.present?
  end

  def mark_as_deleted!
    self.deleted_at = Time.now
  end

  def mark_as_undeleted!
    self.deleted_at = nil
  end

  def soft_delete!
    self.class.transaction do
      mark_as_deleted!
      soft_delete_dependencies.each(&:soft_delete!)
      save!
      run_callbacks(:after_soft_delete)
    end
  end

  def soft_undelete!
    self.class.transaction do
      mark_as_undeleted!
      soft_delete_dependencies.each(&:soft_undelete!)
      save!
    end
  end

  protected

  def soft_delete_dependencies
    self.class.soft_delete_dependents.map { |dependent| Dependency.new(self, dependent) }
  end
end
