require 'active_record'
require 'soft_deletion/version'
require 'soft_deletion/dependency'

module SoftDeletion
  def self.included(base)
    unless base.ancestors.include?(ActiveRecord::Base)
      raise "You can only include this if #{base} extends ActiveRecord::Base"
    end
    base.extend(ClassMethods)

    # Avoids a bad SQL request with versions of code without the colun deleted_at (for example a migration prior to the migration
    # that adds deleted_at)
    if base.column_names.include?('deleted_at')
      base.send(:default_scope, :conditions => base.soft_delete_default_scope_conditions)
    end

    # backport after_soft_delete so we can safely upgrade to rails 3
    if ActiveRecord::VERSION::MAJOR > 2
      base.define_callbacks :soft_delete
      class << base
        def after_soft_delete(*callbacks)
          set_callback :soft_delete, :after, *callbacks
        end
      end
    else
      base.define_callbacks :after_soft_delete
    end
  end

  module ClassMethods
    def soft_delete_default_scope_conditions
      {:deleted_at => nil}
    end

    def soft_delete_dependents
      self.reflect_on_all_associations.
        select { |a| [:destroy, :delete_all, :nullify].include?(a.options[:dependent]) }.
        map(&:name)
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

  def mark_as_deleted
    self.deleted_at = Time.now
  end

  def mark_as_undeleted
    self.deleted_at = nil
  end

  def soft_delete!
    self.class.transaction do
      if ActiveRecord::VERSION::MAJOR > 2
        run_callbacks :soft_delete do
          _soft_delete!
        end
      else
        _soft_delete!
        run_callbacks :after_soft_delete
      end
    end
  end

  def soft_undelete!
    self.class.transaction do
      mark_as_undeleted
      soft_delete_dependencies.each(&:soft_undelete!)
      save!
    end
  end

  protected

  def _soft_delete!
    mark_as_deleted
    soft_delete_dependencies.each(&:soft_delete!)
    save!
  end

  def soft_delete_dependencies
    self.class.soft_delete_dependents.map { |dependent| Dependency.new(self, dependent) }
  end
end
