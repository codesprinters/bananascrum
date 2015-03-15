require File.dirname(__FILE__) + '/../test_helper'

class WorkLoadChartTest< ActiveSupport::TestCase

  context 'WorkLoadChart' do
    setup do
      Domain.current = @domain = Factory.create(:domain)
      User.current = Factory.create(:user, :domain => @domain)
      
      @project = Factory.create(:project, :domain => @domain)
      @sprint = Factory.create(:sprint, :domain => @domain, :project => @project)
    end

    teardown do
      User.current = nil
    end

    should 'raise exception for empty sprint' do
      @chart = WorkLoadChart.new @sprint
      assert_raise NotEnoughDataError do
        @chart.compute_chart
      end
    end

    context 'for sprint with data' do
      setup do
        @users = [1, 2 ,3].map { Factory.create(:user, :domain => @domain) }
        User.current = @users.first
        
        3.times do
          item = Factory.create(:item, :sprint => @sprint, :domain => @domain, :project => @project)
          5.times do 
            task = Factory.create(:task_fake, :item => item, :task_users_attributes => [ { :user => @users.rand } ], :domain => @domain)
          end
        end
        @sprint.reload
      end
        
      should 'have all the users from sprint in data' do
        @chart = WorkLoadChart.new @sprint
        @chart.compute_chart
  
        users = @sprint.users
        users.each do |user|
          assert @chart.labels.include? user.login.to_s
        end
        assert !@chart.labels.include?('unassigned')
      end
  
      should 'have unaasinged key if some tasks is unassigned' do
        some_task = @sprint.tasks.find(:first, :conditions => 'tasks.estimate > 0')
        assert_not_nil some_task
        some_task.task_users.destroy_all
        
        @chart = WorkLoadChart.new @sprint
        @chart.compute_chart
        
        assert @chart.labels.include?('unassigned')
        assert_equal some_task.estimate, @chart.values[@chart.labels.index('unassigned')]
      end
  
      should 'have 0 value for user who has finished tasks' do
        some_user = @sprint.users.first
        some_user.tasks.each do |task|
          task.estimate = 0
          task.save
        end
        
        @chart = WorkLoadChart.new @sprint
        @chart.compute_chart
  
        assert @chart.labels.include?(some_user.login.to_s)
        index = @chart.labels.index(some_user.login.to_s)
        assert_equal 0, @chart.values[index]
      end
  
      should 'have correct time left for each user' do
        @chart = WorkLoadChart.new @sprint
        @chart.compute_chart
        
        @sprint.users.each do |user|
          sum = @sprint.tasks.select{ |t| t.users.include?(user)}.map(&:estimate).sum
          assert @chart.labels.include?(user.login.to_s)
          index = @chart.labels.index(user.login.to_s)
          assert_equal sum, @chart.values[index]
        end
      end
    end
  end
end
