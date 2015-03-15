# Base controller for all operations inside a single project
# Just a wrapper around ProjectAccessControl - *do not* add anything
# but this include here - the module must be fully usable outside this
# inheritance hierarchy
class ProjectBaseController < DomainBaseController
  protected
  include ProjectAccessControl
  around_filter :set_current_project
  around_filter :ensure_current_project_set
  before_filter :disallow_non_get_for_archived_projects
end
