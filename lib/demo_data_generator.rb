class DemoDataGenerator < DataGenerator
  
  def initialize
    super
    find_or_create_demo_domain
  end

  def regenerate
    Domain.transaction do
      generate
    end
  end

  private

  def find_or_create_demo_domain
    @domain = Domain.find_by_name(AppConfig.demo_domain)

    DomainChecks.disable do
      @domain.destroy unless @domain.nil?
    end

    if !Plan.find_by_name("Demo")
      Plan.create!(:name => "Demo", :public => false, :price => nil, :timeline_view => true, :ssl => true, :items_limit => nil, :users_limit => nil, :valid_from => Time.now)
    end

    @plan = Plan.find_by_name("Demo")

    @domain = Factory.build(:domain, :name => AppConfig.demo_domain, :full_name => "Banana Scrum Demo", :plan => @plan)
    @domain.save!
    Domain.current = @domain
  end

  public
  
  def generate
    @time = 5.days.ago

    project_fake do
      tags_fake(5)
      
      admin(:login => 'admin', :theme => Theme.first)
      3.times { user_fake }

      backlog_item_fake_with_textile
      10.times { backlog_item_fake }
      
      @time = 60.days.ago
      5.times do
        sprint_old do
          4.times do
            @user = @users.rand
            backlog_item_fake do
              (rand(2)+1).times do
                @user = @users.rand
                task_fake
              end
            end
          end
        end
        @time += 11.days
      end
      @time = 5.days.ago

      sprint_ongoing do
        backlog_item_fake_with_textile
        5.times do
          backlog_item_fake do
            (rand(6)+3).times do
              @user = @users.rand
              task_fake
            end
          end
        end
        task_estimated_fake(20)
        task_estimated_fake(20)
      end

    end
    
  end
end
