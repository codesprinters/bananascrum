class BulkItemCreator
  attr_accessor :project

  def initialize(project)
    self.project = project
  end

  def parse(text)
    result = []
    lines = text.split("\n")
    while lines.length > 0 
      item = lines.shift
      next unless user_story?(item)
      tasks = []
      task = lines.shift
      while task?(task) 
        tasks.push(task) 
        task = lines.shift
      end
      lines.unshift(task) if task
      result << new_backlog_item(item, tasks)
    end
    return result
  end

  def new_backlog_item(item, tasks)
    user_story, estimate = split_estimate(item)
    
    tasks_attributes = tasks.map do |task|
      task = cutoff_separators(task)
      summary, task_estimate = split_estimate(task)
      task_estimate = task_estimate.to_i if task_estimate

      { :summary_safe => summary, :estimate_safe => task_estimate, :suppress_parent_validation => true }
    end

    params = { :position => 0, :user_story_safe => user_story, :estimate => estimate, :tasks_attributes=> tasks_attributes, :project => self.project }
    return Item.new(params)
  end

  def split_estimate(text)
    parts = text.split(',')
    match = parts.last.match(/^\s?[0-9]+(\.[0-9]+)?$/)
    story = estimate = nil
    if match 
      story = parts[0..-2].join(',')
      estimate = match[0].to_f
    else
      story = text
    end
    return story, estimate
  end

  def user_story?(line)
    return !line.blank? && !task?(line)
  end

  def task?(line)
    return !line.blank? && line.match(task_regexp)
  end

  def task_regexp
    /^\s*[\s\+\-\#\*]\s*/
  end

  def cutoff_separators(text)
    text.gsub(task_regexp, '')
  end

end
