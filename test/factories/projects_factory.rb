Factory.sequence(:project_name) {|i| "project_#{i}" }

Factory.define(:project) do |p|
  p.name { Factory.next(:project_name) }
  p.presentation_name {|p| p.name.gsub("_", " ").camelize }
  p.description "Some description"
  p.time_zone "London"
  p.free_days { { '0' => '1', '6' => '1' } }
  p.estimate_sequence { ",0,0.5,1,2,3,5,8,13,20,40,100,9999" }
end

Factory.define(:project_fake, :parent => :project) do |p|
  p.presentation_name { Faker::Company.name }
  p.name { Faker::Internet.domain_word }
  p.description { Faker::Lorem.sentence(10) }
  p.estimate_sequence { ",0,0.5,1,2,3,5,8,13,20,40,100,9999" }
end
