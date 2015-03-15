Factory.define :role do |r|
end

Factory.define :team_member_role, :parent => :role do |r|
  r.code 'team_member'
  r.name 'Team Member'
end

Factory.define :product_owner_role, :parent => :role do |r|
  r.code 'product_owner'
  r.name 'Product Owner'
end

Factory.define :scrum_master_role, :parent => :role do |r|
  r.code 'scrum_master'
  r.name 'Scrum Master'
end
