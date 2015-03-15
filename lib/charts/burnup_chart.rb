class BurnupChart < BurnChart

  attr_reader :data, :sprint_span, :data_span
  
  def initialize(sprint, for_date = nil)
    super
    initialize_dates
    initialize_data_hash
  end

  def labels
    @sprint_span.map {|date| date.strftime(CHART_DATE_FORMAT)}
  end

  def work_done
    @data_span.map {|date| @data[date][:work_done]}
  end

  def workload
    @sprint_span.map {|date| @data[date][:workload]}
  end
  
  def values # used by code calculating y_max
    workload
  end
  
  def compute_chart
    for log in @sprint.task_logs
      put_into_bucket(log)
    end

    workload_all, work_done_all = 0, 0
    for date in dates_from_data
      workload, work_done = compute_deltas(@data[date])
      workload_all += workload
      work_done_all += work_done
      @data[date][:workload] = workload_all
      @data[date][:work_done] = work_done_all
    end
  end
  
  def put_into_bucket(log)
    unless log.task_id
      raise NotEnoughDataError
    end
    date = log.timestamp_in_zone.to_date
    @data[date][:tasks][log.task_id] << log
  end

  def compute_deltas(data)
    deltas = {:removed => [], :rising => [], :falling => []}
    for logs in data[:tasks].values
      next if logs.empty?
      first_estimate = logs.first.estimate_old
      last_estimate = logs.last.estimate_new
      type, delta = categorized_delta(first_estimate, last_estimate)
      deltas[type] << delta
    end
    rising = deltas[:rising].inject(0) {|sum, n| sum + n }
    removed = deltas[:removed].inject(0) {|sum, n| sum + n }
    falling = deltas[:falling].inject(0) {|sum, n| sum + n }
    return rising.to_i + removed.to_i, falling
  end

  def categorized_delta(first, last)
    case
    when first.nil? && last.nil?
      [:rising, 0]
    when first.nil?
      [:rising, last]
    when last.nil?
      [:removed, -first]
    when last > first
      [:rising, last - first]
    else
      [:falling, first - last]
    end
  end

  # creates data for flash graph
  def render_data
    compute_chart
    super
    
    @chart.title = { 'text' => 'Burnup Chart', 'colour' => '525660', 'style'=> '{font-size: 18px; color: #525660; padding-bottom: 10px;}' }
     
    line = OpenFlashChart::LineHollow.new(:dot_size => 4, :width=> 3, :halo_size => 0)
    line.set_values workload
    line.set_font_size('12')
    line.set_colour("B2AEAF")
    line.set_tooltip("#key#<br>#x_label#: #val#h")
    line.text = "Total workload"
    line.font_size = 10
    @chart.add_element(line)

    line = OpenFlashChart::LineDot.new(:dot_size => 4, :width=> 3, :halo_size => 0)
    line.set_values work_done
    line.set_colour("#435255")
    line.set_font_size('12')
    line.set_tooltip("#key#<br>#x_label#: #val#h")
    line.text = "Work done"
    line.font_size = 10
    @chart.add_element(line)
    return @chart.render
  end

  def initialize_dates
    @sprint_span = @sprint.from_date..@sprint.to_date
    if @for_date.nil? or @for_date > @sprint.to_date
      @for_date = @sprint.to_date
    end
    @data_span = @sprint.from_date..@for_date
  end

  def initialize_data_hash
    @data = Hash.new do |data_hash, date|
      data_hash[date] = {
        :tasks => Hash.new {|h,k| h[k] = [] },
        :work_done => 0,
        :workload => 0
      }
    end

    # dates that have to be taken into account
    for date in @sprint_span
      @data[date]
    end
  end

  def dates_from_data
    @data.keys.sort
  end

end
