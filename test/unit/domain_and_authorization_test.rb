require File.dirname(__FILE__) + '/../test_helper'

class DomainAndAuthorizationTest < ActiveSupport::TestCase

  class UnderTestController < ApplicationController
    protected
    include DomainAndAuthorization
  end

  context "before filter for ssl check" do
    setup do
      @controller = UnderTestController.new
      @request    = ActionController::TestRequest.new
      @controller.expects(:request).at_least_once.returns(@request)
    end

    context "with enabled ssl in AppConfig" do
      setup do
        AppConfig.expects(:ssl_enabled).at_least_once.returns(true)

        @domain = Domain.new
        @plan = Plan.new
        @domain.expects(:plan).at_least_once.returns(@plan)
        Domain.current = @domain
      end

      context "with plan with enabled ssl" do
        setup { @plan.expects(:ssl?).at_least_once.returns(true) }

        context "on http request" do
          setup { perform_http_request }
          should_redirect_to_https_protocol
        end

        context "on https request" do
          setup { perform_https_request }
          should_not_redirect
        end
      end

      context "with plan with disabled ssl" do
        setup { @plan.expects(:ssl?).at_least_once.returns(false) }

        context "on http request" do
          setup { perform_http_request }
          should_not_redirect
        end

        context "on https request" do
          setup { perform_https_request }
          should_redirect_to_http_protocol
        end
      end
    end

    context "with disabled ssl in AppConfig" do
      setup do
        AppConfig.expects(:ssl_enabled).at_least_once.returns(false)
        # there is no need to check domain's plan
        @domain.expects(:plan).never
      end

      context "on http request" do
        setup { perform_http_request }
        should_not_redirect
      end

      context "on https request" do
        setup { perform_https_request }
        should_redirect_to_http_protocol
      end
    end

  end

  protected

  def perform_https_request
    @request.expects(:ssl?).at_least_once.returns(true)
  end

  def perform_http_request
    @request.expects(:ssl?).at_least_once.returns(false)
  end

end
