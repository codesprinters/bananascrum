Factory.define :license do |l|
  l.entity_name { Faker::Company.name }
end

Factory.define(:company_license, :parent => :license) do |l|
  l.entity_name 'Code Sprinters'

  l.key <<LICENSE
===== LICENSE BEGIN =====
Q29kZSBTcHJpbnRlcnM=:
aU+O4jSqR3xTdrXJDOyJEcKweTdwdXmfzDeymv4R0JbyO4hoSM35Cg/7FUyFyo1/B3XCEm0mdRkRcmc2ZSpaBt5UWDHAjrZU/U7g1AMV1ijC1PwvrSsUIxn5cmP2HugL8p+uSciuNDZVP2Mm0Jnk3GNjzMMi5LO/9Ux0em/9N34=
===== LICENSE END =======
LICENSE
  l.valid_to nil
end

Factory.define(:personal_license, :parent => :license) do |l|
  l.entity_name 'John Doe'

  l.key <<LICENSE
===== LICENSE BEGIN =====
Sm9obiBEb2U=:MjAzMy0xMi0yMQ==
aAgZI42fnWrfL0ZKlDf2qgPLqrYy4ZI5c6lWcHlgNG1bMa4C6tSt5Ca1VFao6H2aumuvZLq4aCELEo6X64ZhAtptGIMkhjB1YcBuaOWMtVplQSMzLq0rhB3f3yiq9Yxkq6QVNnLKDtnplr/ODFzAWfkNoQzjuuLP2LMUw5XIgt0=
===== LICENSE END =======
LICENSE
  l.valid_to '2033-12-21'
end
