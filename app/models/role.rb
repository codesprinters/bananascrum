class Role < ActiveRecord::Base
  has_many :role_assignments # let the FK cascade do the job, so no :dependent here
  validates_uniqueness_of :name, :code

  DEFAULTS = [
    { :code => "scrum_master", :name => "Scrum Master", :description => "Scrum Master" },
    { :code => "product_owner", :name => "Product Owner", :description => "Product Owner" },
    { :code => "team_member", :name => "Team Member", :description => "Team Member" },
    { :code => "idea_submitter", :name => "Idea Submitter", :description => "Idea Submitter" },
  ].freeze

  def self.reset_to_defaults
    Role.destroy_all
    DEFAULTS.each do |elem|
      role = Role.new(elem)
      role.save!
    end
  end
end
