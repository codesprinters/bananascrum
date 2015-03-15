class JuggernautSession < ActiveRecord::Base
  include DomainChecks
  
  belongs_to :user
  belongs_to :project
  has_many :locked_items, :class_name => "BacklogElement", 
    :foreign_key => 'locked_by_id'
    
  before_destroy :remove_all_locks
  validates_presence_of :initial_message_id, :project_id
  
  before_validation_on_create :set_initial_message_id
  
  named_scope(:logged_in, :conditions => "subscribed_at IS NOT NULL")
  
  def subscribed
    self.subscribed_at = Time.now
    save
  end
  
  def send_scheduled_messages
    messages = JuggernautCache.instance.get_scheduled_messages(self)
    messages.each do |message|
      Juggernaut.send_to_clients(message.body, [self.id])
    end
  rescue Errno::ECONNREFUSED
    logger.error("Connecting with Juggernaut failed!")  
  end
  
  def remove_all_locks
    unlocked = self.locked_items.map(&:id)
    JuggernautCache.instance.broadcast({'operation' => 'disconnected', :envelope => { :unlocked => unlocked } }, [self.project.id])
    self.locked_items = []
  end
  
  protected
  def set_initial_message_id
    self.initial_message_id = JuggernautCache.instance.current_id
  end
end
