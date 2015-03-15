Factory.sequence(:sprints_name) { |i| "Sprint #{i}" }

Factory.define(:sprint) do |s|
  s.name { Factory.next(:sprints_name) }
  s.from_date { Date.today }
  s.to_date {|s| s.from_date + 14.days }
  s.goals { Faker::Company.bs }
end
