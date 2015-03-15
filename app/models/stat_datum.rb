class StatDatum < ActiveRecord::Base
  belongs_to :stat_run
  validates_presence_of :stat_run, :value, :kind

end