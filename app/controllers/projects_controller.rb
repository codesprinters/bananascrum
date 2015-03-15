class ProjectsController < DomainBaseController

  def index
    @user = User.current
  end

end
