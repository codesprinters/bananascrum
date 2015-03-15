module UsersHelper
  
  def admin_check_box(user)
    form_html = ""
    form_html += form_tag(admin_admin_user_path(user), :class => 'checkbox-form') 
    checked = user.admin? ? 'checked="checked"' : ''
    disabled = user == User.current ? 'disabled="disabled"' : ''
    form_html += "<input type=\"checkbox\" class=\"checkbox admin-user-checkbox\" name=\"user_admin\" #{checked} #{disabled} />"
    form_html += "</form>"
  end
  
  
  def block_arrow(user)
    klass = "block-user"
    klass += user.blocked? ? ' unblock' : ' block'
    klass += ' disabled' if user == User.current
    functional_link_to('', block_admin_user_path(user), :class => klass)
  end

  def archived_check_box(project)
    form_html = ""
    checked = project.archived ? 'checked="checked"' : ''
    form_html += form_tag(archive_admin_project_path(project.id), :class => 'checkbox-form') 
    form_html += "<input type=\"checkbox\" class=\"checkbox archive-project-checkbox\" name=\"project_archived\" #{checked} />"
    form_html += "</form>"
  end
  
  def project_assignment_hash(user, projects)
    i = -1
    projects.map { |project| { :label => project.presentation_name, :name => "form[projects_to_assign][#{i += 1}]", :value => project.id } }
  end
  
end
