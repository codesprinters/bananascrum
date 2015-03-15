Factory.define(:plan_change) do |pc|
  pc.old_plan_id { Factory.create(:pay_pal_plan).id }
  pc.new_plan_id { Factory.create(:pay_pal_plan).id }
  pc.pending true
end
