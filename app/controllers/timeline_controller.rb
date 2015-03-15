class TimelineController < ProjectBaseController
  include JuggernautFilters

  helper :tasks, :backlog, :juggernaut_tag
  before_filter :restrict_to_plan
  before_filter :new_layout_only
  before_filter :create_juggernaut_session, :only => [:show]
  
  def show
    @current_menu_item = 'timeline'
    @project = Project.current

    @past_sprints = @project.sprints.past
    @ongoing_sprints = @project.sprints.ongoing
    @items = @project.backlog_elements.not_assigned

    @sprint_active = @project.last_sprint
    @sprints_after_today_json = @current_project.sprints_to_plan.map do |s|
      {:name => s.name, :sequence_number => s.sequence_number,
       :from_date => s.from_date.strftime(User.current.prefered_date_format), :to_date => s.to_date.strftime(User.current.prefered_date_format)}
    end.to_json
    last_sprints = [@ongoing_sprints, @past_sprints].map { |collection| collection.last }.select { |s| s }
    if last_sprints.length > 0
      @last_sprint_number = last_sprints[0].sequence_number
    else
      @last_sprint_number = 0
    end
    
    @sprints_load_chart_data = SprintsLoadChart.new(@past_sprints).render_data.to_json
#     To be uncommented after we redesign this graph
#     @project_burnup_chart_data = ProjectBurnupChart.new(@past_sprints).render_data.to_json
    
    @stats = ProjectStats.new(@project).compute
  end

  protected
  def restrict_to_plan
    raise ActiveRecord::RecordNotFound unless Domain.current.plan.timeline_view
  end

end
