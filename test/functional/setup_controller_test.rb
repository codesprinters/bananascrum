require File.dirname(__FILE__) + '/../test_helper'

class SetupControllerTest < ActionController::TestCase

  def self.should_render_change_licese_view
    should_respond_with :success
    should_assign_to(:license) { @license }
    should_render_template :change_license
  end

  context 'Setup controller' do
    setup do
      Domain.current = Domain.default
      Domain.current.license.destroy
    end

    context 'with a valid license key' do
      setup do
        @license = Factory.create(:company_license, :domain => Domain.default)
      end

      context 'on GET to :change_license' do
        setup { get :change_license }
        should_redirect_to('root path') { root_path }
      end
    end

    context 'without a valid license key' do
      setup do
        @license = Factory.create(:company_license, :domain => Domain.default)
        @license.update_attribute(:key, "wrong")
      end

      context 'on GET to :change_license' do
        setup { get :change_license }
        should_render_change_licese_view
        should "render valid HTML" do
          assert_select "input#license_entity_name"
        end
      end

      context 'on GET to :change_license without current license' do
        setup do
          License.delete_all
          @license = License.new(:domain => Domain.default)
          License.expects(:new).returns(@license)
          get :change_license
        end

        should_render_change_licese_view
      end

      context 'on POST to :change_license' do
        setup { post :change_license, :license => Factory.attributes_for(:company_license) }

        should_assign_to(:license) { @license }
        should_set_the_flash_to('License information updated')
        should_respond_with(:redirect)
        should_redirect_to('admin panel') { admin_panel_path }
      end
    end

    context 'with existing license and valid license' do
      setup do
        @license = Factory.create(:company_license, :domain => Domain.default)
        @admin = Factory.create(:admin, :domain => Domain.default)
      end
      
      context 'on GET to :first_admin' do
        setup { get :first_admin }
        should_respond_with :redirect
      end

      context 'with invalid entity_name' do
        setup { @license.update_attribute(:entity_name, 'Dog Springer') }

        context 'on GET to :change_license' do
          setup { get :change_license }
          should_render_change_licese_view
        end
      end
    end

    context 'with no admin' do
      setup do 
        users = mock
        users.stubs(:admins).returns(Array.new)
        Domain.any_instance.stubs(:users).returns(users)
      end
      
      context 'on GET to :first_admin' do
        setup { get :first_admin }

        should_respond_with :success
        should_assign_to :admin
        should_render_template :first_admin
      end

      context 'on POST to :first_admin' do
        setup { post :first_admin, :admin => Factory.attributes_for(:admin) }

        should_assign_to(:admin)
        should_set_the_flash_to('Setup was completed')
        should_redirect_to('admin panel') { admin_panel_path }
      end
    end
  end

end
