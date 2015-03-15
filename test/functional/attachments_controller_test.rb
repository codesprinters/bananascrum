require File.dirname(__FILE__) + '/../test_helper'
require 'attachments_controller'

class AttachmentsControllerTest < ActionController::TestCase
  fixtures :backlog_elements, :users, :projects, :domains
  
  def setup
    DomainChecks.disable do
      @controller = AttachmentsController.new
      @request = ActionController::TestRequest.new
      @response = ActionController::TestResponse.new
      @user = users(:simple_user)
      @domain = domains(:simple_domain)
      @banana = projects(:bananorama)
      @request.session[:user_id] = @user.id
      @request.host = @domain.name + "." + AppConfig.banana_domain
    end
    Juggernaut.stubs(:send_to_channels) # FIXME: replace this stubs with expectations diffrent for each action
  end

  context 'on POST to :create' do
    setup do
      Domain.current = @domain = Domain.find_by_name(AppConfig::default_domain)
      User.current = @user = @domain.users.first

      @request.session[:user_id] = @user.id
      @request.host = @domain.name + "." + AppConfig.banana_domain

      project = @domain.projects.select { |p| p.archived != true }.first
      item = Factory.create(:item, :project => project)
      content = uploaded_file("#{RAILS_ROOT}/test/fixtures/files/cs.pdf", "application/pdf")
      xhr :post, :create, :attachment => {:content => content}, :item_id => item.id, :project_id => item.project.name
    end

    should_respond_with :success
    should_change("the number of clips", :by => 1) { Clip.count }
  end
end
