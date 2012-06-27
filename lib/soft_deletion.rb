require 'active_record'
require 'soft_deletion/version'
require 'soft_deletion/dependency'

module SoftDeletion
  def self.included(base)
    unless base.ancestors.include?(ActiveRecord::Base)
      raise "You can only include this if #{base} extends ActiveRecord::Base"
    end
    base.extend(ClassMethods)

    if base.respond_to?(:define_default_soft_delete_scope)
      base.define_default_soft_delete_scope
    else
      # Avoids a bad SQL request with versions of code without the column deleted_at (for example a migration prior to the migration
      # that adds deleted_at)
      if base.column_names.include?('deleted_at')
        base.send(:default_scope, :conditions => { :deleted_at => nil })
      end
    end

    # backport after_soft_delete so we can safely upgrade to rails 3
    if ActiveRecord::VERSION::MAJOR > 2
      base.define_callbacks :soft_delete
      class << base
        def before_soft_delete(*callbacks)
          set_callback :soft_delete, :before, *callbacks
        end

        def after_soft_delete(*callbacks)
          set_callback :soft_delete, :after, *callbacks
        end
      end
    else
      base.define_callbacks :before_soft_delete
      base.define_callbacks :after_soft_delete
    end
  end

  module ClassMethods
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

    def mark_as_soft_deleted_sql
      ["deleted_at = ?", Time.now]
    end

    def soft_delete_all!(ids_or_models)
      ids_or_models = Array.wrap(ids_or_models)

      if ids_or_models.first.is_a?(ActiveRecord::Base)
        ids = ids_or_models.map(&:id)
        models = ids_or_models
      else
        ids = ids_or_models
        models = all(:conditions => { :id => ids })
      end

      transaction do
        update_all(mark_as_soft_deleted_sql, :id => ids)
        models.each do |model|
          model.soft_delete_dependencies.each(&:soft_delete!)
          model.run_callbacks ActiveRecord::VERSION::MAJOR > 2 ? :soft_delete : :after_soft_delete
        end
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
    _run_soft_delete { save! }
  end

  def soft_delete(*args)
    _run_soft_delete do
      return false unless save(*args)
    end
  end

  def soft_undelete!
    self.class.transaction do
      mark_as_undeleted
      soft_delete_dependencies.each(&:soft_undelete!)
      save!
    end
  end

  def soft_delete_dependencies
    self.class.soft_delete_dependents.map { |dependent| Dependency.new(self, dependent) }
  end

  protected

  def _run_soft_delete(&block)
    self.class.transaction do
      if ActiveRecord::VERSION::MAJOR > 2
        run_callbacks :soft_delete do
          mark_as_deleted
          soft_delete_dependencies.each(&:soft_delete!)
          block.call
        end
      else
        run_callbacks :before_soft_delete
        mark_as_deleted
        soft_delete_dependencies.each(&:soft_delete!)
        block.call
        run_callbacks :after_soft_delete
      end
    end
  end
end
