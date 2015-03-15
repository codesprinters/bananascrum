require File.dirname(__FILE__) + '/../../test_helper'

class ApplicationHelperTest < ActionView::TestCase
  include ApplicationHelper

  fixtures :users, :news
  def params
    @params
  end
  
  
  def test_url_per_role
    @params = Hash.new
    
    project = DomainChecks.disable{projects(:bananorama)}
    Domain.current = domains(:code_sprinters)
    User.current  = DomainChecks.disable{users(:user_one)}
    assert !project.get_user_roles(User.current).any? {|role| role.name == "Product Owner"}
    url = url_per_role(project)
    assert_not_nil url
    assert_match(/sprints/, url)
    
    User.current  = DomainChecks.disable{users(:banana_owner)}
    assert project.get_user_roles(User.current).any? {|role| role.name == "Product Owner"}
    url = url_per_role(project)
    assert_match(/items/, url)
  end
  
  def test_generate_menu
    @params = Hash.new
    
    Project.current = DomainChecks.disable{projects(:bananorama)}
    User.current  = DomainChecks.disable{users(:user_one)}
    
    Domain.current = domains(:code_sprinters)
    menu = generate_menu Project.current
    assert_not_nil menu
    assert_match(/<ul\b[^>]*>(.*?)<\/ul>/, menu)
    
    User.current = DomainChecks.disable{users(:janek)}
    menu = generate_menu Project.current
    assert_no_match(/<li class=\"current\"><a href=\"\/admin\">Admin<\/a><\/li>/, menu)
  end
  
  def test_login_info_content
    @params = Hash.new
    
    Project.current = DomainChecks.disable{projects(:bananorama)}
    User.current  = DomainChecks.disable{users(:user_one)}
    Domain.current = domains(:code_sprinters)
    
    content = login_info_content
    assert_not_nil content
    projects = Project.find_all_for(User.current)
    
    assert_match(/#{User.current.full_name}/, content)
    
    check_project_links(projects, User.current, content)
    
    
    User.current  = DomainChecks.disable{users(:janek)}
    content = login_info_content
    projects = Project.find_all_for(User.current)
    
    check_project_links(projects, User.current, content)
  end
  
  private
  
  # are there all projects to which user is assign to?
  def check_project_links(projects, user, content)
    projects.each do |p|
      roles = p.get_user_roles(user)
      if roles.any? {|role| role.name == "Product Owner"}
        assert_match(/projects\/#{p.name}\/items/, content)
      else
        assert_match(/projects\/#{p.name}\/sprints/, content)
      end
      assert_match(/#{p.presentation_name}/, content)
    end
  end
end
