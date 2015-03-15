module ActsAsLogged

  def self.included(base)
    base.has_many :logs
    
    base.after_create :log_creation
    base.after_update :log_update
    base.before_destroy :log_destruction
    
    base.extend ClassMethods
    base.send :include, InstanceMethods

    base.class_inheritable_reader :logged_fields
    base.write_inheritable_attribute :logged_fields, []

    base.class_inheritable_reader :extra_logged_fields
    base.write_inheritable_attribute :extra_logged_fields, []

    base.class_inheritable_reader :logging_enabled
    base.write_inheritable_attribute :logging_enabled, true

    %w{sprint item task}.each do |relation_name|
      klass = relation_name.classify.constantize
      base.instance_eval do
        define_method(:"#{relation_name}_for_log") do
          return self if self.is_a?(klass)
          return self.instance_eval("self.#{relation_name}") rescue nil
        end
      end
    end
  end

  # thanks to this you can write
  # log_changes_of "this", "that", "anything"
  # in your class, and those will be logged on update
  module ClassMethods
    def log_changes_of(*args)
      options = args.extract_options!
      write_inheritable_attribute :logged_fields, args
      write_inheritable_attribute :extra_logged_fields, options[:extra_logged_fields] if options.has_key?(:extra_logged_fields)
    end

    # Executes the block with logging disabled.
    #
    #   Foo.without_logging do
    #     @foo.save
    #   end
    #
    def without_logging(&block)
      logging_was_enabled = logging_enabled
      disable_logging
      returning(block.call) { enable_logging if logging_was_enabled }
    end

    def disable_logging
      write_inheritable_attribute :logging_enabled, false
    end

    def enable_logging
      write_inheritable_attribute :logging_enabled, true
    end
  end

  module InstanceMethods

    def log_creation
      write_log(:create, loggable_chages_for(:create))
    end

    def log_destruction
      write_log(:delete, loggable_chages_for(:delete))
    end

    def log_update
      write_log(:update, loggable_changes)
    end

    protected

    def loggable_changes
      self.changes.reject { |field, value| !logged_fields.include?(field) }
    end

    # ActiveRecord::Dirty dosn't provide logig for retrieve fields values after create or after destroy
    def loggable_chages_for(action)
      result = {}

      build_changes = lambda do |value|
        changes = [value, nil]
        changes.reverse! if action == :create
        return changes
      end

      logged_fields.each do |field|
        old_value = attributes[field]
        result[field] = build_changes.call(old_value) if logged_fields.include?(field)
      end

      extra_logged_fields.each do |method|
        value = self.send(method.to_sym)
        result[method] = build_changes.call(value) if value
      end

      return result
    end

    def write_log(action, attributes_to_write, &block)
      return if not logging_enabled
      
      log = Log.new(:action => action.to_s,
        :logable_type => self.class.to_s,

        :domain => Domain.current,
        :user => User.current,

        :sprint => self.sprint_for_log,
        :task => self.task_for_log,
        :item => self.item_for_log)

      attributes_to_write.each do |field, changes|
        old_value, new_value = *changes

        log.fields << LogField.new(:domain => Domain.current,
          :name => field,
          :old_value => old_value,
          :new_value => new_value)
      end
      unless log.fields.blank?
        log.save!
        return log
      else
        return
      end
    end

  end

end
