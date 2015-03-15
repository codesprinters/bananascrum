require File.dirname(__FILE__) + '/../test_helper'

class DummyClass1 < ActiveRecord::BaseWithoutTable
  column :should_fail, :boolean
  column :some_text, :string
  
  validate :fail_when_it_should
  
  def fail_when_it_should
    if self.should_fail
      errors.add(:should_fail, "it fails")
      return false;
    end
  end
  
  def save
    return self.valid?
  end
end

class DummyClass2 < ActiveRecord::BaseWithoutTable
  column :some_other_text, :string
end

class PresenterClass < Presenter
  def_delegators :dummy1, :should_fail, :should_fail=, :some_text, :some_text=
  def_delegators :dummy2, :some_other_text, :some_other_text=

  def dummy1
    @dummy1 ||= DummyClass1.new
  end

  def dummy2
    @dummy2 ||= DummyClass2.new
  end

  def objects
    [ dummy1, dummy2 ]
  end
  
  def save
    return self.valid?
  end
end


class UserTest < ActiveSupport::TestCase
  context "Class inheriting from Presenter with proper fields" do
    setup do 
      @presenter = PresenterClass.new({
        :should_fail => false,
        :some_text => "text1",
        :some_other_text => "text2"
      })
    end
    
    should "pass validation" do
      assert @presenter.valid?
    end
    
    should "have the text typed" do
      assert_equal "text1", @presenter.some_text
      assert_equal "text1", @presenter.dummy1.some_text
      assert_equal "text2", @presenter.some_other_text
      assert_equal "text2", @presenter.dummy2.some_other_text
    end
    
    should "save" do
      assert @presenter.save
    end
  end
  
  context "Class inheriting from Presenter with errors" do
    setup do 
      @presenter = PresenterClass.new({
        :should_fail => true,
        :some_text => "text1",
        :some_other_text => "text2"
      })
    end
  
    should "be invalid" do
      assert !@presenter.valid?
    end
    
    should "have error on invalid column" do
      @presenter.valid?
      assert_not_nil @presenter.errors.on(:should_fail)
      
      assert_match /it fails/, @presenter.errors.on(:should_fail)
    end
    
    should "not save" do
      assert !@presenter.save
    end
    
  end
end