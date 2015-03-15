class CommentsController < ProjectBaseController
  helper :backlog
  
  verify :method => :post, :only => [ :create ],
         :redirect_to => { :controller => 'backlog' }

  before_filter :find_item
  prepend_after_filter :juggernaut_broadcast, :only => [ :create ]
  
  cache_sweeper :item_sweeper, :only => [ :create ]

  def new
    @comment = Comment.new(:item => @item)
    render_to_json_envelope(:partial => 'comments_with_form', :locals => {:comment => @comment})
  end

  def create
    @comment = Comment.new(params[:comment])
    @comment.user = User.current
    @comment.item = @item
    if @comment.valid?
      @comment.save
      env = { 
        :number => @comment.item.comments.count, 
        :item => @item.id,
        :leaveOpen => true,
        :form => render_to_string(:partial => 'form', :locals => {:comment => @item.comments.build})

      }
      render_to_json_envelope({ :partial => 'comment', :object => @comment }, env)
    else
      render_json(:conflict, { :html => render_to_string(:partial => 'comments_with_form', :locals => {:comment => @comment}) })
    end
  end

  protected

  def find_item
    @item = Item.find(params[:item_id])
  end
end
