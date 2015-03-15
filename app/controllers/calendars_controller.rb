class CalendarsController < ProjectBaseController
  
  before_filter :set_user_to_nil, :only => 'show'
  skip_filter :authorize, :only => 'show'
  
  def show
    # Check calendar key
    unless params[:key] && params[:key] == Project.current.calendar_key
      flash[:error] = "Invalid calendar key"
      return redirect_to project_sprints_url(Project.current)
    end

    @calendar = Project.current.sprint_calendar
    render :text => @calendar.to_ical, :content_type => "text/calendar"
  end
end
