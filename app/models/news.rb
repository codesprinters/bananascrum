class News < ActiveRecord::Base
  validates_presence_of :expiration_date, :text

  has_many :plan_news
  has_many :plans, :through => :plan_news
  
  before_validation_on_create :set_expiration_date
  
  def self.latest_for_plan(plan)
    plan.news.find(:first, :order => "created_at DESC", :conditions => ["expiration_date > ?", Time.now.to_s(:db)])
  end
  
  protected
  
  def set_expiration_date
    return if self.expiration_date
    self.expiration_date = Time.now + 14.day
  end
end
