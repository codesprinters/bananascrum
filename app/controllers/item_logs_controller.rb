
class ItemLogsController < ProjectBaseController
  
  before_filter :find_item
  
  # all params optional:
  #   skip_count - number of elements to skip (already visible on screen)
  #   user_filter - filter to specific user 
  #   limit - number of logs to fetch (default all)
  #   estimate_updates - show task estimate updates (default true)
  #   older_than - fetch only logs older than
  def index
    opts = HashWithIndifferentAccess.new({ 
      :skip_count => 0,
      :limit => 10000
    }).merge(params)
    
    
    find_opts = {
      :offset => opts[:skip_count].to_i
    }
    find_opts[:limit] = opts[:limit].to_i if opts[:limit]
    count_opts = find_opts.clone      # this is necessary, calling find would add some keys to the hash
    
    scope = @item.logs
    scope = scope.scoped(:conditions => [ "logs.created_at < ?", opts[:older_than]]) if opts[:older_than]
    scope = scope.not_task_estimate_updates_for_deleted_tasks.not_item_assignment_for_deleted_sprints
    scope = scope.not_task_updates unless opts[:estimate_updates]
    
    scope = scope.for_user(opts[:user_filter]) unless opts[:user_filter].to_i == 0
    
    total_count = scope.count :all
    collection = scope.find :all, find_opts
    
    remaining_count = [ total_count - opts[:skip_count].to_i - collection.length, 0 ].max
    html = render_to_string(:partial => "items/log", :collection => collection)
    
    render_json 200, :html => html, :logs_remaining => remaining_count
  end
  
  def show
    @log = @item.logs.find(params[:id])
    @fields = @log.fields.select { |field| %w(user_story description estimate).include?(field.name.to_s) }
    render_to_json_envelope :layout => false
  end
  
  protected
  def find_item
    @item = Item.find(params[:item_id])
  end
end
