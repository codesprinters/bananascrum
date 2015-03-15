class ImpedimentsController < ProjectBaseController
  include InPlaceEditing
  in_place_edit_for :impediment, :summary
  
  helper :backlog
  
  prepend_after_filter :juggernaut_broadcast,
    :only => [:impediment_summary, :impediment_description, :create_comment, :create, :destroy, :status ]
  
  verify :method => :post, :only => [:create, :create_comment, :status]
  verify :method => :delete, :only => [:destroy]
  
  def new
    @impediment = Impediment.new
    render_to_json_envelope
  end

  def create_comment
    begin
      @impediment = Impediment.find(params[:id])
      @log = @impediment.comment(params[:comment])
      if request.xhr?
        render_to_json_envelope({ :partial => 'impediments/comment', :object => @log },  {:item => @impediment.id })
      else
        redirect_to project_items_path(Project.current)
      end
    rescue ActiveRecord::RecordInvalid => rie
      if request.xhr?
        flash[:error] = rie.to_s
        render_json 409 
      else
        render :action => 'new_comment'
      end
    end
  end

  def new_comment
    @impediment = Impediment.find(params[:id])
    if request.xhr?
      render_to_json_envelope :partial => 'impediments/comment_form'
    end
  end

  def create
    begin
      Impediment.transaction do
        @impediment = Impediment.new(params[:impediment])
        @impediment.project = Project.current
        @impediment.save!
        @impediment.reload
        if request.xhr?
          render_to_json_envelope :partial => 'impediments/impediment', :object => @impediment
        else
          redirect_to project_items_path(Project.current)
        end
      end
    rescue ActiveRecord::RecordInvalid => rie
      if request.xhr?
        new_form = render_to_string :action => "new", :layout => false
        render_json 409, :html => new_form
      else
        render :action => 'new'
      end
    end
  end
  
  def destroy
    @impediment = Project.current.impediments.find(params[:id])
    if @impediment.destroy then
      flash[:notice] = "Impediment '#{@impediment.summary}' deleted."
      if request.xhr?
        render_json 200, :item => params[:id]
      else
        redirect_to project_items_url(Project.current)
      end
    else
      flash[:error] = "Impediment was not deleted."
      if request.xhr?
        render_json 409, :_error => { :type => 'impediment_not_deleted', :message => flash[:error] }
      end
    end
  end

  def status
    begin
      Impediment.transaction do
        @reason =  (params[:comment].blank? ? "" : params[:comment] )
        @impediment = Project.current.impediments.find(params[:id])
        if (params[:impediment_status] == "Opened")
          @impediment.reopen(@reason)
        else
          @impediment.close(@reason)
        end
        @impediment.reload
        if request.xhr?
          render_to_json_envelope({ :partial => 'impediments/impediment', :object => @impediment },  { :item => @impediment.id })
        else
          redirect_to project_items_url(Project.current)
        end
      end
    rescue ActiveRecord::RecordInvalid => e
      flash[:error] = e.to_s
      render_json 409 
    end
  end
  
  def impediment_description
    @impediment = Project.current.impediments.find(params[:id])
    old_value = @impediment.readable_description

    @impediment.description = params[:value]

    description = if @impediment.save
      @impediment.readable_description
    else
      old_value
    end

    return render_to_json_envelope({:partial => 'shared/redcloth_description', :locals => { :description => description } }, :item => @impediment.id)
  end

  def description
    begin
      impediment = Project.current.impediments.find(params[:id])
      render :text => impediment.description 
    rescue ActiveRecord::RecordNotFound => e
      render_not_found
    end
  end

end
