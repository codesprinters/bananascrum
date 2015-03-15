require 'digest/sha1'

class UserActivation < ActiveRecord::Base
  
  include DomainChecks
  
  belongs_to :user
  validates_presence_of :user
  validates_uniqueness_of :key

  def before_create
    key = nil
    i = 0
    loop do
      key = Digest::SHA1.hexdigest("#{Time.current.to_f}#{self.user.login}#{i}")
      break unless UserActivation.find_by_key(key)
      i += 1
    end  
    self.key = key
  end
end
