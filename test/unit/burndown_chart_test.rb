require File.dirname(__FILE__) + '/../test_helper'

class BurndownChartTest < ActiveSupport::TestCase
  fixtures :sprints, :backlog_elements, :tasks, :task_logs, :projects, :users

  def setup
    super
    Domain.current = domains(:code_sprinters)
    User.current = users(:user_one)
    @sprint = sprints(:sprint_with_assigned_tasks)
  end
  
  def teardown
    super
    User.current = nil
    Domain.current = nil
  end

  def test_label_count
    chart = BurndownChart.new @sprint
    assert_equal @sprint.length, chart.labels.length
  end

  def test_label_format
    chart = BurndownChart.new @sprint
    assert_equal @sprint.from_date.strftime(BurndownChart::CHART_DATE_FORMAT), chart.labels[0]
    assert_equal @sprint.to_date.strftime(BurndownChart::CHART_DATE_FORMAT), chart.labels[-1]
  end

  def test_number_of_values_depending_on_date
    chart = BurndownChart.new @sprint, @sprint.from_date - 10.days
    assert_equal 0, chart.values.length

    chart = BurndownChart.new @sprint, @sprint.from_date
    assert_equal 1, chart.values.length

    chart = BurndownChart.new @sprint, @sprint.to_date
    assert_equal @sprint.length, chart.values.length

    chart = BurndownChart.new @sprint, @sprint.to_date + 10.days
    assert_equal @sprint.length, chart.values.length
  end

  def test_y_axis_maximum
    # 10 should be minimum for empty dataset
    chart = BurndownChart.new @sprint, @sprint.from_date - 1.day
    assert_equal [], chart.values
    assert_equal 10, chart.y_max

    chart = BurndownChart.new @sprint, @sprint.from_date
    assert_equal 9, chart.values.max
    assert_equal 10, chart.y_max

    chart = BurndownChart.new @sprint, "2007-01-15".to_date
    assert_equal 16, chart.values.max
    assert_equal 20, chart.y_max

    chart = BurndownChart.new @sprint
    assert_equal 16, chart.values.max
    assert_equal 20, chart.y_max
  end

  def test_label_steps
    new_sprint = @sprint.dup

    assumptions = [
      { :length => 2, :steps => 1 },
      { :length => 9, :steps => 1 },
      { :length => 10, :steps => 1 },
      { :length => 11, :steps => 2 },
      { :length => 33, :steps => 4 },
      { :length => 60, :steps => 6 },
    ]

    assumptions.each do |a|
      new_sprint.to_date = new_sprint.from_date + (a[:length] - 1).days
      chart = BurndownChart.new new_sprint
      assert_equal a[:steps], chart.label_step
    end
  end

  def test_ideal_burndown_boundaries_without_free_days
    @sprint.project.free_days = {}
    chart = BurndownChart.new @sprint, @sprint.to_date
    real = chart.values
    ideal = chart.ideal_values

    assert ideal.first > 0
    assert_equal @sprint.length, ideal.length
    assert_equal real.first, ideal.first
    assert_equal 0, ideal.last
  end

  def test_ideal_burndown_boundaries_with_sprint_ending_on_free_day
    @sprint.project.free_days = {
      @sprint.to_date.wday.to_s => true,
    }

    chart = BurndownChart.new @sprint, @sprint.to_date
    real = chart.values
    ideal = chart.ideal_values

    assert_equal(17, @sprint.length.to_i)
    assert ideal.first > 0
    assert_equal(9, ideal.first)
    assert_equal @sprint.length, ideal.length
    assert_equal real.first, ideal.first
    assert_equal 0, ideal.last.to_i
  end

  def test_ideal_burndown_boundaries_with_sprint_starting_on_free_day
    @sprint.project.free_days = {
      @sprint.from_date.wday.to_s => true,
    }

    chart = BurndownChart.new @sprint, @sprint.to_date
    real = chart.values
    ideal = chart.ideal_values

    assert ideal.first > 0
    assert_equal @sprint.length, ideal.length
    assert_equal real.first, ideal.first
    assert_equal 0, ideal.last.to_i
  end

  def test_ideal_burndown_boundaries_with_sprint_starting_and_ending_on_free_day
    @sprint.project.free_days = {
      @sprint.from_date.wday.to_s => true,
      @sprint.to_date.wday.to_s => true,
    }

    chart = BurndownChart.new @sprint, @sprint.to_date
    real = chart.values
    ideal = chart.ideal_values

    assert ideal.first > 0
    assert_equal @sprint.length, ideal.length
    assert_equal real.first, ideal.first

    assert_equal 9, ideal.first
    assert_in_delta(0, ideal.last, 10 ** -3)
  end

  def test_ideal_burndown_slope
    @sprint.project.free_days = {}
    chart = BurndownChart.new @sprint, @sprint.to_date
    ideal = chart.ideal_values

    assert @sprint.length > 1
    expected_slope = chart.values.first.to_f / (@sprint.length.to_f - 1)
    (1...@sprint.length).each do |day|
      assert_equal expected_slope, ideal[day-1] - ideal[day]
    end
  end

  def test_burndown_data_for_whole_sprint
    sprint = sprints(:sprint_with_assigned_tasks)

    # Start with 0 and don't include values past sprint boundaries
    expected = [
      [ "2007-01-06".to_date, 9 ],
      [ "2007-01-07".to_date, 9 ],
      [ "2007-01-08".to_date, 9 ],
      [ "2007-01-09".to_date, 9 ],
      [ "2007-01-10".to_date, 9 ],
      [ "2007-01-11".to_date, 9 ],
      [ "2007-01-12".to_date, 9 ],
      [ "2007-01-13".to_date, 9 ],
      [ "2007-01-14".to_date, 9 ],
      [ "2007-01-15".to_date, 16 ],
      [ "2007-01-16".to_date, 16 ],
      [ "2007-01-17".to_date, 16 ],
      [ "2007-01-18".to_date, 16 ],
      [ "2007-01-19".to_date, 16 ],
      [ "2007-01-20".to_date, 10 ],
      [ "2007-01-21".to_date, 10 ],
      [ "2007-01-22".to_date, 9 ],
    ]
    assert_equal expected, BurndownChart.new(sprint).chart_data
  end

  def test_partial_burndown
    sprint = sprints(:sprint_with_assigned_tasks)

    # All values past a given date are treated as an unknown future (nil)
    expected = [
      [ "2007-01-06".to_date, 9 ],
      [ "2007-01-07".to_date, 9 ],
      [ "2007-01-08".to_date, 9 ],
      [ "2007-01-09".to_date, 9 ],
      [ "2007-01-10".to_date, nil ],
      [ "2007-01-11".to_date, nil ],
      [ "2007-01-12".to_date, nil ],
      [ "2007-01-13".to_date, nil ],
      [ "2007-01-14".to_date, nil ],
      [ "2007-01-15".to_date, nil ],
      [ "2007-01-16".to_date, nil ],
      [ "2007-01-17".to_date, nil ],
      [ "2007-01-18".to_date, nil ],
      [ "2007-01-19".to_date, nil ],
      [ "2007-01-20".to_date, nil ],
      [ "2007-01-21".to_date, nil ],
      [ "2007-01-22".to_date, nil ],
    ]
    assert_equal expected, BurndownChart.new(sprint, "2007-01-09".to_date).chart_data
  end

  def test_empty_burndown_if_no_tasks
    sprint = sprints(:sprint_one)

    expected = (sprint.from_date..sprint.to_date).map { |day| [day, 0] }
    assert_equal expected, BurndownChart.new(sprint).chart_data
  end

  def test_counting_estimates_from_before_assigning_to_sprint
    sprint = Sprint.new(:name => "dudu", :from_date => Date.today, :to_date => Date.today + 14, :project => projects(:bananorama))
    sprint.save!
    item = Item.new(:user_story => "It", :estimate => 5, :project => projects(:bananorama))
    item.save!
    task = Task.new(:summary => "Do.", :estimate => 4, :item => item)
    task.save!
    assert task.task_logs.blank?
    item.sprint = sprint
    item.save!
    first_log = task.task_logs.find(:first, :conditions => { :sprint_id => sprint })
    assert_equal 4, first_log.estimate_new
    assert_equal nil, first_log.estimate_old
    expected = (sprint.from_date..sprint.to_date).map { |day| [day, 4] }
    assert_equal expected, BurndownChart.new(sprint).chart_data
  end

  def test_estimate_changes_before_sprint
    project = projects(:bananorama)
    date = "2008-06-08".to_date
    Date.stubs(:today).returns(date)
    Time.stubs(:now).returns(date.to_time)

    sprint = project.sprints.create(:name => "dudu", :from_date => date+2, :to_date => date+4)
    item = project.items.create(:user_story => "As user...", :estimate => 5)
    task = item.tasks.create(:summary => "None", :estimate => 10)

    item.sprint = sprint
    item.save

    task.estimate = 5
    task.save

    expected = [
      [ date+2, 5 ],
      [ date+3, 5 ],
      [ date+4, 5 ],
    ]

    assert_equal expected, BurndownChart.new(sprint).chart_data
  end

  def test_counting_dropped_items
    sprint = sprints(:sprint_with_dropped_item)

    expected = [
      [ "2007-01-10".to_date, 10 ],
      [ "2007-01-11".to_date, 10 ],
      [ "2007-01-12".to_date, 0 ],
      [ "2007-01-13".to_date, 0 ],
    ]

    assert_equal expected, BurndownChart.new(sprint).chart_data
  end

end

