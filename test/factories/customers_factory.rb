Factory.define :customer do |c|
  c.company  { false }
  c.name { Faker::Name.first_name }
  c.email { Faker::Internet.email }
  c.phone { 1234567 }
  c.mobile_phone { true }
  c.country { ['PL', 'US'].rand }
  c.city { Faker::Address.city }
  c.postcode { Faker::Address.zip_code }
  c.street_line1 { Faker::Address.street_suffix }
  c.tax_number { 123456 }
  c.dummy { false }
end

Factory.define(:company_customer, :parent => :customer) do |c|
  c.company true
  c.company_name 'Code Sprinters'
end

Factory.define(:personal_customer, :parent => :customer) do |c|
  c.company false
  c.first_name 'John'
  c.last_name 'Doe'
end
