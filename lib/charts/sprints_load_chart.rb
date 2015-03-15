require 'project_chart'

class SprintsLoadChart < ProjectChart
  
  def values
    @sprints.map(&:items_estimated_effort)
  end
    
  def average_velocity_values
    ave = average_velocity
    resp = []
    (@sprints.length + 2).times { resp.push(ave) }
    return resp
  end
  
  
  def render_data
    raise NotEnoughDataError.new if @sprints.blank?
    
    super
    
    @chart.title = { 'text' => 'Sprint load history', 'colour' => '525660', 'style'=> '{font-size: 18px; color: #525660; padding-bottom: 10px;}' }
     
    bar = OpenFlashChart::BarFilled.new
    bar.set_colour("B2AEAF")
    bar.set_values values_for_display
    bar.set_tooltip("#x_label#<br>#val# #{@project.backlog_unit}")
    @chart.add_element bar
    
    line = OpenFlashChart::Line.new(:width=> 3)
    line.set_values(average_velocity_values)
    line.set_font_size('12')
    line.set_colour("B2AEAF")
    line.set_tooltip("Average velocity: #val##{@project.backlog_unit}")
    line.text = "Average velocity"
    @chart.add_element(line)
    
    xaxis = OpenFlashChart::XAxis.new(:grid_colour => "c7cddd", :colour => "784016", :label_colour => '282c35', :steps => 1, :font_size => 12, :style => '{font-size: 20px;}', :tick_height => 6, :offset => false)
    xlabels = OpenFlashChart::XAxisLabels.new(:steps => label_step)
    xlabels.labels = labels.map { |text| OpenFlashChart::XAxisLabel.new(text, '282c35', "10", 10) }
    xaxis.labels = xlabels
    xaxis.set_range(0, @sprints.length + 1)
    
    @chart.x_axis = xaxis
    
    return @chart.render
  rescue NotEnoughDataError => e
    return not_enough_data_message
  end
  
end
