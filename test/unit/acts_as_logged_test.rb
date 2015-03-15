require File.dirname(__FILE__) + '/../test_helper'

class ActsAsLoggedTest < ActiveSupport::TestCase

  def setup
    Domain.current = @domain = domains(:code_sprinters)
    Project.current = @project = projects(:bananorama)
    User.current = users(:user_one)
  end

  context 'logs for Sprint' do
    setup do
      @sprint = Factory.build(:sprint, :project => @project, :domain => @domain)
    end

    should 'write log for creation' do
      assert @sprint.save

      log = @sprint.logs.of_create.first
      assert log
      assert_equal User.current, log.user
      assert_equal 'Sprint', log.logable_type
      assert_equal 'create', log.action

      field = log.fields.for('name')
      assert field
      assert_equal 'name', field.name
      assert_nil field.old_value
      assert_equal @sprint.name, field.new_value

      field = log.fields.for('goals')
      assert field
      assert_equal 'goals', field.name
      assert_nil field.old_value
      assert_equal @sprint.goals, field.new_value
    end

    should 'write log for update' do
      assert @sprint.save
      old_attributes = @sprint.attributes
      assert @sprint.update_attributes!(:name => 'A new name', :goals => 'New goals')

      log = @sprint.logs.of_update.first
      assert log
      assert_equal User.current, log.user
      assert_equal 'Sprint', log.logable_type
      assert_equal 'update', log.action

      field = log.fields.for('name')
      assert field
      assert_equal old_attributes['name'], field.old_value
      assert_equal @sprint.name, field.new_value

      field = log.fields.for('goals')
      assert field
      assert_equal old_attributes['goals'], field.old_value
      assert_equal @sprint.goals, field.new_value
    end

    should 'write log for destroy' do
      assert @sprint.save
      assert @sprint.destroy

      log = Log.of_delete.first
      assert log
      assert_equal User.current, log.user
      assert_equal 'Sprint', log.logable_type
      assert_equal 'delete', log.action

      field = log.fields.for('name')
      assert field
      assert_equal @sprint.name, field.old_value

      field = log.fields.for('goals')
      assert field
      assert_equal @sprint.goals, field.old_value
    end

    context 'with dummy extra fields for logging' do
      setup do
        @sprint = Factory.build(:sprint, :project => @project, :domain => @domain)

        @sprint.expects(:extra_logged_fields).returns(['foo'])
        @sprint.expects(:foo).returns('bar' + @sprint.name + @sprint.goals)
      end

      should 'log extra fields' do
        assert @sprint.save
        
        log = @sprint.logs.last
        assert log

        field = log.fields.for('name')
        assert field
        assert_equal @sprint.name, field.new_value

        field = log.fields.for('foo')
        assert field
        assert_equal 'bar' + @sprint.name + @sprint.goals, field.new_value
      end
    end
  end

  context 'logs for Item' do
    setup do
      @sprint = Factory.create(:sprint, :project => @project, :domain => @domain)
      @item = Factory.create(:item, :project => @project, :domain => @domain, :sprint => @sprint)
    end

    should 'write log for creation' do
      assert @item.save

      log = @item.logs.of_create.first
      assert log
      assert_equal @sprint, log.sprint
      assert_equal @item, log.item
    end
  end

end
