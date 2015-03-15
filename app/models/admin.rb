class Admin < User
  # we want all projects to be visible for admin, including archived
  def projects
    self.domain.projects
  end
end
