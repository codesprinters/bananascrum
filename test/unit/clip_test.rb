require File.dirname(__FILE__) + '/../test_helper'

class ClipTest < ActiveSupport::TestCase
  fixtures :sprints, :backlog_elements, :tasks, :task_logs, :projects, :users
  include ActionController::TestProcess

  def setup
    Domain.current = domains(:code_sprinters)
  end
  
  def teardown
    Domain.current = nil
    User.current = nil
  end
  
  def test_creating_attachment
    
    item = backlog_elements(:item_with_task)
    clip = item.clips.new
    clip.content = fixture_file_upload('files/cs.pdf', 'application/pdf')

    assert_not_nil clip.content_file_name
    assert clip.save

    # this should not be allowed.
    clip2 = item.clips.new
    clip2.content = fixture_file_upload('files/cs.pdf', 'application/pdf')
    assert_not_nil(clip.content_file_name)

    assert_equal(clip.content_file_name, clip2.content_file_name)
    assert_equal false, clip2.save

    # same name but in other backlog item
    other_item = backlog_elements(:item_with_nil_estimate)
    clip = other_item.clips.new
    clip.content = fixture_file_upload('files/cs.pdf', 'application/pdf')

    assert clip.save
  end

  def test_size_with_units
    expectations = [
      [ 100, "100B" ],
      [ 700, "700B" ],
      [ 1024, "1KB" ],
      [ 3070, "2KB" ],
      [ 1024*1024, "1MB" ],
      [ 3145730, "3MB" ],
    ]

    expectations.each do |e|
      att = Clip.new :content_file_size => e[0]
      assert_equal e[1], att.size_with_units
    end
  end
  
end
