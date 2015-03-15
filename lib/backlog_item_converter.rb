require "csv"

class BacklogItemConverter
  INFINITY_STRING = "inf".freeze
  NOT_ESTIMATED_STRING = "?".freeze

  SEPARATORS = %W[\t ; ,]

  def initialize(project, separator)
    @project = project
    @separator = separator
    @items = []
    @last_item = nil
    @created_tags = []
  end

  def file_empty?(file)
    file.eof?
  end  

  def import_csv(csv_file)
    return [] if file_empty?(csv_file)

    separator = detect_separator(csv_file)
    ActiveRecord::Base.transaction do
      csv_file.rewind
      CSV::Reader.parse(csv_file, separator).each do |row|
        parse_csv_row(row)
      end
      
      for item in @items
        item.save
      end
        
    end
    return @items, @created_tags.compact
  end

  def export_csv(items)
    output = StringIO.new    
    CSV::Writer.generate(output, @separator) do |csv|
      items.each do |item|
        csv << export_item(item)
        for task in item.tasks
          csv << export_task(task)
        end
      end
    end
    output.rewind
    return output
  end

  def detect_separator(file)
    separators = [@separator] + SEPARATORS
    @best_candidate = @separator
    @best_candidate_cols = 0
    
    for separator in separators
      begin
        try_separator(file, separator)
      rescue CSV::IllegalFormatError
        # Parsing with wrong separator may cause exception, ignore it
      end
    end
    
    @best_candidate
  end

  # using parser handle CSV rows spanning multiple lines
  def try_separator(file, separator)
    file.rewind
    
    reader = CSV::Reader.parse(file, separator)
    row = reader.shift    
    if row.length > @best_candidate_cols
      @best_candidate = separator
      @best_candidate_cols = row.length
    end
    reader.close
  end

  private

  def parse_csv_row(row)
    if task_row?(row)
      parse_task_row(row)
    else
      item = parse_item_row(row)
      if item.valid?
        @items << item
        @last_item = item
      end
    end
  end

  def task_row?(row)
    row[0].nil? or row[0] == ''
  end

  def parse_task_row(row)
    return unless @last_item
    
    summary = row[4]
    estimate = row[5]
    logins = row[6]
    
    task = @last_item.tasks.build(:summary => summary, :estimate => estimate)
    if logins
      logins.split(',').each do |login|
        user = @project.domain.users.find_by_login(login)
        task.users << user if user
      end
    end
    task.item = @last_item
  end

  def parse_item_row(row)
    item = Item.new do |i|
      i.project = @project
      i.user_story = row[0]
      i.description = row[2]
      i.estimate = parse_estimate(row[1]) if row[1]
    end

    tags = row[3] || ""
    converter = TagConverter.new(tags)
    converter.to_a.each do |tag|
      new = item.add_tag(tag.strip)
      if new
        @created_tags << @project.tags.find_by_name(tag.strip)
      end
    end
    item
  end

  def parse_estimate(estimate_string)
    case estimate_string
    when INFINITY_STRING
      Item::INFINITY_ESTIMATE_REPRESENTATIVE
    when NOT_ESTIMATED_STRING
      nil
    else
      estimate = estimate_string.to_f
      estimate_choices = @project.estimate_choices      
      if estimate_choices.include?(estimate)
        if estimate == 0.0 and !(estimate_string == "0" or estimate_string == "0.0")
          nil
        else
          estimate
        end
      else
        nil
      end
    end
  end

  def export_item(item)
    tag_list = TagConverter.new(item.tag_list).to_s
    [item.user_story, csv_estimate(item.estimate), item.description, tag_list]
  end

  def export_task(task)
    login  =  !task.users.blank? && task.users.map(&:login).join(",")
    ['', '', '', '', task.summary, task.estimate, login]
  end

  def csv_estimate(estimate)
    case estimate
    when Item::INFINITY_ESTIMATE_REPRESENTATIVE
      INFINITY_STRING
    when nil
      NOT_ESTIMATED_STRING
    else
      estimate.to_s
    end
  end

  class TagConverter
    # List of mappings char => escape sequence
    # Used internally by converter class
    # If you want to extend it, make sure '%' is last element on the list
    # Otherwise, escape methods would double-escape some sequences
    ESCAPE_CHARS = [[',', '%2c'], ['%', '%25']]

    def initialize(tags)
      @tags = []
      if tags.is_a? String
        @tags = tags.split(',').map { |t| unescape(t) }
      else
        @tags = tags.to_a.map { |t| t.to_s }
      end
    end

    def to_a
      @tags
    end

    def to_s
      @tags.map { |t| escape(t) }.join(',')
    end

    protected
    def unescape(tag)
      ESCAPE_CHARS.each do |pair|
        to, from = pair
        tag = tag.gsub(from, to)
      end
      return tag
    end

    def escape(tag)
      ESCAPE_CHARS.reverse.each do |pair|
        from, to = pair
        tag = tag.gsub(from, to)
      end
      return tag
    end
  end
end
