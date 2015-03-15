require "csv"

class ItemsController < ProjectBaseController
  include JuggernautFilters
  include RemoveNeighbouringMarkers
  
  helper :tasks, :backlog, :juggernaut_tag, :item_logs

  limit_access :product_owner, :except => [ :destroy, :update, :backlog_item_estimate, :backlog_item_user_story ],
    :if => Proc.new { |c| !Item.find(c.params[:id]).sprint.nil? if c.params[:id] }

  # GETs should be safe
  verify :method => :post, :only => [ :create, :update,
    :backlog_item_user_story, :backlog_item_description, :backlog_item_estimate],
    :redirect_to => { :action => :list }

  before_filter :create_juggernaut_session, :only => [:index, :show]
  
  before_filter :new_layout_only, :only => [ :show ]
  before_filter :find_sprint, :only => [:new, :create]
  before_filter :find_item, :only => [:backlog_item_user_story, :backlog_item_estimate, :backlog_item_description, :show]
  before_filter :disallow_non_get_for_finished_sprints, :only => [:new, :create, :destroy, :backlog_item_user_story, :backlog_item_description, :backlog_item_estimate]

  prepend_after_filter :juggernaut_broadcast, :only => [:sort, :create, :destroy, :backlog_item_description, :backlog_item_estimate, :backlog_item_user_story, :lock, :unlock, :import_csv, :bulk_add, :sort ]
  prepend_after_filter :refresh_burnchart, :only => [:backlog_item_estimate, :destroy], :if => Proc.new { @sprint.nil? }
  prepend_after_filter :unlock_item, :only => [ :unlock, :backlog_item_description, :backlog_item_user_story, :sort]

  cache_sweeper :item_sweeper, :only => [ :destroy, :backlog_item_description, :backlog_item_estimate, :backlog_item_user_story ]

  def show
    number_to_show = 10
    @users_for_log_filter = @item.users_who_changed_it
    scope = @item.logs.not_task_estimate_updates_for_deleted_tasks.not_item_assignment_for_deleted_sprints
    @logs = scope.find :all, :limit => number_to_show
    @log_count = [ @item.logs.count - number_to_show, 0 ].max
  end

  def index
    prepare_list
    partial =  User.current.new_layout ? 'index_new' : 'index'
    respond_to do |format|
      format.html {render partial}
      format.js { render_list_json }
    end
  end

  def print
    prepare_list
    @stats = Item.stats_for_printing @items
    render :layout => "print"
  end

  def sort
    begin
      Item.transaction do
        project = Project.current
        @item = Project.current.items.not_assigned.find(params['item'].to_i)
        old_position = @item.position
        new_position = params['position'].to_i
        if old_position != new_position
          remove_neighbouring_markers(@item)
          @item.position = new_position
          @item.save!
        end
      end
    rescue ActiveRecord::RecordNotFound => rnf
      return render_json(404, :_error => {:type => 'backlog_sort', :message => "Attempted to sort nonexistent item"})
    rescue => e
      return render_json(409, { :_error => { :type => 'backlog_sort', :message => e.to_s } })
    end
    return render_json(200, :item => @item.id, :position => params['position'], :_removed_markers => @removed_markers)
  end

  def new
    @item = Item.new
    @item.project = Project.current
    if request.xhr?
      return render_to_json_envelope :partial => 'form'
    else
      render :action => 'new'
    end
  end

  def create
    Item.transaction do
      @current_project = Project.current
      @item = Item.new(params[:item])
      @screen = params[:screen]
      @item.position ||= 0 unless params[:'backlog-end'] == '1'
      if @item.save
        handle_tag_params(params)
        envelope = { :item => @item.id  }
        new_tags_objects = @item.project.tags.find_all_by_name(@new_tags)
        # we don't want to reply with empty 'tags' array. If there were no new
        # tags don't send array at all.
        unless new_tags_objects.empty?
          envelope[:tag_in_cloud] = {
            :old => render_to_string(:partial => 'tags/tag_in_tag_cloud', :collection => new_tags_objects, :as => :tag),
            :new => render_to_string(:partial => 'tags/tag_in_tag_cloud_new', :collection => new_tags_objects, :as => :tag)
          }
        end
        @item.reload
        envelope[:position] = @item.position
        render_to_json_envelope({ :partial => "items/item", :object => @item }, envelope)
      else
        form_html = render_to_string(:action => :new, :layout => false)
        render_json 409, :html => form_html
      end
    end
  end

  def copy
    begin
      Item.transaction do
        @original_item = Item.find(params[:id])
        @item = @original_item.create_copy
      end

      # prepare response
      envelope = { :item => @item.id  }
      envelope[:position] = @item.position
      envelope[:position_in_sprint] = @item.position_in_sprint
      render_to_json_envelope({ :partial => "items/item", :object => @item }, envelope)
    rescue
      form_html = render_to_string(:action => :new, :layout => false)
      render_json 409, :html => form_html
    end
  end

  def destroy
    Item.transaction do 
      @item = Project.current.items.find(params[:id])
      @sprint = @item.sprint
      remove_neighbouring_markers(@item)
      @item.destroy or raise Exception.new "Unable to delete item"
      flash[:notice] = "Backlog item '#{@item.user_story}' deleted."
      return render_json 200, :item => params[:id], :_removed_markers => @removed_markers
    end
  rescue ActiveRecord::RecordNotFound
    flash[:notice] = "Backlog item deleted."
    return render_json 200, :item => params[:id], :_removed_markers => []
  rescue => e
    flash[:error] = e.message
    return render_json 409
  end

  def lock
    @juggernaut_session = JuggernautSession.find(params[:session_id])
    Item.transaction do
      @item = Project.current.items.find(params[:id])
      @item.lock(@juggernaut_session)
    end
    envelope = {
      :item => @item.id,
      :locked_by_name => User.current.login,
      :operation => params[:operation]
    }
    render :json => envelope
  end

  def unlock
    @item = Project.current.items.find(params[:id])
    render_json :ok
  end

  # Renders item description without any filters (nl2br, redcloct)
  def item_description_text
    item = Project.current.items.find(params[:id])
    if item.description.nil?
      render :text => ""
    else
      render :text => item.description
    end
  end

  def backlog_item_description
    old_value = @item.readable_description

    @item.description = params[:value]

    description = if @item.save
      @item.readable_description
    else
      old_value
    end

    return render_to_json_envelope({:partial => 'shared/redcloth_description', :locals => { :description => description } }, :item => @item.id)
  end

  def backlog_item_user_story
    @item.user_story = params[:value]
    if @item.save
      return render_json(200, :item => @item.id, :value => @item.user_story)
    else
      if @item.errors.on(:user_story)
        flash[:error] = "Item user story #{@item.errors.on(:user_story).first}"
      else
        flash[:persistant] = @item.errors.full_messages.join
      end
      return render_json(409)
    end
  end

  def import_csv_from_file
    if request.xhr?
      return render_to_json_envelope :partial => 'import_csv_from_file'
    else
      render :nothing => true
    end
  end

  def import_csv
    @current_project = Project.current

    status = 200
    html = ''
    tags_html = []
    if params[:csv].nil?
      raise CSV::IllegalFormatError
    end
    converter =  BacklogItemConverter.new(Project.current, Project.current.csv_separator)
    items, new_tags = converter.import_csv(params[:csv])
    saved_items = items.select { |item| ! item.new_record? }
    rejected_count = items.length - saved_items.length
    unless items
      flash[:notice] = "Empty file"
    else
      html = {
        :old => render_to_string(:partial => 'item', :collection => saved_items),
        :new => render_to_string(:partial => 'item_new', :collection => saved_items)
      }
      tags_html = {
        :old => render_to_string(:partial => 'tags/tag_in_tag_cloud', :collection => new_tags, :as => :tag),
        :new => render_to_string(:partial => 'tags/tag_in_tag_cloud_new', :collection => new_tags, :as => :tag)
      }
      if saved_items.length == 0
        flash[:notice] = "No items were imported."
      else
        flash[:notice] = "CSV import successful. Imported #{saved_items.length} items."
      end
      if rejected_count > 0
        flash[:notice] += " #{rejected_count} items were rejected due to plan limit of backlog length."
      end
    end
  rescue CSV::IllegalFormatError
    flash[:error] = 'There was an error parsing your CSV file'
    status = 409
  ensure
    render_json_as_plain_text status, :html => html, :tag_in_cloud => tags_html
  end

  def export_to_csv
    @current_project = Project.current

    position_attribute = params[:sprint_id].nil? ? 'position' : 'position_in_sprint'
    @items = @current_project.items.all(:conditions => { :sprint_id => params[:sprint_id]}, :order => "backlog_elements.#{position_attribute} ASC", :include => [:tags, :tags])
    # FIXME: why charset and encoding?
    converter = BacklogItemConverter.new(@current_project, Project.current.csv_separator)
    send_data(converter.export_csv(@items).read,
      :type => 'text/csv; charset=iso-8859-1; header=present',
      :filename => 'items.csv',
      :disposition => 'attachment',
      :encoding => 'utf8'
    )
  end

  def backlog_item_estimate
    # opera sends string "null" if field value is set to null (js)
    if (params[:value] == "null" or params[:value] == "?")
      params[:value] = nil
    end
    @item.estimate = params[:value]
    @item.save
    @item.reload
    render_json 200, :estimate => @item.more_intish_estimate.to_s, :item => @item.id
  end

  # hack to redirect from /projects/name to product backlog, used in routes.rb
  def redirect_to_list
    redirect_to project_items_url(Project.current)
  end

  def bulk_add
    if request.post?
      text = params[:text] || ""
      creator = BulkItemCreator.new(@current_project)
      items = creator.parse(text)
      valid = Array.new
  
      Item.transaction do
        valid = items.reverse.select { |item| item.save }
        flash[:notice] = "Created #{valid.length} backlog items."
        flash[:notice] += " #{items.length - valid.length} items rejected as invalid" if valid.length < items.length
      end
      render_to_json_envelope :partial => "item", :collection => valid.reverse
    else
      render_to_json_envelope :layout => false #just render the content of modal window
    end
  end

  protected

  def prepare_list
    @current_menu_item = "Backlog"
    @current_project = Project.current
    @sprint_active = @current_project.last_sprint

    @items = @current_project.backlog_elements.not_assigned
  end

  def find_sprint
    @sprint = Sprint.find_by_id(params[:sprint])
  end

  def render_list_json
    render_to_json_envelope :partial => 'items/item', :collection => @items
  end

  def find_item
    @item = Project.current.items.find(params[:id])
    @sprint = @item.sprint
  end

  def handle_tag_params(params)
    if params[:tags].nil?
      tags = []
    else
      tags = @item.project.tags.find_all_by_id(params[:tags].values);
    end
    @new_tags = []
    @new_tags = params[:new_tags].values unless params[:new_tags].blank?
    # handling situation when user left new tag in input without pressing enter
    @new_tags << params[:new_item_tag] unless params[:new_item_tag].blank?
    @new_tags.uniq!
    tags += @new_tags
    tags.each do |t|
      @item.add_tag(t)
    end
  end
end
