class SeleniumDataGenerator < DataGenerator
  def generate
    ensure_roles_exist
    ensure_theme_exist

    plan(nil, nil, nil, true)
    domain do
      Domain.default && Domain.default.delete # we have a default domain in initial database data, we need to get rid of it
      @domain.name = AppConfig::default_domain
      @domain.save!
            
      Factory.create(:company_license, :domain => @domain)
      project do
        users = (1..3).map { user }

        users << user do
          @user.theme = Theme.find_by_slug('blue')
          @user.save!
        end

        admin do
          @admin.theme = Theme.find_by_slug('blue')
          @admin.save!
        end

        @user = users[2]

        estimated_items(2)
        2.times { backlog_item_infinity }

        sprint_old do
          backlog_item { task_done }
          backlog_item { task_done }
        end

        sprint do
          
          @user = users[1]
          backlog_item do
            @backlog_item.add_tag("tag_1")
            @backlog_item.add_tag("tag_2")
            [10, 6, 8].each {|est| task_estimated(est) }
          end

          @user = users[0]
          backlog_item do
            @backlog_item.add_tag("tag_2")
            @backlog_item.add_tag("tag_3")
            2.times { task_done }
          end

          @user = nil
          backlog_item { 2.times { task } }

          estimated_items
        end
      end
    end

    plan(1, 1, 0)
    domain

    plan(nil, 1, 1)
    domain do
      10.times { user }
    end

    plan(1, nil, 1)
    domain do
      project
    end

    plan(1, 1, 0)
    domain do
      @admin.theme = Theme.find_by_slug('blue')
      @admin.save
    end

    plan(nil, 1, 1)
    domain do
      10.times { user }
      @admin.theme = Theme.find_by_slug('blue')
      @admin.save
    end

    plan(1, nil, 1)
    domain do
      project
      @admin.theme = Theme.find_by_slug('blue')
      @admin.save
    end
  end

  def estimated_items(order = 1)
    order.times do
      backlog_item_not_estimated do
        @backlog_item.add_tag("dont know")
      end
      backlog_item_estimated(1) do
        @backlog_item.add_tag("tag_1")
      end
      backlog_item_estimated(1) do
        task_estimated(8)
      end
      [0, 3, 5, 13].each do |i|
        backlog_item_estimated(i)
      end
    end
  end

  def ensure_roles_exist
    unless Role.exists?(:code => 'team_member')
      Factory(:team_member_role)
    end
    unless Role.exists?(:code => 'scrum_master')
      Factory(:scrum_master_role)
    end
    unless Role.exists?(:code => 'product_owner')
      Factory(:product_owner_role)
    end

  end

  def ensure_theme_exist
    unless Theme.exists?(:slug => 'blue')
      Rake::Task['db:populate:themes'].invoke
    end
  end

end