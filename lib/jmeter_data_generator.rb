class JmeterDataGenerator < DataGenerator
  def generate
    ensure_roles_exist
    ensure_theme_exist
  
    plan(nil, nil, nil)


    500.times do
      domain
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