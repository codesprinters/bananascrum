module DomainChecks
  def self.included(base)
    base.belongs_to :domain
    base.validates_presence_of :domain
    
    base.before_validation :domain_checks_before_validation
    base.before_save :ensure_same_domain
    base.before_destroy :ensure_same_domain
    
    unless base.instance_methods.include?("after_find")
      base.class_eval do
        def after_find
          # empty method - defined so that aliast_method_chain would work
        end
      end
    end

    base.alias_method_chain(:after_find, :domain_checks)
  end

  # Sets the domain to current if not set to anything else
  # for new objects
  def domain_checks_before_validation
    if self.new_record? && self.domain.nil? then
      self.domain = Domain.current
    end
  end
  
  # after_find callbacks must be defined directly.
  # This overwrites other after_find methods,
  # when this becomes a problem use method chaining
  def after_find_with_domain_checks
    after_find_without_domain_checks
    ensure_same_domain
  end
  
  #
  # Ensures that loaded/saved/destroyed objects belong to the current domain.
  #
  def ensure_same_domain
    return if Thread.current[:domain_checks_suspended]

    if Domain.current.nil? then
      raise SecurityError.new("No current domain!")
    end

    unless (Domain.current.new_record? && Domain.current == self.domain) || (Domain.current.id == self.domain_id)
      message = "Cross-domain access requested."
      
      if RAILS_ENV == 'development' or RAILS_ENV == 'test' then
        message << " Class: #{self.class.to_s}, id: #{self.id}, domain_id: #{self.domain_id}, current domain_id: #{Domain.current.id}"
      end
      
      raise SecurityError.new(message)
    end
  end
  
  def self.disable
    previous = Thread.current[:domain_checks_suspended]
    begin
      Thread.current[:domain_checks_suspended] = true
      return yield
    ensure
      Thread.current[:domain_checks_suspended] = previous
    end
  end

end
