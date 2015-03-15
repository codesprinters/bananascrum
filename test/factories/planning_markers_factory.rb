Factory.define(:planning_marker) do |m|
  m.item_span { (1..5).to_a.choice() }
  m.position { Factory.next(:marker_position) }
end

Factory.sequence(:marker_position) { |i| i }
