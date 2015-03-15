class AttachmentsController < ProjectBaseController

  before_filter :find_attachment, :except => [:new, :create]
  prepend_after_filter :juggernaut_broadcast, :only => [ :destroy, :create ]

  cache_sweeper :item_sweeper, :only => [ :create, :destroy ]

  def new
    @item = Item.find(params[:item_id])
    @attachment = @item.clips.build
    if request.xhr?
      render_to_json_envelope :partial => 'form'
    end
  end

  def download
    if AppConfig.use_aws_s3
      redirect_to @attachment.temporary_link
    else
      path = @attachment.content.path
      send_file(path,
          :disposition => 'attachment',
          :encoding => 'utf8',
          :type => @attachment.content_content_type,
          :filename => URI.encode(@attachment.content_file_name))
    end
  rescue ActionController::MissingFile
    render_not_found
  end
  alias show download

  def create
    @item = Item.find(params[:item_id])
    @attachment = @item.clips.new(params[:attachment])

    html = nil
    status = 200
    # responding to iframe. We send JSON envelope, but treat is as text,
    # because Firefox goes crazy when he gets JSON to iframe
    if @attachment.save
      html = render_to_string(:partial => 'file', :layout => false, :object => @attachment)
    else
      html = render_to_string(:action => 'new', :layout => false)
      status = 409
    end
    render_json_as_plain_text status, :html => html
  end

  def destroy
    @item = @attachment.item
    if @attachment.destroy
      render_json 200, :item => @item.id, :asset_id => params[:id]
    else
      render_json 500
    end
  end

  private

  def find_attachment
    asset = Clip.find(params[:id])
    if asset.item.project == Project.current
      @attachment = asset
    else
      @attachment = nil
    end
  end

end
