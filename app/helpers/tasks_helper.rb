module TasksHelper
  def user_asignment_json_hash(project = Project.current)
    team_members = project.team_members
    i = -1
    obj = team_members.map { |user| { :label => user.login, :value => user.id, :name => "task[task_users_attributes][#{i += 1}][user_id]" } }
    obj.to_json
  end

  def get_users_logins(task)
    users = task.users
    users = users.length > 0 ? users : [ { :login => "unassigned" } ] 
    list = users.map do |user| 
      "<span class='user-login'>#{h user[:login]}</span>"
    end
    list.join(', ')
  end

end
