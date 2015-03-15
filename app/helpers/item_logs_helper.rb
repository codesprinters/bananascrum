module ItemLogsHelper
  class NotEnoughLogData < Exception; end;

  def log_text(log, options = {})
    options = {
      :show_details_link => true
    }.merge(options)
    method = "log_text_for_#{log.logable_type.underscore}_#{log.action}".to_sym
    text = nil
    if self.respond_to?(method)
      text = self.send(method, log, options)
    else
      raise NotEnoughLogData.new("Unknown log type")
    end
    
    return text
    
  rescue NotEnoughLogData => e
    # we shouldn't ever get here
    return false
  end
  
  def log_text_for_item_create(log, options = {})
    "created item '#{log.fields.for('user_story').try(:new_value)}' #{details_link(log, options)}"
  end
  
  def log_text_for_item_delete(log, options = {})
    "deleted item '#{log.fields.for('user_story').try(:new_value)}' #{details_link(log, options)}"
  end
  
  def log_text_for_item_update(log, options = {})
    if (log.fields.length > 1) 
      return "changed item attributes #{details_link(log, options)}"
    elsif log.fields.for('description')
      return "changed item description #{details_link(log, options)}"
    elsif field = log.fields.for('estimate')
      return "changed item estimate from #{Item.readable_estimate(field.old_value)} to #{Item.readable_estimate(field.new_value)}"
    elsif field = log.fields.for('user_story')
      return "changed item user story from '#{field.old_value}' to '#{field.new_value}'"
    elsif field = log.fields.for('sprint_id')
      if field.new_value.nil?
        return "dropped item from sprint #{sprint_link(log, field.old_value)}"
      else
        return "assigned item to sprint #{sprint_link(log, field.new_value)}"
      end
    end
  end
  
  def log_text_for_task_user_create(log, options = {})
    "assigned #{log.fields.for('user_full_name').try(:new_value)} to the task '#{log.fields.for('task_summary').try(:new_value)}'"
  end
  
  def log_text_for_task_user_delete(log, options = {})
    "unassigned #{log.fields.for('user_full_name').try(:old_value)} from the task '#{log.fields.for('task_summary').try(:old_value)}'"
  end
  
  def log_text_for_task_create(log, options = {})
    "created task '#{log.fields.for('summary').try(:new_value)}' with estimate #{log.fields.for('estimate').try(:new_value)}"
  end
  
  def log_text_for_task_delete(log, options = {})
    "deleted task '#{log.fields.for('summary').try(:old_value)}' with estimate #{log.fields.for('estimate').try(:old_value)}"
  end
  
  def log_text_for_task_update(log, options = {})
    if field = log.fields.for('estimate')
      if field.new_value.to_i == 0
        return "completed task '#{task_summary(log.task)}'"
      else
        return "changed estimated of the task '#{task_summary(log.task)}' from #{field.old_value} to #{field.new_value}"
      end
    elsif field = log.fields.for('summary')
      return "changed task summary from '#{field.old_value}' to '#{field.new_value}'"
    end
  end
  
  def task_summary(task)
    if task
      return task.summary
    else
      raise NotEnoughLogData.new("Task deleted")
    end
  end
  
  def sprint_link(log, sprint_id)
    sprint = log.item.project.sprints.find_by_id(sprint_id)
    if sprint
      return link_to(sprint.name, project_sprint_path(sprint.project.name, sprint))
    else
      raise NotEnoughLogData.new("Sprint deleted")
    end
  end
  
  def details_link(log, options = {})
    if options[:show_details_link]
      link_to("details", project_item_log_path(log.item.project.name, log.item, log), :rel => "facebox")
    end
  end
  
  def date_field(log)
    %Q~
      <div class="history-date-field" title="#{log.created_at.to_s(:db)}">
        #{log.created_at.to_date.to_s(:db)}
      </div>
    ~
  end
  
  def log_creator(log)
    log.user.nil? ? "Unknown user" : log.user.full_name
  end
  
  def present_field_value(field_name, value)
    method = "present_field_value_#{field_name}".to_sym
    if self.respond_to?(method)
      return self.send(method, value)
    else
      return value
    end
  end
  
  def present_field_value_description(value)
    textilize_without_paragraph(auto_link(h(value)))
  end
  
  def present_field_value_estimate(value)
    Item.readable_estimate(value)
  end
end