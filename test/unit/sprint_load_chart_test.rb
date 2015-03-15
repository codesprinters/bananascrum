require File.dirname(__FILE__) + '/../test_helper'

class SprintsLoadChartTest < ActiveSupport::TestCase

  context 'SprintsLoadChartTest' do
    context 'for blank sprints list' do
      setup do
        @chart = SprintsLoadChart.new
      end
  
      should 'render nice message' do
        data = @chart.render_data
        assert_match /No sprints to display/, data.to_json
      end
    end
    
    context 'for the list of sprints' do
      setup do 
        Domain.current = @domain = Factory.create(:domain)
        @project = Factory.create :project
        User.current = Factory.create :user
        
        @time = 50.days.ago.to_date
        4.times do 
          sprint = Factory.create :sprint, :project => @project,
            :from_date => @time.to_date, :to_date => (@time + 10.days).to_date
          5.times do 
            item = Factory.create :item, :sprint => sprint, :project => @project
            3.times do 
              task = Factory.create :task, :item => item, :estimate => 0
            end
          end
          @time += 11.days
        end
        
        @chart = SprintsLoadChart.new(@project.sprints.reload)
        @data = @chart.render_data
      end
      
      should 'have all the sprints as labels' do
        Domain.current = @domain
        
        assert_equal @project.sprints.count + 2, @chart.labels.length
        assert @chart.labels[1..-2].map{|s| s.match(/Sprint/)}.all?
        assert_equal 15, @chart.average_velocity_values.first
      end
    end
  end
end