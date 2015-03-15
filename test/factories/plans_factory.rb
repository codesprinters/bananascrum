Factory.sequence(:plan_no) { |p| "Plan no #{p}" }

Factory.define(:plan) do |p|
  p.name { Factory.next(:plan_no) }
  p.users_limit 10
  p.projects_limit 4
  p.mbytes_limit 200
  p.valid_from { 10.months.ago.to_date }
  p.public true
end

Factory.define(:free_plan, :parent => :plan) do |p|
  p.price nil
end

Factory.define(:paid_plan, :parent => :plan) do |p|
  p.price 100
end

Factory.define(:small_plan, :parent => :plan) do |p|
  p.users_limit 2
  p.projects_limit 2
  p.mbytes_limit 2
end

Factory.define(:plan_with_ssl, :parent => :plan) do |p|
  p.ssl true
end

Factory.define(:pay_pal_plan, :parent => :plan) do |p|
  p.name { "PayPal " + Factory.next(:plan_no) }
  p.ssl true
  p.valid_from 1.months.ago.to_date
  p.price 10.5
  p.timeline_view true
end

Factory.define(:plan_with_item_limit, :parent => :plan) do |p|
  p.name { "Limited items " + Factory.next(:plan_no) }
  p.ssl false
  p.timeline_view true
  p.items_limit 2
end
