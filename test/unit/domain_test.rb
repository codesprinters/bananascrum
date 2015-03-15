require File.dirname(__FILE__) + '/../test_helper'

class DomainTest < ActiveSupport::TestCase

  should_have_db_column :trial_period_used, :type => 'boolean', :null => false, :default => false
  should_have_db_column :billing_agreement_status, :type => 'string'
  should_have_db_column :billing_profile_id, :type => 'string'
  def teardown
    Domain.current = nil
  end

  context 'A new Domain instance' do
    setup { @domain = Domain.new }
    subject { @domain }

    should_have_many :clips

    should "set name from sugesstion" do
      valid_names = ['lalala', 'a', 'code-sprint-ers']
      for name in valid_names
        @domain.suggested_name = name
        assert_equal name, @domain.name
      end
    end

    should "not set name if suggestion is not valid" do
      invalid_names = ["www.bs", "with space", '$fancy%pants*', '-', 'aaaa-', '-onp']
      old_name = @domain.name = 'old_name'
      for name in invalid_names
        @domain.suggested_name = name
        assert_not_equal name, @domain.name
        assert_equal old_name, @domain.name
      end
    end
  end

  context 'A Domain instance' do
    setup do
      Domain.current = @domain = Factory.build(:domain)
      @domain.save!
    end

    context 'with impediments, sprints, items, task, etc' do
      setup do
        Factory.create(:project, :domain => @domain)
        @user = Factory.create(:user, :domain => @domain)
        @project = Factory.create(:project, :domain => @domain)
        RoleAssignment.create!(:project => @project, :user => @user, :role => roles(:team_member))
        User.current = @user
        Factory.create(:impediment, :project => @project)
        @sprint = Factory.create(:sprint, :project => @project)
        
        2.times do 
          item = Factory.create(:item, :project => @project ) 
          task = Factory.create(:task, :item => item)
          task.assign_users([ @user ])
          item.add_tag('some tag')
          item.comments.create!(:text => "some comment", :user => @user)
        end
        2.times { Factory.create(:item, :project => @project, :sprint => @sprint ) }
      end
      
      should 'remove without any exceptions' do
        @domain.destroy
      end
    end

    context 'with clips' do
      setup do
        @project = Factory.create(:project, :domain => @domain)
        3.times { @project.items.create!(Factory.attributes_for(:item)) }

        5.times do |n|
          Clip.create!(:domain => @domain, :item => @project.items.rand,
            :content_file_name => "test_#{n}.pdf",
            :content_content_type => 'application/pdf',
            :content_file_size => 1.megabyte)
        end
      end

      should 'compute clips bytes' do
        assert_equal 5.megabytes, @domain.clips_bytes
      end

      should 'delete attached clip files' do
        Clip.any_instance.expects(:destroy_attached_files).times(5)
        assert_equal 5, @domain.clips.count
        @domain.destroy
        assert !Domain.exists?(@domain)
      end
    end
  end

end
