

# This is abstract graph! It doesn't represent anything
class ProjectChart < BurnChart
  class NotEnoughDataError < StandardError; end
  
  def initialize(sprints = [])
    @sprints = sprints
    @project = sprints.first && sprints.first.project
  end
  
  def values_for_display
    resp = values
    resp.unshift(nil)   #this values represent first and last point, used to display nice average velocity
    resp.push(nil)
  end

  def labels
    resp = @sprints.map(&:name)
    resp.unshift("") #this values represent first and last point, used to display nice average velocity
    resp.push("")
  end

  def average_velocity 
    num = @sprints.length
    @sprints.map(&:items_estimated_effort).sum.to_f / num
  end

  def label_step
      (labels.length.to_f / 7).ceil
  end


  protected

  def not_enough_data_message(text = "No sprints to display")
    return super(text)
  end
end