module SoftDeletion
  class Dependency
    attr_reader :record, :association_name

    def initialize(record, association_name)
      @record = record
      @association_name = association_name
    end

    def soft_delete!
      return unless can_soft_delete?

      if nullify?
        nullify_dependencies
      else
        dependencies.each(&:soft_delete!)
      end
    end

    def soft_undelete!
      return unless can_soft_delete?

      klass.with_deleted do
        dependencies.each(&:soft_undelete!)
      end
    end

    protected

    def nullify?
      association.options[:dependent] == :nullify
    end

    def nullify_dependencies
      dependencies.each do |dependency|
        dependency.update_attribute(association.primary_key_name, nil)
      end
    end

    def can_soft_delete?
      klass.method_defined? :soft_delete!
    end

    def klass
      association.klass
    end

    def association
      record.class.reflect_on_association(association_name.to_sym)
    end

    def dependencies
      Array.wrap(record.send(association_name))
    end
  end
end
