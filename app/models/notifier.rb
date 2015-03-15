class Notifier < ActionMailer::Base
  helper :notifier
  include ActionView::Helpers::NumberHelper

  def reset_password(user, key)
    @subject    = "Banana Scrum account verification."
    @body       = { :user => user, :key => key }
    @recipients = verify(user.email_address)
    @from       = AppConfig.home_mail
    @sent_on    = Time.current
    @headers    = {}
  end

  def admin_reset_password(user, key)
    @subject    = "Your password has been reset by admin"
    @body       = { :user => user, :key => key }
    @recipients = verify(user.email_address)
    @from       = AppConfig.home_mail
    @sent_on    = Time.current
    @headers    = {}
  end
  
   def new_user(user, key)
    @subject    = "Banana Scrum account verification."
    @body       = { :user => user, :key => key }
    @recipients = verify(user.email_address)
    @from       = AppConfig.home_mail
    @sent_on    = Time.current
    @headers    = {}
  end

  def roles_assigment(project, user, role = nil)
    roles = project.get_user_roles(user)
    role ||= roles.first 
    
    @subject    = "New role assignment for project #{project.presentation_name}"
    @body       = { :project => project, :user => user, :roles => roles, :new_role => role }
    @recipients = verify(user.email_address)
    @from       = AppConfig.home_mail
    @sent_on    = Time.current
    @headers    = {}
  end

  def role_withdrawal(project, user, role)
    roles = project.get_user_roles(user)

    @subject    = "Role withdrawal for project #{project.presentation_name}"
    @body       = { :project => project, :user => user, :removed_role => role, :roles => roles }
    @recipients = verify(user.email_address)
    @from       = AppConfig.home_mail
    @sent_on    = Time.current
    @headers    = {}
  end

  private

  def verify(recipients)
    return nil if recipients.nil?
    env = ENV['RAILS_ENV']
    if env.blank? || env == 'development' || env == 'staging'
      return AppConfig.development_mail
    else
      return recipients
    end
  end

end
