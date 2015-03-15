require File.dirname(__FILE__) + '/../test_helper'


class BulkItemCreatorTest < ActiveSupport::TestCase
  context 'BulkItemCreator' do 
    setup do
      DomainChecks.disable do
        @project = projects(:bananorama)
        Domain.current = @project.domain
        User.current = @project.domain.users.first
      end
      @creator = BulkItemCreator.new(@project)
    end

    should 'have project properyty' do
      assert @creator.project
      assert_equal "bananorama", @creator.project.name
    end

    context 'cutoff_separators method' do 
      should 'work' do
        assert_equal "some text", @creator.cutoff_separators("   some text")
        assert_equal "some text   ", @creator.cutoff_separators("   some text   ")
        assert_equal "some text", @creator.cutoff_separators(" -  some text")
        assert_equal "1.   some text", @creator.cutoff_separators("1.   some text")
        assert_equal "some text,393", @creator.cutoff_separators(" some text,393")
        assert_equal "some text,393", @creator.cutoff_separators(" + some text,393")
        assert_equal "some text,393", @creator.cutoff_separators(" # some text,393")
        assert_equal "+ some text,393", @creator.cutoff_separators(" #+ some text,393")
        assert_equal "some text,393", @creator.cutoff_separators(" * some text,393")
      end
    end

  
    context 'split estiamte method' do
      should 'work' do
        assert_equal ["text", 5.0], @creator.split_estimate("text, 5")
        assert_equal ["text 302", 5.0], @creator.split_estimate("text 302, 5")
        assert_equal ["text,with commas", 5.0], @creator.split_estimate("text,with commas, 5")
        assert_equal ["text,with commas", 0.5], @creator.split_estimate("text,with commas,0.5")
        assert_equal ["text,with commas, .5", nil], @creator.split_estimate("text,with commas, .5")
        assert_equal ["text,with commas, 1.5.3", nil], @creator.split_estimate("text,with commas, 1.5.3")
      end
    end

    context "parse method" do
      should "return proper one item" do 
        text = "As a user I want to be cool, and fancy,40\n task 1,6\n task 2"
        result = @creator.parse(text)
        assert result.is_a? Array
        assert_equal 1, result.length
        item = result.first
        assert item.is_a? Item
        assert_equal 40, item.estimate.to_i
        assert_equal 2, item.tasks.length
        assert_equal "As a user I want to be cool, and fancy", item.user_story
        assert_nil item.description
        assert_equal "task 1", item.tasks.first.summary
        assert_equal 6, item.tasks.first.estimate
        assert_equal "task 2", item.tasks.second.summary
        assert_equal 1, item.tasks.second.estimate

        assert_difference 'Item.count' do
          assert_difference 'Task.count', 2 do
            assert item.save
          end
        end
        item.tasks.reload
        assert_equal item, item.tasks.first.item
      end

      should "return proper two items" do 
        text = "As a user I want to be cool, and fancy,40\n task 1,6\n task 2\nThis is second story"
        result = @creator.parse(text)
        assert result.is_a? Array
        assert_equal 2, result.length
        assert result.first.is_a? Item
        assert_equal 2, result.first.tasks.length
        assert_equal 0, result.second.tasks.count 
        assert_nil result.second.estimate
        assert_nil result.second.description
        assert result.first.valid?
        assert result.second.valid?
      end

      should "ignore tasks without the story" do 
        text = " this is a task without a story\nAs a user I want to be cool,40\n task 1,6\n task 2\nThis is second story"
        result = @creator.parse(text)
        assert result.is_a? Array
        assert_equal 2, result.length
        assert result.first.is_a? Item
        assert_equal 2, result.first.tasks.length
        assert_equal 0, result.second.tasks.count 
        assert_nil result.second.estimate
        assert_nil result.second.description
        assert result.first.valid?
        assert result.second.valid?
      end

      should "return blank array for empty string" do
        text = ""
        result = @creator.parse(text)
        assert result.is_a? Array
        assert result.blank?
      end

      should "behave well with blank lines" do
        text = "As a user I want to be cool, and fancy,40\n task 1,6\n task 2\n\n\nThis is second story\nThis is another story\n -this is task\n\n -this should be ignored"
        result = @creator.parse(text)
        assert result.is_a? Array
        assert_equal 3, result.length
        assert_equal 1, result.last.tasks.length
        assert_equal "this is task", result.last.tasks.last.summary
        assert_equal 2, result.first.tasks.length
        assert_equal 0, result.second.tasks.length
      end

      should "take into account someone can use commas" do
        text = "As a user, I didn't know, I shouldn't use so many commas"
        result = @creator.parse(text)
        assert result.is_a? Array
        assert_equal 1, result.length
        assert_equal "As a user, I didn't know, I shouldn't use so many commas", result.first.user_story
        assert_nil result.first.estimate
        assert result.first.valid?
      end

      should "give defualt for incorrect task estimate" do
        text = "As a user I want to have something\n -task,with commas and stuff,7\n task with big estimate,100000" 
        result = @creator.parse(text)
        assert result.is_a? Array
        assert_equal 1, result.length
        assert_equal 2, result.first.tasks.length
        assert_equal 7, result.first.tasks.first.estimate
        assert_equal 1, result.first.tasks.last.estimate
      end

      should "cut very long user story" do
        text = "Very long user story, Very long user story, Very long user story, Very long user story, Very long user story, Very long user story, Very long user story, Very long user story, Very long user story, Very long user story, Very long user story, Very long user story, Very long user story"
        result = @creator.parse(text)
        assert result.is_a? Array
        assert_equal 1, result.length
        assert result.first.valid?
        assert_equal 255, result.first.user_story.length
      end
    end
  end
  
end
