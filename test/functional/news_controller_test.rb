require File.dirname(__FILE__) + '/../test_helper'

class NewsControllerTest < ActionController::TestCase
  fixtures :domains, :users, :news
  should_include_check_ssl_filter

  def setup
    DomainChecks.disable do
      @controller = NewsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @domain = domains(:code_sprinters)
      @request.host = @domain.name + "." + AppConfig.banana_domain
      @banana = projects(:bananorama).name
      @user = users(:user_one)
      @request.session[:user_id] = @user.id
      News.all.each { |n| n.plan_news.create!(:plan => @domain.plan) }
    end
  end

  def test_dismiss_unread_xhr
    @request.session["unread_news"] = true
    xhr :post, :dismiss_unread
    
    DomainChecks.disable do
      assert_response :success
      assert_date_in_delta(Time.now, @user.reload.last_news_read_date, 1.minute)
    end
  end

end
