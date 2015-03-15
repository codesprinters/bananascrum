class MarkFreePlanUsersAsSpamLovers < ActiveRecord::Migration
  def self.up
    execute("
      UPDATE users u
      INNER JOIN domains d on d.id = u.domain_id
      INNER JOIN plans p on p.id = d.plan_id
      SET u.like_spam = 1, u.service_updates = 1, u.new_offers = 1
      WHERE p.price is NULL")
  end
  
  def self.down
  end
end
