require File.dirname(__FILE__) + '/../test_helper'

class NewsTest < ActiveSupport::TestCase
  def test_creation
    n = News.create(:text => "Some news text, possibly with <b>some</b> HTML")
    assert(News.exists?(n.id), "News not created")
    assert_not_nil n.expiration_date
  end

  def test_latest_for_plan
    news = News.find(:all).reject!{|m| m.expiration_date < Time.now}
    news.sort! { |a, b| b.created_at <=> a.created_at }
    plan = plans(:simple_plan)
    latest = News.latest_for_plan(plan)
    assert_nil latest
    
    news.each { |n| n.plan_news.create!(:plan => plan) }
    latest = News.latest_for_plan(plan)
    assert_not_nil latest
    assert_equal(news.first, latest)
    assert latest.expiration_date > Time.now
  end
  
  def test_create_with_setting_expiration_date
    n = News.create(:text => "Something", :expiration_date => 1.day.from_now)
    assert n.expiration_date < 2.day.from_now
  end
    
end
