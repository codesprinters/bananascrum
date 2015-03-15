Factory.sequence(:item_story) { |i| "User Story #{i}" }

Factory.define(:item) do |item|
  item.user_story { Factory.next(:item_story) }
  item.description "Backlog item description"
  item.estimate 3
end

Factory.define(:item_fake, :parent => :item) do |item|
  item.user_story { Faker::Company.catch_phrase }
  item.description { Faker::Lorem.paragraph(rand(7)) }
  item.estimate { Project::FIBONNACI_ESTIMATE[0..-2].rand }
end
