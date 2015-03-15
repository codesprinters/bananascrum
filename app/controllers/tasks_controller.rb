class TasksController < ProjectBaseController
  include InPlaceEditing
  include TasksHelper
  helper :backlog

  limit_access :product_owner, :none => true

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :create, :update, :task_estimate, :task_summary, :sort ],
    :redirect_to => { :controller => 'backlog' }
  
  prepend_after_filter :juggernaut_broadcast, :only => [:sort, :create, :destroy, :assign, :task_estimate, :task_summary ]
  prepend_after_filter :refresh_burnchart, :only => [:create, :destroy, :task_estimate, :assign]
  prepend_after_filter :refresh_participants, :only => [ :create, :destroy, :assign ]  
  prepend_after_filter :unlock_item, :only => [ :task_summary ]

  cache_sweeper :item_sweeper, :except => [ :new ]

  def sort
    begin
      @item = Project.current.items.find(params['item'])
      @sprint = @item.sprint
      return disallow_non_get_for_finished_sprints if sprint_edition_forbidden?(@sprint)
      Task.transaction do
        @task = @item.tasks.find(params['id'].to_i)
        @task.position = params['position'].to_i
        @task.save!
      end
    rescue ActiveRecord::RecordNotFound => rnf
      return render_json 404, :_error => { :type => 'item_sort', :message => "Item or task was not found" }
    rescue => e
      return render_json 409, :_error => { :type => 'item_sort', :message => e.to_s }
    end
    return render_json 200, :item => @item.id, :position => params['position'], :id => @task.id
  end

  def new
    @item = Item.find(params[:item_id])
    @task = Task.new
    @task.item = @item
    @task.users << User.current if @current_project.team_members.include? User.current
    
    if request.xhr?
      render_to_json_envelope({ :partial => 'tasks/form' }, { :mark => @task.users.map(&:login) })
    end
  end

  def create
    begin
      Task.transaction do
        @item = Item.find(params[:task][:item_id])
        @sprint = @item.sprint
        return disallow_non_get_for_finished_sprints if sprint_edition_forbidden?(@sprint)
        
        @task = Task.new(params[:task])
        @task.save!

        
        # No need to send info whether item is done. It is handled in view
        render_to_json_envelope({:partial => 'items/task'}, {:item_done => @item.is_done, :item => @item.id})
      end
    rescue ActiveRecord::RecordInvalid => rie
      new_form = render_to_string :partial => 'tasks/form_error_messages', :layout => false
      render_json 400, :_error => { :type => 'invalid_record', :message => "Couldn't save record" }, :html => new_form
    end
  end
  
  def destroy
    @task = Task.find(params[:id])
    @item = @task.item
    @sprint = @item.sprint
    return disallow_non_get_for_finished_sprints if sprint_edition_forbidden?(@sprint)
    if @task.destroy then
      flash[:notice] = "Task '#{@task.summary}' deleted."
      return render_json 200, :item_done => @item.reload.is_done, :item => @item.id, :id => params[:id]
    else
      flash[:error] = "Task was not deleted."
      return render_json 409
    end
  rescue ActiveRecord::RecordNotFound
    flash[:error] = "Task not found."
    return render_json 409
  end

  def assign
    @task = @current_project.tasks.find(params[:id])
    @sprint = @task.item.sprint
    return disallow_non_get_for_finished_sprints if sprint_edition_forbidden?(@sprint)
    users = params[:value] && params[:value].split(',').map{ |login| @current_project.users.find_by_login(login) }.compact
    @task.assign_users(users || [])
    
    return render_json 200, :login => get_users_logins(@task), :item => @task.item_id, :id => @task.id
  end

  def task_estimate
    begin
      task = Task.find(params[:id], :include => { :item => :sprint })
      @sprint = task.item.sprint
      return disallow_non_get_for_finished_sprints if sprint_edition_forbidden?(@sprint)
      
      Task.transaction do
        task.update_attributes! :estimate => params[:value]
        flash[:notice] = "Task '#{task.summary}' was marked as completed" if task.is_done
        render_json 200, :value => task.estimate,
          :task_done => task.is_done, :item_done => task.item.is_done, :item => task.item.id, :id => task.id
      end
    rescue ActiveRecord::RecordNotFound => rnf
      render_json 404, :_error => { :type => 'not_found',
        :message => "Unable to find task with id: #{params[:id].to_s}" }
    rescue ActiveRecord::RecordInvalid => e
      flash[:error] = e.record.errors.full_messages.join(", ")
      render_json(409)
    rescue => e
      render_json 409, :_error => { :type => 'task_estimate', :message => e.to_s }
    end
  end
  
  def task_summary
    @task = Task.find(params[:id], :include => :item)
    @sprint = @task.item.sprint
    return disallow_non_get_for_finished_sprints if sprint_edition_forbidden?(@sprint)
    
    Task.transaction do
      @item = @task.item
      old = @task.summary
      @task.summary = params[:value]
      if @task.save
        render_json 200, :item => @item.id, :id => @task.id, :value => @task.summary
      else
        flash[:error] = @task.errors.full_messages.join(". ")
        render_json 200, :item => @item.id, :id => @task.id, :value => old
      end
    end
  end



end
