Factory.define(:payment) do |p|
  p.status Payment::STATUSES[:unpaid]
  p.amount 100
  p.plan { Factory(:small_plan) }
end

Factory.define(:unpaid_payment, :parent => :payment) do |p|
  p.status Payment::STATUSES[:unpaid]
  p.from_date 2.months.ago
  p.to_date 1.month.ago
end

Factory.define(:paid_payment, :parent => :payment) do |p|
  p.status Payment::STATUSES[:paid]
  p.from_date 2.months.ago
  p.to_date 1.month.ago
end
