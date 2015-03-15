class DataGenerator
  attr_reader :domain, :admin, :users, :projects, :sprints, :backlog_items

  def initialize
    @users = []
    @projects = []
    @tasks = []
    @sprints = []
    @backlog_items = []
    @tags = []
    @time = Time.now
  end

  def plan(users = 3, projects = 4, mbytes = 3, markers = false)
    @plan = Factory(:plan, :users_limit => users,
      :projects_limit => projects, :mbytes_limit => mbytes, :timeline_view => markers)
  end

  def domain
    @domain = Factory.build(:domain, :plan => @plan)

    Domain.current = @domain
    @domain.save
    
    @project = nil
    @backlog_item = nil
    @user = nil
    admin
    yield if block_given?
    @domain
  end

  def admin(opts = {})
    @admin = Factory(:admin, opts)
    if @project
      @project.add_user_with_role(@admin, Role.find_by_code('team_member'))
    end
    yield if block_given?
    @admin
  end

  def user
    @user = Factory(:user)
    User.current = @user
    @users << @user
    if @project
      @project.add_user_with_role(@user, Role.find_by_code('team_member'))
    end
    yield if block_given?
    @user
  end

  def user_fake
    @user = Factory(:user_fake)
    User.current = @user
    @users << @user
    if @project
      @project.add_user_with_role(@user, Role.find_by_code('team_member'))
    end
    yield if block_given?
    @user
  end

  def project(opts = {})
    @project = Factory(:project, opts)
    Time.zone = @project.time_zone
    @projects << @project
    yield if block_given?
    @project
  end

  def project_fake(opts = {})
    @project = Factory(:project_fake, opts)
    Time.zone = @project.time_zone
    @projects << @project
    yield if block_given?
    @project
  end

  def tags_fake(number)
    names = Faker::Lorem::words(number).uniq
    for name in names
      tag = @project.tags.create!(:name => name)
      @tags << tag
    end
  end

  def sprint(opts = {})
    opts = {:project => @project}.merge(opts)
    @sprint = Factory(:sprint, opts)
    @sprints << @sprint
    yield if block_given?
    @sprint
  end

  def sprint_ongoing(opts = {})
    opts = {:project => @project, :from_date => (@time - 3.days).to_date}.merge(opts)
    @sprint = Factory(:sprint, opts)
    @sprints << @sprint
    yield if block_given?
    @sprint
  end

  def sprint_old(&block)
    from = (@time - 14.days).to_date
    to = (@time - 4.days).to_date
    sprint(:from_date => from, :to_date => to, &block)
  end

  def backlog_item(opts = {})
    opts = {:project => @project, :sprint => @sprint, :position => 0}.merge(opts)
    @backlog_item = Factory(:item, opts)
    @backlog_items << @backlog_item
    yield if block_given?
    @backlog_item
  end

  def backlog_item_fake(opts = {})
    opts = {:project => @project, :sprint => @sprint, :position => 0}.merge(opts)
    @backlog_item = Factory(:item_fake, opts)
    if rand > 0.5
      @backlog_item.add_tag(@tags.rand)
    end
    @backlog_items << @backlog_item
    yield if block_given?
    @backlog_item
  end

  def backlog_item_not_estimated(&block)
    backlog_item(:estimate => nil, &block)
  end

  def backlog_item_fake_with_textile
    backlog_item_fake(:description => TEXTILE_DESC)
  end

  def backlog_item_estimated(est, &block)
    backlog_item(:estimate => est, &block)
  end

  def backlog_item_infinity(&block)
    backlog_item(:estimate => Item::INFINITY_ESTIMATE_REPRESENTATIVE, &block)
  end

  def task(opts = {})
    opts = {:item => @backlog_item}.merge(opts)
    opts[:task_users_attributes] = [ { :user => @user } ] if @user
    @task = Factory(:task, opts)
    @tasks << @task
    @task
  end

  def task_fake(opts = {})
    opts = {:item => @backlog_item}.merge(opts)
    opts[:task_users_attributes] = [ { :user => @user } ] if @user
    @task = Factory(:task_fake, opts)
    @tasks << @task
    randomize_task_logs(@task)
    @task
  end

  def task_estimated_fake(estimate)
    opts = {:item => @backlog_item, :estimate => estimate}
    opts[:task_users_attributes] = [ { :user => @user } ] if @user
    @task = Factory(:task_fake, opts)
    @tasks << @task
    @task
  end

  def task_estimated(num)
    task(:estimate => num)
  end

  def task_done
    task(:estimate => 0)
  end

  private

  def randomize_task_logs(task)
    estimate = task.estimate
    task.task_logs.each do |tl|
      tl.update_attribute(:timestamp, (@sprint.from_date + 5.hours))
    end
    from = (@sprint.from_date + 1.day).to_date
    if Date.today < @sprint.to_date
      to = Date.today
    else
      to = @sprint.to_date
    end
    (from..to).each do |date|
      new_est = estimate - rand(3)
      new_est = 0 if new_est < 0
      @sprint.task_logs.create(:task => task,
        :estimate_new => new_est,
        :estimate_old => estimate,
        :timestamp => date + 5.hours
      )
      estimate = new_est
    end
    # Silly way of not triggering before update
    Task.update_all(["estimate = ?", estimate], :id => task.id)
  end

  TEXTILE_DESC = %q[
h1. Assumenda

h2. Quia consectetur

* *Inventore* velit aut non.
* Molestiae ut cumque ullam. Dignissimos autem rem est et voluptatem iste optio
quia.

h2. Quia est quo voluptatum et est illum.

Sint tenetur dolorem suscipit. Consectetur mollitia quisquam dolor consequatur
dolore sunt. Eligendi similique assumenda aut nam exercitationem doloribus
accusamus.

# Dignissimos autem
# Atque quia iste distinctio aspernatur non quia consectetur.
# http://www.codesprinters.com

Ea blanditiis quas veritatis natus. *Eligendi maxime maiores aut.*
Doloribus nisi et esse dolor dolorem veritatis sequi. Non totam dolorem et quod
hic sapiente dolores. Quos maxime fuga voluptatum adipisci rerum sed voluptatem
voluptas. Nesciunt assumenda suscipit libero tempore dolor aut optio non.
  ]

end
