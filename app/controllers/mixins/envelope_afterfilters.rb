# Methods which appends values to the envelope to trigger js behaviour
# Used in ApplicationController.
module EnvelopeAfterfilters
  JSON = ActiveSupport::JSON
  
  def error?
    code = response.status.split.first.to_i
    return code >= 400
  end

  def append_to_envelope(symbol, data)
    json = JSON.decode(response.body)
    json[symbol] = data
    response.body = json.to_json
  rescue JSON::ParseError
    #silent fail here... this means not json have been rendered and we cannot append
  end

  def unlock_item
    return if @item.nil?

    @item.unlock
    append_to_envelope(:_unlock, @item.id)
  end

  def refresh_participants
    return if error?
    return if @sprint.nil?

    append_to_envelope(:_participants, @sprint.participants)
  end

  def refresh_burnchart
    return if error?
    return if @sprint.nil?

    set_chart_data
    append_to_envelope(:_burnchart, @chart_data)
  end

  def refresh_project_members
    return if error?
    return if @project.nil?

    append_to_envelope(:_project_members, [ { :id => @project.id, :members => @project.users.count } ])
  end


  def set_chart_data
    @chart_data = {}
    @chart_data["burndown"] = @current_project.graph_visible?("Burndown") ? BurndownChart.new(@sprint, Date.current).render_data : nil
    @chart_data["burnup"] = @current_project.graph_visible?("Burnup") ? BurnupChart.new(@sprint, Date.current).render_data : nil
    @chart_data["workload"] = @current_project.graph_visible?("Workload") ? WorkLoadChart.new(@sprint).render_data : nil
    @chart_data["itemsburndown"] = @current_project.graph_visible?("Items Burndown") ? BurndownStoryChart.new(@sprint, Date.current).render_data : nil

    @chart_data = @chart_data.delete_if {|key, value| value.nil? }
  end

end
