class TagsController < ProjectBaseController
  
  prepend_after_filter :juggernaut_broadcast, :only => [ :create, :update, :destroy ]
  cache_sweeper :item_sweeper, :only => [ :destroy, :update ]

  before_filter :find_project
  before_filter :find_tag, :except => [ :create ]
  
  def create
    @tag = @current_project.tags.create(params[:tag])
    if @tag.valid?
      render_to_json_envelope({:partial => 'tag_in_tag_cloud', :locals => {:tag => @tag }})
    else
      flash[:error] = @tag.errors.full_messages.join
      render_json 409
    end
  end

  def update
    @tag.update_attributes(params[:tag])
    if @tag.valid?
      render_to_json_envelope({:partial => 'tag_in_tag_cloud', :locals => {:tag => @tag}}, {:id => @tag.id, :color_no => @tag.color_no })
    else
      flash[:error] = @tag.errors.full_messages.join
      render_json 409
    end
  end

  def destroy
    
    if @tag.destroy
      render_json 200, :id => @tag.id
    else
      render_json :conflict
    end
  end

  private

  def find_project
    @current_project = Project.current
  end

  #filter
  def find_tag
    @tag = Project.current.tags.find(params[:id])
  end

  def render_tag(&block_for_html)
    respond_to do |format|
      format.xml { render :xml => @tag.to_xml }
      format.json { render :json => @tag.to_json }
      format.yaml { render :yaml => @tag.to_yaml }
    end
  end

  def render_tags
    respond_to do |format|
      format.html {render :partial => 'list'}
      format.xml { render :xml => @tags.to_xml }
      format.json { render :json => @tags.to_json }
      format.yaml { render :yaml => @tags.to_yaml }
    end
  end
end
