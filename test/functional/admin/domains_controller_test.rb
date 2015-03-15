require File.dirname(__FILE__) + '/../../test_helper'

class Admin::DomainsControllerTest < ActionController::TestCase
  should_include_check_ssl_filter

  context "Should route posts to domain update action" do
    should_route(:put, '/admin/domain', :action => 'update')
  end

  context "Domain controller's" do
    setup do
      DomainChecks.disable do
        Domain.current = @domain = Domain.find_by_name(AppConfig::default_domain)
        @domain.save!
        @user = users(:admin)
      end

      @request.host = @domain.name + "." + AppConfig.banana_domain
      @request.session[:user_id] = @user[:id]
    end

    context "post on update with ajax request and full name" do
      setup do
        xhr :post, :update, :domain => { :full_name => 'xhrziazia' }, :format => 'json'
      end

      should_respond_with :success
      should 'update domain full name' do
        assert_equal 'xhrziazia', @domain.reload.full_name
      end
    end
  end
end
