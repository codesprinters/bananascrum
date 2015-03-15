class NotEnoughDataError < StandardError; end

class WorkLoadChart < BurnChart
  def compute_chart
    sql = generate_sql_query
    @data = connection.select_all(sql)  
    raise NotEnoughDataError.new if @data.blank?
  end
  
  def generate_sql_query
    sql = "
      SELECT
        SUM(tasks.estimate) AS 'load' ,
        COALESCE(users.login, 'unassigned') AS 'login'
      FROM tasks
      JOIN backlog_elements AS items
        ON tasks.item_id = items.id and items.type = 'Item'
      LEFT JOIN task_users AS task_users
        ON tasks.id = task_users.task_id
      LEFT JOIN users AS users
        ON task_users.user_id = users.id
      WHERE items.sprint_id = #{@sprint.id }
      GROUP BY task_users.user_id
      ORDER BY login ASC"
      
    return sql
  end

  def labels
    @data.map{|row| row["login"]}
  end

  def values
    @data.map{|row| row["load"].to_i}
  end

  def values_for_display
    if labels.include?('unassigned')
      index = labels.index('unassigned')      

      resp = values.clone
      
      value = OpenFlashChart::BarFilledValue.new(resp[index])
      value.set_colour '908C8C'
      resp[index] = value
      return resp
    else
      return values
    end
  end

  def label_step
    1
  end

  def render_data
    compute_chart
    super
    
    @chart.title = { 'text' => 'Workload Chart', 'colour' => '525660', 'style'=> '{font-size: 18px; color: #525660; padding-bottom: 10px;}' }
    
    bar = OpenFlashChart::Bar.new({:tip => "#val##{@sprint.project.task_unit}<br> left for #x_label# ", :on_show => {:type => "grow-up", :cascade => 2.5, :delay => 1}})
    bar.set_colour 'B2AEAF'
    bar.set_alpha 0.8
    bar.set_values(values_for_display)
    @chart.add_element(bar)
    
    return @chart.render
  rescue NotEnoughDataError => e
    return not_enough_data_message
  end

  protected

  def not_enough_data_message(text = "No tasks assigned to the sprint")
    return super(text)
  end

end
