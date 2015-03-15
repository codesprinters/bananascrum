class BurnChart

  CHART_DATE_FORMAT = "%d %b"

  attr_reader :free_days_indexes

  def initialize(sprint, for_date = nil)
    @sprint = sprint
    @for_date = for_date
  end

  def labels
    chart_data.map { |e| e[0].strftime CHART_DATE_FORMAT }
  end

  def values
    chart_data.map { |e| e[1] }.compact
  end

  def y_max
    ((values.max.to_f / 10).round + 1) * 10
  end

  def label_step
    (labels.length.to_f / 10).ceil
  end

  # naive memoization of burndown data
  def chart_data
    @chart_data ||= compute_chart_data
  end

  def render_data
    @chart = OpenFlashChart::Base.new
    @chart.set_bg_colour('E7ECEE')
    
    xaxis = OpenFlashChart::XAxis.new(:grid_colour => "c7cddd", :colour => "565055", :label_colour => '666666', :steps => 1, :font_size => 12, :style => '{font-size: 20px;}', :tick_height => 6)
    xlabels = OpenFlashChart::XAxisLabels.new(:steps => label_step)
    xlabels.labels = labels.map { |text| OpenFlashChart::XAxisLabel.new(text, '282c35', "10", 0) }
    xaxis.labels = xlabels
    @chart.x_axis = xaxis
    @chart.set_colour('525660')
    
    yaxis = OpenFlashChart::YAxis.new(:steps => y_max/5, :min => 0, :max => y_max, :grid_colour => "c7cddd", :colour => "565055", :tick_length => 6)
    @chart.y_axis = yaxis
    @chart.set_y_label__label_style("12,#282c35")
    
    tooltip = OpenFlashChart::Tooltip.new
    tooltip.set_shadow(true)
    tooltip.set_stroke(2)
    tooltip.set_colour("#B3C2C4");
    tooltip.set_background_colour("#D6E1E3");
    tooltip.set_title_style( "{font-size: 14px; color: #333333; text-align: center;}" );
    tooltip.set_body_style( "{font-size: 10px; font-weight: bold; color: #111111; text-align: center;}" );
    @chart.set_tooltip(tooltip)
    
  end
  
  protected

  def not_enough_data_message(text = nil)
    background = "E7ECEE"
    response = {
      "elements" => [], 
      "title" => { "text" => text, 'colour' => '525650', 'style' => '{font-size: 18px; color: #525660; padding: 80px 10px;}'}, 
      "bg_colour" =>  background, 
      "y_axis" => {
        "labels" => [ '' ],
        "grid-colour" => background , 
        "colour" => background 
      }, 
      "x_axis" => {
        "grid-colour" => background ,
        "colour" => background 
      }
    }
    return response.to_json
  end

  def connection
    @sprint.connection
  end

end