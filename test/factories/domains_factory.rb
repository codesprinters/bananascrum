Factory.sequence(:domain_name) {|i| "testdomain#{i}" }

Factory.define(:domain) do |d|
  d.name { Factory.next(:domain_name) }
  d.full_name {|d| d.name }
  d.plan_id { Plan.find_by_name(Plan::NO_LIMIT_PLAN_NAME).try(:id) }
end
