Factory.define(:invoice) do |i|
  i.issue_date Date.today
  i.transaction_id '1223456'
end
