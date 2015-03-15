namespace :debtors do
  desc "Goes trough all domains, looks for debtors and threatens them with email or block domains"
  task :threat => :environment do
    puts "Threatening debtors"
    finder = DebtorFinder.new
    finder.run
    puts finder.messages.join("\n")
    puts "Done"
  end
end
