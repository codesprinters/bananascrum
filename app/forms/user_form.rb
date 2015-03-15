class UserForm < Presenter

  def_delegators :user, :login, :login=, :first_name, :first_name=, :last_name, :last_name=, :email_address, :email_address=, :like_spam, :like_spam=, :note_for_user, :note_for_user=, :theme_id, :theme_id=, :date_format_preference, :date_format_preference=
  def_delegators :user_assignment_fields, :roles_to_assign, :roles_to_assign=, :projects_to_assign, :projects_to_assign=, :to_assign, :to_assign=
  
  def user
    @user ||= User.new
    @user.theme = Theme.first
    @user
  end
  
  def user_assignment_fields
    @user_assignment_fields ||= begin 
      fields = UserAssignmentFields.new
      fields.user = user
      fields
    end
  end
  
  def objects
    [ user, user_assignment_fields ]
  end
  
end