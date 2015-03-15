class PaypalIpnLog < ActiveRecord::Base
  belongs_to :domain
  belongs_to :payment

  validates_presence_of :raw_post
end
