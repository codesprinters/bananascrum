class EurRate < ActiveRecord::Base
  validates_presence_of :rate, :publish_date
end