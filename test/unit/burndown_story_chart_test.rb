require File.dirname(__FILE__) + '/../test_helper'

class BurndownStoryChartTest < ActiveSupport::TestCase

  context 'BurndownStoryChart' do 
    setup do
      Domain.current = @domain = Factory.create(:domain)
      User.current = Factory.create(:user)

      @project = Factory :project
      @start_date = 7.day.ago.to_date
      @sprint = Factory :sprint, :project => @project, :from_date => @start_date, :to_date => 7.day.from_now.to_date
      @chart = BurndownStoryChart.new(@sprint)
    end

    teardown do
      User.current = nil
      Domain.current = nil
    end

    context 'chart data' do
      setup do
        
        3.times do |index|
          item = Factory :item, :project => @project, :sprint => @sprint, :estimate => @project.estimate_choices[index + 2] #0.5, 1, 2 SP
          3.times do
            task = Factory :task, :item => item
            task.task_logs.each do |tl|
              tl.update_attribute(:timestamp, @start_date + 1.hour)
            end
          end
        end
      end
  
      should 'generate flat line for none job done' do
        data = @chart.compute_chart_data
        assert_chart_data(data) { |index| 3.5 }
      end
  
      context 'for task with 1SP finished on second day' do
        setup do
          item = @sprint.items.find_by_estimate('1')
          assert_not_nil item
          close_item_tasks(item, @sprint.from_date + 2.day + 5.hour)
        end
  
        should 'be 3.5 for first 2 days, later should be 2.5' do
          data = @chart.compute_chart_data
          assert_chart_data data do |index|
            index < 2 ? 3.5 : 2.5
          end
        end
  
        context 'and reopened on 4th day' do
          setup do 
            item = @sprint.items.find_by_estimate('1')
            assert_not_nil item
            task = item.tasks.first
            task.estimate = 3
            assert task.save
            task.task_logs.last.update_attribute(:timestamp, @sprint.from_date + 4.day + 5.hour)
          end
  
          should 'be 3.5 for first 2 days, later should be 2.5 till day 4 and 3.5 till the end' do
            data = @chart.compute_chart_data
            assert_chart_data data do |index|
              if index < 2
                3.5
              elsif index < 4
                2.5
              else
                3.5
              end
            end
          end
        end
      
        context 'and task with 2SP finished on 6th day' do
          setup do
            item = @sprint.items.find_by_estimate('2')
            assert_not_nil item
            close_item_tasks(item, @sprint.from_date + 6.day + 5.hour)
          end
  
          should 'be 3.5 for first 2 days, 2.5 till 6 day, 0.5 to the end' do
            data = @chart.compute_chart_data
            assert_chart_data data do |index|
              if index < 2
                3.5
              elsif index < 6
                2.5
              else
                0.5
              end
            end
          end

          should 'render chart data without errors' do
            # this isn't a proper test I know... but making asserts for format of output JSON seems to be painfull. At least I test if no exception is thrown
            assert_nothing_raised do
              @chart.render_data
            end
          end
  
          context 'calculated for present day' do
            setup do
              @chart = BurndownStoryChart.new(@sprint, Date.today)
            end
          
            should 'be 3.5 for first 2 days, 2.5 till 6 day, 0.5 untill present day, nil to the end' do
              data = @chart.compute_chart_data
              assert_chart_data data do |index|
                if index < 2
                  3.5
                elsif index < 6
                  2.5
                elsif index < 8
                  0.5
                else
                  nil
                end
              end
            end
          end
  
        end
      end
  
      context 'for sprint with backlog item with no tasks' do
        setup do
          Factory :item, :sprint => @sprint, :project => @project, :estimate => @project.estimate_choices[7] # 8SP
        end
    
        should 'treat this item as not done' do
          data = @chart.compute_chart_data
          assert_chart_data data do |index|
            11.5
          end
        end
      end
  
    end

    context 'Ideal burndown for sprint with 10 SP' do
      setup do
        Factory :item, :project => @project, :sprint => @sprint, :estimate => @project.estimate_choices[7] #8 SP
        Factory :item, :project => @project, :sprint => @sprint, :estimate => @project.estimate_choices[4] #2 SP
      end

      should 'return valid data' do
        data = @chart.ideal_burndown
        dates = nil
        assert_nothing_raised { dates = data.map(&:first) }
        working_count = dates[1..-1].reject{|day| [0, 6].include?(day.to_date.wday) }.length #ignore first day
        
        left = @sprint.items_estimated_effort
        delta = left.to_f / working_count
        assert_chart_data data do |index|
          left -= delta unless [0, 6].include?(dates[index].to_date.wday) || index == 0 
          sprintf("%2.1f", left)
        end
      end
    end
  end

  private
  def assert_chart_data(data, &expected_value_proc)
    assert data.is_a?(Array)
    assert_equal @sprint.length, data.length
    data.each_with_index do |row, index|
      assert row.is_a? Array
      assert_equal 2, row.length
      day = row.first
      value = row.last
      expected_value = expected_value_proc.call(index)
      assert_nothing_raised { day.to_date }
      assert day.to_date >= @sprint.from_date
      assert day.to_date <= @sprint.to_date
      assert_equal expected_value, value, "at index #{index}"
    end
  end

  def close_item_tasks(item, timestamp)
    item.tasks.each do |task|
      task.estimate = 0
      assert task.save
      task.task_logs.last.update_attribute(:timestamp, timestamp)
    end
  end
end
