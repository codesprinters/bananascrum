class StatRun < ActiveRecord::Base
  has_many :stat_data
  validates_presence_of :timestamp
end
