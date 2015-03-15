class BacklogItemTagsController < ProjectBaseController

  cache_sweeper :item_sweeper, :only => [ :create, :destroy ]
  prepend_after_filter :juggernaut_broadcast, :only => [ :create, :destroy ]

  def new
    @item = Item.find(params[:item_id])
    @available_tags = @item.project.tags - @item.tags
    @available_tags_names = @available_tags.map(&:name)
    envelope = { :tags => @available_tags_names }
    render_to_json_envelope({ :partial => 'assign_form' }, envelope)
  end

  def create
    Item.transaction do
      @item = Item.find(params[:item_id])
      @tag = @item.project.tags.find_by_name(params[:tag])
      @tag ||= @item.project.tags.new(:name => params[:tag])
      @item.add_tag(@tag)
    end
    tag_in_cloud = render_to_string(:partial => 'tags/tag_in_tag_cloud', :locals => {:tag => @tag})
    tag_in_cloud_new = render_to_string(:partial => 'tags/tag_in_tag_cloud_new', :locals => {:tag => @tag})
    render_to_json_envelope({
        :partial => 'items/item_tag',
        :locals => {:item => @item, :tag => @tag}
      }, {
        :item => @item.id,
        :tag_in_cloud => {
          :new => tag_in_cloud_new,
          :old => tag_in_cloud
        },
        :tag_id => @tag.id
      })
  rescue ActiveRecord::RecordInvalid
    render_json :conflict
  end

  def destroy
    # deasign tag from backlog_item
    Item.transaction do
      @item = Item.find(params[:item_id])
      @tag = @item.tags.find(params[:id])
      @item.remove_tag(@tag)
    end
    render_json 200, :item => @item.id, :tag => @tag.name
  end

end
