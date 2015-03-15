require File.dirname(__FILE__) + '/../test_helper'

class BurnupChartTest < ActiveSupport::TestCase
  context 'BurnupChart' do
    setup do
      @logs = []
      @sprint = Factory.build(:sprint)
      @sprint.stubs(:task_logs).returns(@logs)
      @for_date = @sprint.from_date + 3.days
      @sprint_span = (@sprint.from_date)..(@sprint.to_date)
    end

    context 'time and data span' do
      should 'compute time span as sprint span' do
        chart = BurnupChart.new(@sprint)
        assert_equal @sprint_span, chart.sprint_span
      end

      should 'compute time span as sprint span with for_date' do
        chart = BurnupChart.new(@sprint, @for_date)
        assert_equal @sprint_span, chart.sprint_span
      end

      should 'compute data span as sprint span' do
        chart = BurnupChart.new(@sprint)
        assert_equal @sprint_span, chart.data_span
      end
      
      should 'compute data span with for_date applied' do
        data_span = @sprint.from_date..@for_date
        chart = BurnupChart.new(@sprint, @for_date)
        assert_equal data_span, chart.data_span
      end

      should 'data span should not be longer than time span' do
        @for_date = @sprint.to_date + 1.day
        chart = BurnupChart.new(@sprint, @for_date)
        assert_equal @sprint_span, chart.data_span
      end
    end


    should 'labels be well formated' do
      chart = BurnupChart.new(@sprint, @for_date)
      labels = @sprint_span.map { |date| date.strftime BurnChart::CHART_DATE_FORMAT }
      assert_equal labels, chart.labels
    end

    should 'compute delta and type and corectly' do
      chart = BurnupChart.new(@sprint)
      assert_equal [:rising, 0], chart.categorized_delta(nil, nil)
      assert_equal [:rising, 10], chart.categorized_delta(nil, 10)
      assert_equal [:rising, 7], chart.categorized_delta(1, 8)
      assert_equal [:removed, -10], chart.categorized_delta(10, nil)
      assert_equal [:falling, 5], chart.categorized_delta(10, 5)
    end

    context 'workload' do
      setup do
        compute_new_chart
      end

      should 'have entry for each sprint day' do
        len = @sprint_span.to_a.size
        assert_equal len, @chart.workload.size
      end

      should 'be initialy zero for each day' do
        assert @chart.workload.all? {|w| w.zero? }
      end

      should 'not be zero if sprint begin was changed' do
        log(1, nil, 20, @sprint.from_date - 2.days)
        compute_new_chart
        assert @chart.workload.all? {|w| w == 20 }
      end

      should 'rise if log added' do
        log(1, nil, 10)
        @chart.compute_chart
        assert @chart.workload.all? {|w| w == 10 }
      end

      should 'rise only by last log new estimate' do
        log(1, nil, 20)
        log(1, 20, 99)
        log(1, 99, 10)
        @chart.compute_chart
        assert @chart.workload.all? {|w| w == 10 }
      end

      should 'rise by first and second log if both have different task_id' do
        log(1, nil, 5)
        log(2, nil, 7)
        @chart.compute_chart
        assert @chart.workload.all? {|w| w == 12 }
      end

      should 'rise by first log if second is done day after' do
        log(1, nil, 20)
        next_day
        log(1, 99, 10)
        @chart.compute_chart
        assert @chart.workload.all? {|w| w == 20 }
      end

      should 'fall if task was removed on day following addition' do
        log(1, nil, 8)
        next_day
        log(1, 8, nil)
        @chart.compute_chart
        assert_equal @chart.workload.first, 8
        assert @chart.workload[1..-1].all? {|w| w == 0 }
      end

    end

    context 'work done' do
      setup do
        @data_span = @sprint.from_date..@for_date
        @chart = BurnupChart.new(@sprint, @for_date)
        @chart.compute_chart
      end

      should 'have entry for each day up to @for_date' do
        len = @data_span.to_a.size
        assert_equal len, @chart.work_done.size
      end

      should 'be initially zero' do
        assert @chart.work_done.all? {|w| w.zero? }
      end

      should 'count logs from before sprint start date' do
        log(1, nil, 10, @sprint.from_date - 3.days)
        log(1, 10, 5, @sprint.from_date - 2.days)
        compute_new_chart
        assert @chart.work_done.all? {|w| w == 5 }
      end

      should 'not rise if task was added on this day' do
        log(1, nil, 10)
        log(1, 10, 3)
        @chart.compute_chart
        assert @chart.work_done.all? {|w| w.zero? }
      end

      should 'not rise if task was removed on same day' do
        log(1, nil, 10)
        next_day
        log(1, 10, 5)
        log(1, 5, nil)
        @chart.compute_chart
        assert @chart.work_done.all? {|w| w.zero? }
      end

      should 'rise if estimate lowered on next day (after adding)' do
        log(1, nil, 7)
        next_day
        log(1, 7, 3)
        @chart.compute_chart
        assert_equal 0, @chart.work_done.first
        assert @chart.work_done[1..-1].all? {|w| w == 4 }
      end

      should 'never falls' do
        log(1, nil, 10)
        log(2, nil, 5)
        log(3, nil, 3)
        log(1, 10, 5)
        next_day
        log(1, 5, 6)
        log(2, 5, 10)
        log(2, 10, 7)
        next_day
        log(3, 3, nil)
        log(2, 7, 0)
        @chart.compute_chart
        work_done = @chart.work_done
        a = work_done.shift
        while b = work_done.shift
          assert a <= b
          a = b
        end
      end

    end

  end

  private

  # Fake log creator
  def log(task_id, estimate_old, estimate_new, timestamp = nil)
    timestamp = timestamp || @fixed_time || Time.now
    @logs << FakeLog.new(task_id, estimate_old, estimate_new, timestamp)
  end

  # Moves timestams of newly created logs
  def next_day
    @fixed_time = (@fixed_time || Time.now) + 1.day
  end

  def compute_new_chart
    @chart = BurnupChart.new(@sprint)
    @chart.compute_chart
  end
  
  # Testing gadget
  class FakeLog
    attr_accessor :task_id, :estimate_old, :estimate_new, :timestamp

    def initialize(task_id, estimate_old, estimate_new, timestamp = Time.now)
      @task_id = task_id
      @estimate_old = estimate_old
      @estimate_new = estimate_new
      @timestamp = timestamp
    end
  
    def timestamp_in_zone
      @timestamp.to_time.in_time_zone(Time.zone)
    end
  end
  
end