require 'burn_chart'

class BurndownStoryChart < BurnChart

  def compute_chart_data
    time_zone = Time.zone.tzinfo
    time_zone = time_zone ? time_zone.name : 'UTC'

    sql = generate_sql_query(time_zone)
    plain_data = connection.select_all(sql)

    data = Hash.new
    plain_data.each do |row|
      data[row['day']] ||= Hash.new
      data[row['day']][row['id'].to_s] = { :remain => row['hours'].to_i }
    end

    estimated_items = @sprint.items.reject{ |item| item.estimate.nil? }

    (@sprint.from_date..@sprint.to_date).map do |day|
      if @for_date and day > @for_date
        [day, nil]
      else
        day_result = @sprint.items_estimated_effort
        estimated_items.each do |item|
           if item_finished?(data, item, day)
             day_result -= item.estimate
           end
        end
        [day, day_result]
      end
    end
  end

  def chart_data
    @data ||= compute_chart_data
  end

  def ideal_burndown
    sprint_days = ((@sprint.from_date + 1)..@sprint.to_date)

    if @sprint.project.free_days then
      working_days = sprint_days.select {|day| @sprint.project.free_days[day.wday.to_s] != '1'}
    else
      working_days = sprint_days.to_a
    end
    
    left = @sprint.items_estimated_effort.to_f
    delta = left / working_days.length
      
    (@sprint.from_date..@sprint.to_date).map do |day|
      left -= delta if working_days.include?(day) 
      [day, sprintf("%2.1f", left)]
    end
  end

  def ideal_values
    ideal_burndown.map(&:last)
  end

  def item_finished?(data, item, day)
    day.downto(@sprint.from_date) do |current|
      day_row = data[current.to_s(:db)]
      next unless day_row and day_row.has_key?(item.id.to_s)
      return day_row[item.id.to_s][:remain] == 0
    end
    return false
  end

  def y_max
    if values.empty? 
      effort = @sprint.items_estimated_effort.to_i
      return (effort > 8) ? effort + 5 : 10
    else
      (([values.max.to_f, ideal_values.map(&:to_f).max].max / 10).floor + 1) * 10
    end
  end

  def generate_sql_query(tz)
    time_converting_function = "DATE(IFNULL(CONVERT_TZ(tl.timestamp, 'UTC', '#{tz}'), tl.timestamp))"

    sql = "
    SELECT
        d.day,
        SUM( IF(tl.estimate_new IS NULL,
                  -tl.estimate_old,
                  IF(tl.estimate_old IS NULL, tl.estimate_new, tl.estimate_new - tl.estimate_old)
               )
           ) AS hours,
        backlog_elements.id AS id
    FROM
        task_logs tl
        JOIN (SELECT
                  DISTINCT #{time_converting_function} AS day
              FROM
                  task_logs tl
              WHERE
                  tl.sprint_id = #{@sprint.id}
              ORDER BY
                  day
            ) d ON d.day >= #{time_converting_function}
        JOIN tasks ON tl.task_id = tasks.id
        JOIN backlog_elements ON tasks.item_id = backlog_elements.id AND backlog_elements.type = 'Item'
    WHERE
        tl.sprint_id = #{@sprint.id}
    GROUP BY
        d.day, backlog_elements.id
    ORDER BY
        d.day"

    return sql
  end

  def render_data
    super
    
    @chart.title = { 'text' => "#{@sprint.project.backlog_unit} Burndown Chart",
      'colour' => '525660', 'style'=> '{font-size: 18px; color: #525660; padding-bottom: 10px;}' }
     
    line = OpenFlashChart::LineHollow.new(:dot_size => 3, :width=> 2, :halo_size => 0)
    line.set_values ideal_values.map{|f| f.to_f}
    line.set_font_size('12')
    line.set_colour("B2AEAF")
    line.set_tooltip("#key#<br>#x_label#: #val##{@sprint.project.backlog_unit}")
    line.text = "Ideal Burndown"
    line.font_size = 10
    @chart.add_element(line)

    line = OpenFlashChart::LineDot.new(:dot_size => 4, :width=> 3, :halo_size => 0)
    line.set_values values
    line.set_colour("#435255")
    line.set_font_size('12')
    line.set_tooltip("#key#<br>#x_label#: #val##{@sprint.project.backlog_unit}")
    line.text = "#{@sprint.project.backlog_unit} Remaining"
    line.font_size = 10
    @chart.add_element(line)
    
    return @chart.render
  end

end
