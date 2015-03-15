class AdminPanelController < AdminBaseController
  helper :users, :admin
  
  def index
    prepare_users
    prepare_projects
  end
end
