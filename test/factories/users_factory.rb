Factory.sequence(:user_login) {|i| "user_#{i}" }
Factory.sequence(:admin_login) {|i| "admin_#{i}" }

Factory.define(:user) do |u|
  u.login { Factory.next(:user_login) }
  u.user_password "password"
  u.email_address {|u| "%s@%s" % [u.login, "example.com"] }
  u.first_name "John"
  u.last_name "Doe"
  u.active true
end

Factory.define(:user_fake, :parent => :user) do |u|
  u.login { res = Faker::Internet.user_name; res.length > 2 ? res : Faker::Internet.user_name } #user_name return too short user_name one per 10000 times
  u.first_name { Faker::Name.first_name }
  u.last_name { Faker::Name.last_name }
end

Factory.define(:admin, :parent => :user) do |a|
  a.login { Factory.next(:admin_login) }
  a.add_attribute :type, "Admin"
end