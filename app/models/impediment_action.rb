# Represents a possible change of state of impediment.
# ImpedimentLogs are instances of those changes.
class ImpedimentAction < ActiveRecord::Base
  validates_uniqueness_of :name
  
  DEFAULTS = [
    {:name => "created",   :open_after => true},
    {:name => "closed",    :open_after => false},
    {:name => "reopened",  :open_after => true},
    {:name => "commented", :open_after => nil}].freeze
    
  def self.create_defaults
    transaction do
      DEFAULTS.each do |default|
        next unless self.find_by_name(default[:name]).nil?
        self.create(default).save!
      end
    end
  end
  
  def validate_log(log)
    case name.to_sym
    when :closed
#       debugger
      log.errors.add("Can't close impediment that is not open") unless log.impediment.is_open?
    when :created
      if (!log.impediment.is_open.nil?) && log.new_record? then
        log.errors.add "Can't add 'created' log entry other than first entry"
      end
    when :reopened
      log.errors.add "Can't reopen impediment that is open" if log.impediment.is_open?
    when :commented
      log.errors.add :comment, "Can't be blank" if log.comment.blank?
    end
  end
end
