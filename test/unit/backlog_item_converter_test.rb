require File.dirname(__FILE__) + '/../test_helper'

require 'stringio'
require 'test/unit'

class BacklogItemConverterTest < ActiveSupport::TestCase
  fixtures :projects
  CSV_FIXTURES = File.join(RAILS_ROOT, 'test/fixtures/csv')

  context "BacklogItemConverter" do
    setup do
      Domain.current = domains(:code_sprinters)
      User.current = users(:user_one)
      Project.current = projects(:bananorama)
      @separator = Project.current.csv_separator
      @converter = BacklogItemConverter.new(Project.current, @separator)
    end

    context 'with empty csv' do
      should_not_change("Number of items") { Item.count }
      should_not_change("Number of tags") { Project.current.tags.length }

      should 'import zero items' do
        items, new_tags = @converter.import_csv(StringIO.new)
        assert_nil items
        assert_nil new_tags
      end
    end

    context 'csv with task with two users' do
      setup do
        @items, @new_tags = @converter.import_csv(csv_with_task_with_two_users)
      end
      
      should 'import 1 item' do
        assert_equal 1, @items.length
      end
      
      should 'have task with two users assigned' do
        assert_equal 1, @items.first.tasks.length
        task = @items.first.tasks.first
        assert_equal 2, task.users.length
        assert task.users.include?(users(:user_one))
        assert task.users.include?(users(:user_two))
      end
    end

    context 'with sample csv' do
      setup do
        @items, @new_tags = @converter.import_csv(csv_sample)
      end

      should 'import some csv' do
        assert_equal(2, @items.length)
        assert !@items.any? {|i| i.new_record? }
      end

      should 'set tags on items' do        
        tags = @items.first.tags
        assert_equal 4, tags.size
        for tag in tags
          assert !tag.new_record?
        end
      end
    end

    context 'sample csv with tasks' do
      setup { @items, @new_tags = @converter.import_csv(csv_sample_with_tasks)}

      should 'import csv file with tasks' do
        assert_equal(2, @items.length)
      end

      should 'set task on items'do
        assert_equal(2, @items.first.tasks.length)
        assert_equal(1, @items.second.tasks.length)
        @items.first.tasks.each do |task|
          assert !task.new_record?
        end
      end
    end

    should 'import task with only estimate' do
      items, new_tags = @converter.import_csv(csv_sample_tasks_with_only_estimate)
      items.each do |item|
        item.tasks.each do |task|
          assert_nil task.summary
          assert task.users.blank?
        end
      end
      assert_equal 4, new_tags.length
    end

    should 'ignore superfluous columns' do
      items = nil
      assert_nothing_raised(CSV::IllegalFormatError) do
        items, new_tags = @converter.import_csv(csv_with_too_many_column)
      end

      assert !items.first.new_record?
    end

    should 'import item with only user story' do
      item, new_tags = @converter.import_csv(csv_with_only_story)[0]
      assert_equal "Story", item.user_story
      assert item.description.nil? ||  item.description.blank?
      assert_nil item.estimate
      assert item.tags.empty?
    end


    should 'import item with only user story and estimate' do
      item, new_tags = @converter.import_csv(csv_with_only_story_and_estimate)[0]
      assert_not_nil item.estimate
      assert item.description.nil? ||  item.description.blank?
      assert item.tags.empty?
    end

    should 'export imported items' do
      items, new_tags = @converter.import_csv(csv_sample)
      csv = @converter.export_csv(items)
      assert_equal(csv_sample.read, csv.read.strip)
    end

    should 'import exported items' do
      items = Project.current.items.all(:conditions => { :sprint_id => nil})
      csv = @converter.export_csv(items)
      imported_items, new_tags = @converter.import_csv(csv)
      pairs = items.zip(imported_items)

      for item, imported_item in pairs
        [:user_story, :description, :estimate].each do |field|
          assert(item[field] == imported_item[field],
            "#{field} not equal: #{item[field]} != #{imported_item[field]}")
        end
      end
    end

    context 'import exported items with tasks' do
      setup do
        @project = Factory.create :project, :domain => Domain.current
        @users = Array.new
        3.times do
          @users << Factory.create(:user_fake, :domain => Domain.current)
        end
        task_users_attributes = @users.map { |u| { :user_id => u.id }}
        @items = Array.new
        5.times do
          item = Factory.create :item_fake, :project => @project
          item.add_tag(Factory.create :tag, :project => @project)
          @items << item
          3.times do
            item.tasks << Factory.create(:task_fake, :item => item, :task_users_attributes => task_users_attributes.shuffle[0..rand(task_users_attributes.length)])
          end 
        end
      end
    
      should 'return the same' do
        csv = @converter.export_csv(@items)
        imported_items, new_tags = @converter.import_csv(csv)
        pairs = @items.zip(imported_items)
  
        for item, imported_item in pairs
          assert_equal item.user_story, imported_item.user_story
          assert_equal item.description, imported_item.description
          assert_equal item.estimate, imported_item.estimate
          task_pairs = item.tasks.zip(imported_item.tasks)
  
          for item_task, imported_item_task in task_pairs
            assert_equal item_task.summary, imported_item_task.summary
            assert_equal item_task.estimate, imported_item_task.estimate
            assert_same_elements item_task.users, imported_item_task.users
          end
        end
      end
    end

    should 'not import invalid item' do
      items, new_tags = @converter.import_csv(csv_with_invalid_item)      
      assert items.empty?
    end

    should 'strip tags' do
      items, new_tags = @converter.import_csv(csv_with_not_stripped_tags)
      tags = items.map(&:tags).flatten
      tags_names = tags.map(&:name).sort
      assert_equal %w[tag1 tag2 tag3], tags_names
    end

    should 'escape chars in tags' do
      items, new_tags = @converter.import_csv(csv_with_tags_with_escaped_chars)
      tags = items.map(&:tags).flatten
      tags_names = tags.map(&:name).sort
      assert_equal %w[,% tag1 tag2 tag3,tag4], tags_names
    end

    should 'understand infinity item' do
      items, new_tags = @converter.import_csv(csv_with_infinity_estimate)      
      item = items.first
      assert item.infinity?
    end

    context 'with bad estimate' do
      setup { @items, @new_tags = @converter.import_csv(csv_with_bad_estimate)}

      should_change("Number of items") { Item.count }
      
      should 'set estimate to nil' do
        for item in @items
          assert_nil item.estimate
        end
      end      
    end

    should 'choose semicolon' do
      csv_file = File.new(File.join(CSV_FIXTURES, 'csv_with_semicolon_separator.csv'))
      until csv_file.eof?
        separator = @converter.detect_separator(csv_file)
        assert_equal ";", separator
      end
    end

    should 'choose comma' do
      csv_file = File.new(File.join(CSV_FIXTURES, 'csv_with_comma_separator.csv'))
      until csv_file.eof?
        separator = @converter.detect_separator(csv_file)
        assert_equal ",", separator
      end
    end

    should 'choose tab' do
      csv_file = csv_with_separator("\t")
      until csv_file.eof?
        separator = @converter.detect_separator(csv_file)
        assert_equal "\t", separator
      end
    end

    should 'choose comma from csv with long description' do
      csv_file = File.new(File.join(CSV_FIXTURES, 'csv_with_long_description.csv'))
      separator = @converter.detect_separator(csv_file)
      assert_equal ",", separator
    end

  end

  context 'TagConverter' do
    setup do
      @array = ['tag1', 'tag2', 'john,mary', '150%', ',%']
      @string = 'tag1,tag2,john%2cmary,150%25,%2c%25'
    end

    context 'instantiaded with string' do
      setup do
        @converter = BacklogItemConverter::TagConverter.new(@string)
      end

      should 'return escaped values' do
        values = @converter.to_a
        assert_equal @array.length, values.length
        values.each do |tag|
          assert @array.include?(tag)
        end
      end

      should 'be converted to escaped string' do
        assert_equal @string, @converter.to_s
      end
    end

    context 'instantiated with an array' do
      setup do 
        @converter = BacklogItemConverter::TagConverter.new(@array)
      end

      should 'return escaped values' do
        values = @converter.to_a
        assert_equal @array.length, values.length
        values.each do |tag|
          assert @array.include?(tag)
        end
      end

      should 'be converted to escaped string' do
        assert_equal @string, @converter.to_s
      end
    end
  end
  
  private

  def csv_sample
    StringIO.new([
        ["new_user_story", 1.0, "des", '"tag1,tag2,tag3,tag4"'].join(@separator),
        ["next_test", 1.0, "desc", 'tag1'].join(@separator)
      ].join("\n"))
  end

  def csv_sample_with_tasks
    StringIO.new([
        ["new_user_story", 1.0, "des", '"tag1, tag2, tag3, tag4"'].join(@separator),
        ['', '', '', '', "summary 1", 1, User.current.login].join(@separator),
        ['', '', '', '', "summary 2", 5].join(@separator),
        ["next_test", 1.0, "desc", 'tag1'].join(@separator),
        ['', '', '', '', "summary 3", 10, User.current.login].join(@separator)
      ].join("\n"))
  end

  def csv_with_task_with_two_users
    StringIO.new([
      ["new_user_story", 1.0, "des", '"tag1, tag2, tag3, tag4"'].join(@separator),
      ['', '', '', '', "summary 1", 1, "\"#{users(:user_one).login},#{users(:user_two).login}\""].join(@separator)
    ].join("\n"))
  end

  def csv_with_invalid_item
    StringIO.new(['', 5, "Simple item with description", "tag1,tag2"].join(@separator))
  end

  def csv_with_not_stripped_tags
    StringIO.new(['Story', 5, "Description", '"    tag2,     tag1    , tag3"'].join(@separator))
  end 

  def csv_with_tags_with_escaped_chars
    StringIO.new(['Story', 5, "Description", '"tag1, tag2, tag3%2ctag4, %2c%25"'].join(@separator))
  end

  def csv_with_infinity_estimate    
    StringIO.new(['Story', 'inf', 'Description'].join(@separator))
  end

  def csv_with_too_many_column
    StringIO.new(['Story', 5, "Desc", "tag1", "s1", "s2"].join(@separator))
  end

  def csv_with_only_story
    StringIO.new('Story,')
  end

  def csv_with_only_story_and_estimate    
    StringIO.new(['Story', '2'].join(@separator))
  end

  def csv_with_separator(separator)
    StringIO.new([
        ["Story0", "2", "desc", '"tag1,tag2"',"s1","s2"].join(separator),
        ["Story1", "ola", "desc", '"tag1,tag2"'].join(separator),
        ["Story2", "1", "desc"].join(separator),
        ["Story3", "5"].join(separator),
        ['"User, asdf, asdfasdf"', "5", '"Usraer, awerwerwe, erwerwe, asdfasdf"'].join(separator),
    ].join("\n"))
  end

  def csv_with_bad_estimate         
     StringIO.new([
        ["Story1", "ola", "desc"].join(@separator),
        ["Story2", "9", "desc"].join(@separator),
        ["Story3", "", "desc"].join(@separator),
      ].join("\n"))
  end

  def csv_sample_tasks_with_only_estimate
    StringIO.new([
        ["new_user_story", 1.0, "des", '"tag1, tag2, tag3, tag4"'].join(@separator),
        ['', '', '', '', '', 1].join(@separator),
        ['', '', '', '', '', 5].join(@separator),
        ["next_test", 1.0, "desc", 'tag1'].join(@separator),
        ['', '', '', '', '', 10].join(@separator)
      ].join("\n"))
  end

end
