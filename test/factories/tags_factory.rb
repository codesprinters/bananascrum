Factory.sequence(:tag_name) { |i| "Tag #{i}" }

Factory.define(:tag) do |tag|
  tag.name { Factory.next(:tag_name) }
  tag.description { "some description" }
end


