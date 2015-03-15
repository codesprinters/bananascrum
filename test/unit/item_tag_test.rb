require File.dirname(__FILE__) + '/../test_helper'

class BacklogItemTagTest < ActiveSupport::TestCase
  fixtures :tags, :projects, :backlog_elements

  def setup
    super
    Domain.current = domains :code_sprinters
  end
  
  def teardown
    super
    Domain.current = nil
    User.current = nil
  end

  context 'A backlog item instance' do
    setup do
      @item = backlog_elements(:item_with_task)
      @tag = tags(:banana_two)
    end

    should 'have unique item_tag' do
      bt = ItemTag.new
      bt.item = @item
      bt.tag = @tag

      bt.save!

      bt = ItemTag.new
      bt.item = @item
      bt.tag = @tag

      assert ! bt.valid?
    end
  end
end
