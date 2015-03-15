module PlanLimits

  def self.included(base)
    base.send(:extend, PlanLimitsClassMethods)
  end

  def exceedes_plan?(plan)
    exceedings = []
    for checker_class in PlanLimitsClassMethods.limit_checkers
      checker = checker_class.new(self, plan)
      unless checker.domain_within_plan?
        exceedings << checker.error_message
      end
    end
    
    return exceedings unless exceedings.empty?
  end

  private

  module PlanLimitsClassMethods
    mattr_reader :limit_checkers

    @@limit_checkers = Set.new

    def checks_plan_using(checker_class)
      plan_check = proc do |instance|
        checker = checker_class.new(instance.domain)
        unless checker.instance_within_plan?(instance)
          instance.errors.add_to_base(checker.error_message)
        end
      end
      validate(plan_check)
    end

    def check_domain_within_plan_using(checker_class)
      @@limit_checkers.add(checker_class)
      domain_validation = proc do |domain|
        checker = checker_class.new(domain)
        unless checker.domain_within_plan?
          domain.errors.add(:plan, checker.error_message)
        end
      end
      validate(domain_validation)
    end
  end
  
end
