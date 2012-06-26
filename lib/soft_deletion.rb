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

    def soft_delete_all!(ids_or_models)
      ids_or_models = Array.wrap(ids_or_models)

      if ids_or_models.first.respond_to?(:id)
        ids = ids_or_models.map(&:id)
        models = ids_or_models
      else
        ids = ids_or_models
        models = all(:conditions => { :id => ids })
      end

      transaction do
        update_all(["deleted_at = ?", Time.now], :id => ids)

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

  def soft_delete_dependencies
    self.class.soft_delete_dependents.map { |dependent| Dependency.new(self, dependent) }
  end

  protected

  def _soft_delete!
    mark_as_deleted
    soft_delete_dependencies.each(&:soft_delete!)
    save!
  end
end
