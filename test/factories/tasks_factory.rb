Factory.sequence(:task_name) {|i| "Task #{i}" }

Factory.define(:task) do |t|
  t.summary { Factory.next(:task_name) }
  t.estimate 4
end

Factory.define(:task_fake, :parent => :task) do |t|
  t.summary { Faker::Lorem.sentence(5)}
  t.estimate { rand(16) }
end
