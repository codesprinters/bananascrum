class LogField < ActiveRecord::Base
  include DomainChecks
  
  belongs_to :domain
  belongs_to :log
end
