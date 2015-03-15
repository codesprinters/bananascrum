class IndexCardLog < ActiveRecord::Base
  belongs_to :domain
  validates_presence_of :collection_size, :contents
end
