require File.dirname(__FILE__) + '/../test_helper'

class DataGeneratorTest < ActiveSupport::TestCase
  context "a" do
    setup do
      Domain.current = nil
      User.current = nil
      @gen = DataGenerator.new
      @gen.plan
    end

    context 'generating domain' do
      setup { Domain.current = @gen.domain }

      should_change("Number of domains") { Domain.count }
      should_change("Number of admins") { Admin.count }

      context 'generating users' do
        setup { @gen.user }

        should_change("Number of users") { User.count }
      end

      context 'generating projects' do
        setup do
          @gen.project
          @gen.user # for having user (also as User.current)
        end

        should_change("Number of projects") { Project.count }

        context 'generating backlog items' do
          setup { @gen.backlog_item }

          should_change("Number of backlog elements") { BacklogElement.count }

          context 'generating tasks' do
            setup { @gen.task }
            
            should_change("Number of tasks") { Task.count }

          end

        end

        context 'sprint_old' do
          setup { @sprint = @gen.sprint_old }

          should 'set sprint date ok' do
            assert @sprint.to_date < Date.today
          end
        end
      end
    end
  end

  context 'quantitive test' do
    setup { test_scenario }

    should_change("Domain.count", :by => 1) { Domain.count }
    should_change("User.count", :by => 4) { User.count } # with domain admin
    should_change("Project.count", :by => 1) { Project.count }
    should_change("BacklogElement.count", :by => 5) { BacklogElement.count }
    should_change("Task.count", :by => 16) { Task.count }
  end

  def test_scenario
    generate = DataGenerator.new
    generate.plan(nil, nil, nil)
    generate.domain do
      generate.user
      generate.project do
        generate.user do
          2.times do
            generate.backlog_item do
              5.times do
                generate.task
              end
            end
          end
        end
        generate.sprint do
          generate.user do
            3.times do
              generate.backlog_item do
                2.times do
                  generate.task
                end
              end
            end
          end
        end
      end

    end
  end
end
