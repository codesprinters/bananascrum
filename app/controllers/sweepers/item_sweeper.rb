class ItemSweeper < ActionController::Caching::Sweeper
  observe Item, Clip, ItemTag, Comment, Task, TaskUser, Tag
   
  def after_create(object)  
    items = get_items(object)
    items.each do |item|
      expire_cache_for(item)
    end
  end  
    
  alias_method :after_update, :after_create
  alias_method :before_destroy, :after_create
  
  protected
  
  def expire_cache_for(item)
    expire_fragment :id => item.id, :controller => :items, :action => :show, :action_suffix => :old
    expire_fragment :id => item.id, :controller => :items, :action => :show, :action_suffix => :new
  end
  
  def get_items(object)
    if object.kind_of? Item
      return [object]
    elsif object.kind_of? Tag
      return object.items
    else
      return [object.item]
    end
  end
  
end
