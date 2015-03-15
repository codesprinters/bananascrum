Factory.define :news do |n|
  n.text { Faker::Lorem.paragraph }
  n.expiration_date { DateTime.now + 1.day }
end
