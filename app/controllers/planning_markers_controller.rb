class PlanningMarkersController < ProjectBaseController
  include JuggernautFilters
  verify :method => :post, :only => [:create]
  verify :method => :put, :only => [:update]
  verify :method => :delete, :only => [:destroy]

  prepend_after_filter :juggernaut_broadcast, :only => [:create, :update, :destroy, :destroy_all, :distribute]

  def create
    begin
      PlanningMarker.transaction do
        @marker = PlanningMarker.new
        @marker.project = @current_project
        @marker.position = params[:position].to_i
        @marker.save!
      end
    rescue => e
      render_json 409, :_error => { :type => 'planning_marker_create', :message => e.to_s}
    else
      render_json 200, :marker => @marker.id, :position => @marker.position
    end
  end

  def update
    begin
      PlanningMarker.transaction do
        @marker = Project.current.planning_markers.find(params[:id])
        @marker.position = params[:position].to_i if params[:position]
        @marker.save!
      end
    rescue ActiveRecord::RecordInvalid => ri
      envelope = {
        :marker => @marker.id,
        :position =>  @marker.position_was,
        :_error => {
          :type => 'planning_marker_update',
          :message => ri.to_s
        }
      }
      render_json 409, envelope
    else
      render_json 200, :marker => @marker.id, :position => @marker.position
    end
  end

  def destroy
    begin
      PlanningMarker.transaction do
        Project.current.planning_markers.find(params[:id]).destroy
      end
    rescue ActiveRecord::RecordNotFound => exception
      render_json 404, :_error => { :type => 'not_found', :message => exception.to_s }
    else
      render_json 200, :marker => params[:id]
    end
  end

  def destroy_all
    PlanningMarker.transaction do
      @current_project.planning_markers.destroy_all
      return render_json 200
    end
    render_json 409, :_error => {:message => "Couldn't delete markers"}
  end

  def distribute
    velocity = params[:velocity].to_f
    if velocity == 0.0
      return render_json 409, :_error => { :type => 'planning_markers_distribute', :message => "Velocity should be a number" }
    end
    markers = []
    
    SortableProductBacklog.disable_callbacks do
      PlanningMarker.transaction do
        @current_project.planning_markers.destroy_all
        SortableProductBacklog.new.fix_order_with_planning_markers(@current_project)
        
        sum = 0.0
        items_since_marker = 0
        index = 0
        
        # Avoid additional SELECT COUNT(*) query
        items = @current_project.items.not_assigned.map { |i| i }
        items_length = items.length

        items.each do |item|
          estimate = item.estimate == Item::INFINITY_ESTIMATE_REPRESENTATIVE ? 0.0 : item.estimate
          estimate = 0.0 if estimate.nil?
          
          sum += estimate
          new_marker = nil
          
          if sum > velocity
            if items_since_marker > 0
              index = item.position - 1   #insert before
              sum = estimate
              items_since_marker = 1
            else
              index = item.position
              sum = 0
              items_since_marker = 0
            end
            new_marker = PlanningMarker.new(:project => @current_project, :position => index, :dont_validate_positions => true)
            new_marker.save!
            markers << { :marker => new_marker.id, :position => index }
          else
            items_since_marker += 1
          end
        end
        SortableProductBacklog.new.fix_order_with_planning_markers(@current_project)
      end
    end
    render_json 200, markers
  end
end
