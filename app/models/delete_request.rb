class DeleteRequest < ActiveRecord::Base
  VALID_DAYS_FOR_KEY = 2.freeze;
  include DomainChecks
  
  attr_accessible(:user, :domain)
  belongs_to :user
  validates_presence_of :user
  validates_uniqueness_of :key

  def before_create
    key = nil
    i = 0
    loop do
      key = Digest::SHA1.hexdigest("#{Time.current.to_f}#{self.user.login}#{i}")
      break unless DeleteRequest.find_by_key(key)
      i += 1
    end
    self.key = key
  end

end
