class Plan < ActiveRecord::Base
  NO_LIMIT_PLAN_NAME = "No limits"
  VAT_RATE = 0.22

  default_scope :order => 'price'

  named_scope :enabled, lambda {
    today = DateTime.now
    {:conditions => ["valid_from <= :today AND (valid_to IS NULL or valid_to >= :today)", {:today => today}]}
  }

  named_scope :public, :conditions => ['public = ?', true]
  named_scope :free, :conditions => 'price IS NULL'

  has_many :domains
  has_many :customers, :through => :domains
  has_many :plan_news
  has_many :news, :through => :plan_news

  validates_presence_of :valid_from
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_numericality_of :users_limit, :projects_limit, :mbytes_limit,
    :allow_nil => true,
    :only_integer => true,
    :greater_than_or_equal_to => 0
  validates_numericality_of :price, :allow_nil => true, :greater_than => 0
    
  def bytes_limit
    return nil if mbytes_limit.nil?
    return 1.megabytes * mbytes_limit
  end

  # whether the plan is currently enabled
  def enabled?
    #FIXME handle wrong date format in the db and comparison exceptions
    return false if Date.today < self.valid_from
    return false if self.valid_to && Date.today > self.valid_to
    
    return true
  end

  def free?
    price.nil?
  end

  def paid?
    !free?
  end

  def price_with_vat
    self.price + tax_amount unless self.price.nil?
  end

  def price_in_cents
    price * 100.0 unless price.nil?
  end

  def tax_amount
    unless self.price.nil?
      return sprintf("%.2f", (self.price * VAT_RATE)).to_f
    end
  end

  def tax_amount_in_cents
    tax_amount * 100.0 unless self.price.nil?
  end

  def desc
    "%s (u:%d, p:%d, a:%d) %dEUR" % [name, users_limit, projects_limit, mbytes_limit, price]
  end

  def long_desc(customer = nil)
    price = (customer && customer.pays_with_vat?) ? self.price_with_vat : self.price
    "Banana Scrum subscription for #{self.name} plan (#{price} EUR)"
  end

  def self.first_free_plan
    self.enabled.public.free.first
  end

end
