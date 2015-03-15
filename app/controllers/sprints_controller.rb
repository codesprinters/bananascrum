class SprintsController < ProjectBaseController
  include JuggernautFilters
  include SprintsHelper
  include RemoveNeighbouringMarkers

  helper :application, :backlog, :tasks, :juggernaut_tag
  
  limit_access :product_owner, :only => [ :index, :show, :chart_data, :chart, :print ]

  before_filter :create_juggernaut_session, :only => [:chart, :show, :plan]
  before_filter :find_sprint, :only => [:chart, :show, :print, :update, :destroy]
  before_filter :set_ongoing_sprints, :only => [ :index ]
  before_filter :disallow_non_get_for_finished_sprints
  prepend_after_filter :juggernaut_broadcast, :only => [ :destroy, :remove_item_from_sprint, :assign_item_to_sprint, :sort, :update ]
  prepend_after_filter :unlock_item, :only => [:sort, :assign_item_to_sprint, :remove_item_from_sprint]
  prepend_after_filter :refresh_burnchart, :only => [ :remove_item_from_sprint, :assign_item_to_sprint, :update ]
  prepend_after_filter :refresh_participants, :only => [ :remove_item_from_sprint, :assign_item_to_sprint, :destroy ]

  def index
    @current_menu_item = "Sprints List"
    @sprints = Project.current.sprints.find(:all, :order => 'from_date ASC')
    if @ongoing_sprints.size > 1
      flash.now[:notice] ||= "\nMultiple ongoing sprints are marked with bold font"
    end
    @calendar_url = project_calendar_url(Project.current, :key => Project.current.calendar_key)
    conditional_render(:index_new, :index)
  end

  def chart
    set_chart_data
    render :layout => 'chart_fullscreen'
  end

  def new
    return render_can_not_create if Project.current.archived?
    start_date = Date.current

    last_sprint = Project.current.sprints.find(:first, :order => 'from_date DESC')
    if last_sprint then
      start_date = last_sprint.to_date + 1.day
      case start_date.cwday
      when 6
        start_date += 2.day
      when 7
        start_date += 1.day
      end
    end

    end_date = start_date + Project.current.sprint_length - 1
    @sprint = Sprint.new(:from_date => start_date, :to_date => end_date)
    @sprint.project = Project.current
    @sprint.sequence_number = @sprint.choose_biggest_sequence_number
    render_to_json_envelope
  end

  def create
    @current_menu_item = "Sprint"
    fix_date_params
    @sprint = Sprint.new(params[:sprint])
    if @sprint.save
      flash[:notice] = "Sprint “#{@sprint.name}” was successfully created."
      render_json 200, sprint_data(@sprint)
    else
      form = render_to_string :action => 'new', :layout => false
      render_json 409, :html => form
    end
  end

  def edit
    @current_menu_item = "Sprint"
    @sprint = Sprint.find(params[:id])
    render_to_json_envelope
  end

  def show
    @current_menu_item = "Sprint"
    @team_members = Project.current.team_members
    @assigned_items = @sprint.items.find(:all, :order => 'position_in_sprint ASC')
    @impediments = @sprint.project.impediments.find(:all, :order => "is_open DESC")
    @has_opened_impediment = @impediments.map(&:is_open).include?(true)
    
    set_chart_data
    conditional_render(:show_new, :show)
  end


  def print
    @sprint = Project.current.sprints.find(params[:id])
    @team_members = Project.current.team_members
    @assigned_items = @sprint.items.find(:all, :order => 'position_in_sprint ASC')
    @impediments = @sprint.project.impediments.find(:all, :order => "is_open DESC")
    @sprint_stats = @sprint.stats_for_printing

    render :layout => "print"
  end


  def plan
    @current_menu_item = "Planning"
    @sprint = Sprint.find(params[:id])
    set_chart_data
    unless @sprint.project.eql? Project.current
      flash[:error] = "Sprint #{@sprint.name} doesn't belong to project #{Project.current.name}"
      redirect_to :action => 'index', :project_id => @sprint.project.name
      return
    end
    @items = Project.current.items.find(:all,
      :conditions => { :sprint_id => nil },
      :order => 'backlog_elements.position ASC, tasks.position ASC, tags.name ASC',
      :include => [:tasks, :tags])
    @assigned_items = @sprint.items.find(:all, 
      :conditions => 'sprint_id is not null', 
      :order => 'position_in_sprint ASC')
    
  end

  def update
    # convert user formatted date to a db compatible one
    fix_date_params
    
    if @sprint.update_attributes(params[:sprint])
      flash[:notice] = "Sprint was successfully updated."
      return render_json 200, sprint_data(@sprint)
    else
      form = render_to_string :action => 'edit', :layout => false
      render_json 409, :html => form
    end
  end

  def destroy
    @items = @sprint.items
    if @sprint.destroy
      flash[:notice] = "Sprint '#{@sprint.name}' was successfully deleted. All sprint items were removed."
      render_json 200, { :id => params[:id] }
    else
      flash[:error] = "Sprint '#{@sprint.name}' was not deleted"
      render_json 409
    end
  end

  def remove_item_from_sprint
    @item = Item.find(params[:item_id])
    @sprint = @item.sprint
   
    return render_json 409, :_error => { :message => "This backlog item doesn't belong to any sprint" } if @sprint.nil?
    
    @sprint = @sprint.dup  #after unassigning this variable cannot be set to nil
      
    Item.transaction do
      @item.sprint = nil
      @item.position_in_sprint = nil
      @item.position = params[:position].to_i unless params[:position].nil?
      if !@item.save
        return render_json 409, :_error => { :message => "Unable to drop item from sprint.\n#{@item.errors.full_messages.join}" }
      end
    end

    flash[:notice] = "Item “#{@item.user_story}” was dropped from the sprint."
    render_to_json_envelope({:partial => 'items/item', :object => @item}, {:item => @item.id, :position => @item.position})
  end

  def assign_item_to_sprint
    begin
      Item.transaction do
        @sprint = Sprint.find(params[:id])
        @item = Item.find(params[:item_id], :conditions => ["sprint_id IS NULL"])
        remove_neighbouring_markers(@item)
        @sprint.assign_item(@item, params[:position] && params[:position].to_i)
        flash[:notice] = "Item “#{@item.user_story}” was assigned to the sprint."
      end
     
    # We get pretty explanation of what happened in exception message
    rescue Sprint::ItemWithInfiniteEstimateAssignmentError => ie
      return render_json 409, :item => @item.id, :position => @item.position, :_error => {:message => ie.to_s, :type => 'infinite_estimate_error' }
    rescue SecurityError => se
      return render_json 409, :_error => {:message => se.to_s, :type => 'assign_to_sprint_error' }
    end
    render_to_json_envelope({:partial => 'items/item', :object => @item},
      { :item => @item[:id], :position => @item.position_in_sprint, :_removed_markers => @removed_markers } )
  end

  def sort
    begin
      Item.transaction do
        @sprint = Project.current.sprints.find(params['id'].to_i)
        @item = @sprint.items.find(params['item'].to_i)
        @item.position_in_sprint = params['position'].to_i
        @item.save!
      end
    rescue ActiveRecord::RecordNotFound => rnf
      return render_json(404, :_error => {:type => 'sprint_sort', :message => 'Attemted to sort nonexistent item'})
    rescue => e
      return render_json(409, :_error => {:type => 'sprint_sort', :message => e.to_s})
    end
    return render_json(200, { :item => @item.id, :position => params['position'] })
  end

  def refresh_item_positions(item)
    return unless item
    # refresh item positions
    item.project.rearrange_items! if item.project
    item.sprint.rearrange_items! if item.sprint
  end

  def find_sprint
    begin
      @sprint = Project.current.sprints.find(params[:id])
      raise "Sprint not found" if @sprint.nil?
    rescue ActiveRecord::RecordNotFound
      flash.keep
      flash[:error] = "Invalid sprint selected. Please choose a valid sprint."
      redirect_to :action => :index, :project_id => Project.current.name
    end
  end

  private
  def fix_date_params
    if params[:sprint][:from_date]
      params[:sprint][:from_date] = Date.strptime(params[:sprint][:from_date], User.current.prefered_date_format).to_s(:db)
    end

    if params[:sprint][:to_date]
      params[:sprint][:to_date] = Date.strptime(params[:sprint][:to_date], User.current.prefered_date_format).to_s(:db)
    end
  end
  
  def set_ongoing_sprints
    @ongoing_sprints = Project.current.ongoing_sprints
  end
  
  def render_can_not_create
    render :status => 403, :action => 'can_not_create'
  end
  
  def sprint_data(sprint)
    set_ongoing_sprints
    resp = { :sprint => @sprint.attributes.slice('name', 'goals', 'id', 'sequence_number') } 
    resp[:sprint][:information_text] = sprint_information(sprint)
    resp[:sprint][:row_html] = render_to_string :partial => 'sprint', :object => sprint
    resp
  end

end
