require 'forwardable'

class Presenter < ActiveRecord::BaseWithoutTable
  extend ::Forwardable
  
  def objects
    return []
  end
  
  def valid?
    objects.map(&:valid?).all?
  end
  
  def save
    if self.valid?
      ActiveRecord::Base.transaction do
        return objects.map(&:save).all?
      end
    else
      return false
    end
  end
  
  def save!
    objects.map(&:save!)
  end
  
  def errors
    @errors = ActiveRecord::Errors.new(self)
    objects.each do |obj|
      obj.errors.each do |attr, error|
        @errors.add(attr, error)
      end
    end
    return @errors
  end
  
  def initialize(params = {})
    params.each_pair do |attribute, value| 
      self.send :"#{attribute}=", value
    end unless params.nil?
  end
end