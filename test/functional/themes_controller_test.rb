require File.dirname(__FILE__) + '/../test_helper'

class ThemesControllerTest < ActionController::TestCase
  fixtures :themes

  def setup
    super
    @controller = ThemesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    @request.host = 'example.com'
    @theme = themes(:blue)
  end

  def test_get_css_format
    get :show, :slug => @theme.slug, :format => 'css'
    assert_response 200
    assert_match 'text/css', @response.headers['Content-Type']
  end

  def test_get_non_css_format
    assert_raise ActionController::RoutingError do
      get "/themes/#{@theme.slug}.html"
    end
  end
end
