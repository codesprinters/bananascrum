Factory.define(:eur_rate) do |u|
  u.rate { 4.0050 }
  u.publish_date { 1.day.ago.to_date }
end
