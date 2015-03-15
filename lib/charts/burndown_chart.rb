require 'burn_chart'

class BurndownChart < BurnChart

  # Calculates ideal values for the sprint based on the sprint length, and initial
  # values, to create burnup we have to reverse these values
  def ideal_values(maximal_value = nil)
    maximal_value ||= chart_data.first[1]

    free_day = @sprint.project.free_days || {}

    free_days_indexes = []
    (@sprint.from_date..@sprint.to_date).each_with_index do |day, index|
      free_days_indexes << index if free_day[day.wday.to_s] == '1'
    end

    work_days = @sprint.length - free_days_indexes.length
    # a to wszystko przez to że pierwszy dzień jest tak naprawdę ignorowany
    work_days +=1 if free_days_indexes.include?(0)

    unless @sprint.length == 1
      height = maximal_value ? maximal_value.to_f : @sprint.tasks_estimated_effort
      interval =  height / (work_days.to_f - 1)

      [height] + (1...@sprint.length).map do |index|
        height -= interval unless free_days_indexes.include?(index)
        height
      end
    else
      []
    end
  end

  # computes values for actual burndown for the sprint.
  #
  # Returns array conatining ["day" => date(Date), "hours" => hours_remaining(Int)] pairs
  # for each day of the sprint (including first and last day)
  def compute_chart_data
    tz = Time.zone.tzinfo
    tz = tz ? tz.name : 'UTC'

    sql = generate_sql_query(tz)
    data = connection.select_all(sql)

    fittest_day = select_fittest_day(data)
    last = fittest_day ? fittest_day['hours'].to_i : 0

    result = []
    (@sprint.from_date..@sprint.to_date).each do |day|
      if @for_date and day > @for_date
        result << [day, nil]
      else
        if entry = data.find { |e| e['day'].to_date == day }
          last = entry['hours'].to_i
        end

        result << [day, last]
      end
    end

    return result
  end

  def y_max
    if values.empty?
      effort = @sprint.tasks_estimated_effort
      return (effort > 10) ? effort + 5 : 10
    else
      ((values.max.to_f / 10).floor + 1) * 10
    end
  end

  def generate_sql_query(tz)
    time_converting_function = 
      "DATE(
        IFNULL(
          CONVERT_TZ(tl.timestamp, 'UTC', '#{tz}'),
          tl.timestamp))"

    sql = "
    SELECT
        d.day,
        SUM( IF(tl.estimate_new IS NULL,
                  -tl.estimate_old,
                  IF(tl.estimate_old IS NULL, tl.estimate_new, tl.estimate_new - tl.estimate_old)
               )
           ) AS hours
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
    WHERE
        tl.sprint_id = #{@sprint.id}
    GROUP BY
        d.day
    ORDER BY
        d.day"

    return sql
  end

  # Ths routine selects the *last* entry that is created before
  # or on the first day of the sprint.
  def select_fittest_day(entries)
    entries.select {|entry| entry['day'].to_date <= @sprint.from_date}.
      max {|a, b| a['day'].to_date <=> b['day'].to_date}
  end

  # creates data for flash graph
  def render_data
    super
    
    @chart.title = { 'text' => 'Burndown Chart', 'colour' => '525660', 'style'=> '{font-size: 18px; color: #525660; padding-bottom: 10px;}' }
     
    line = OpenFlashChart::LineHollow.new(:dot_size => 3, :width=> 2, :halo_size => 0)
    line.set_values(ideal_values.map{|f| f.round})
    line.set_font_size('12')
    line.set_colour("B2AEAF")
    line.set_tooltip("#key#<br>#x_label#: #val#h")
    line.text = "Ideal Burndown"
    line.font_size = 10
    @chart.add_element(line)

    line = OpenFlashChart::LineDot.new(:dot_size => 4, :width=> 3, :halo_size => 0)
    line.set_values(values)
    line.set_font_size('12')
    line.set_colour("#435255")
    line.set_tooltip("#key#<br>#x_label#: #val#h")
    line.text = "Hours Remaining"
    line.font_size = 10
    @chart.add_element(line)
  
    return @chart.render
  end
end
