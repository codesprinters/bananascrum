class ProjectStats
  attr_accessor :project
  
  def initialize(project)
    @project = project
  end
  
  def compute
    result = {}
    result[:items_completed] = self.project.items.done.length
    result[:items_remaining] = self.project.items.remaining.length
    result[:time_elapsed] = self.time_elapsed 
    result[:velocity] = {
      :last_10 => self.velocity(self.last_10_sprints),
      :overall => self.velocity(self.past_sprints)
    }
    result[:team] = self.team_stats
    result
  end
  
  def past_sprints
    @past_sprints ||= begin 
      sprints = self.project.sprints.past
      sprints.map do |sprint|
        resp = {
          :velocity => sprint.items.map(&:estimate).compact.sum, 
          :team_count => sprint.users.count, 
          :from_date => sprint.from_date 
        }
        resp[:member_velocity] = resp[:velocity] / resp[:team_count] rescue 0
        resp
      end
    end
  end
  
  def time_elapsed
    return if past_sprints.blank?
    Date.current - past_sprints.first[:from_date]
  end
  
  def last_10_sprints
    first_index = (@past_sprints.length >= 10) ? -10 : -@past_sprints.length
    @past_sprints[first_index..-1]
  end
  
  def team_stats
    return Hash.new if past_sprints.blank?
    
    ave_size = past_sprints.map{ |sprint| sprint[:team_count] }.sum.to_f / past_sprints.length
    ave_vel = past_sprints.map{ |sprint| sprint[:member_velocity] }.sum.to_f / past_sprints.length
    {
      :ave_size => sprintf("%3.1f", ave_size),
      :ave_velocity => sprintf("%3.1f", ave_vel)
    }
  end
  
  def velocity(sprints)
    return Hash.new if sprints.blank?
    vel = sprints.map { |sprint| sprint[:velocity] }
    {
      :min => vel.min,
      :max => vel.max,
      :ave => sprintf("%3.1f", vel.sum.to_f / vel.length)
    }
  end
end