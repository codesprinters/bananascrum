module JuggernautFilters

  def create_juggernaut_session
    @juggernaut_session = JuggernautSession.create(:user => User.current, :project => @current_project)
  end

end
