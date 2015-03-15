class UserFormWithPasswordAssignment < UserForm 
  def_delegators :user, :user_password, :user_password=, :user_password_confirmation, :user_password_confirmation=
  
  def initialize(params = {})
    super(params)
    self.user.password_changed = true
  end
  
end