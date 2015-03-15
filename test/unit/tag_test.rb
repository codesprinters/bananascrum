require File.dirname(__FILE__) + '/../test_helper'

class TagTest < ActiveSupport::TestCase
  fixtures :projects

  def setup
    Domain.current = domains(:code_sprinters)
    User.current = users(:user_one)
  end

  def teardown
    super
    Domain.current = nil
    User.current = nil
  end
  
  def test_validity_constraints
    t = Tag.new
    t.name = 'NowyTag'
    t.project = projects(:bananorama)

    assert t.valid?

    t.name = nil
    
    assert ! t.valid?

    t.name = ''

    assert ! t.valid?

    t.name = 'NowyWspaniałyTag'

    assert t.valid?

    t.project = nil
    
    assert ! t.valid?

    t.project = projects(:second)
    assert t.valid?
  end

  def test_uniqueness
    t = Tag.new(:name => 'NowyTag')
    t.project = projects(:bananorama)
    t.save!

    t2 = Tag.new(:name => 'NowyTag')
    t2.project = projects(:bananorama)

    t3 = Tag.new(:name => 'NowyTag')
    t3.project = projects(:bananorama)
    
    assert ! t2.valid?
    assert ! t3.valid?
    
    t2.name = 'NowyWspaniałyTag'
    assert t2.valid?

    t3.project = projects(:second)
    assert t3.valid?

    t2.save!
    t3.save!
  end

  def test_cant_mass_change_project
    t = Tag.new(:name => 'NowyTag')
    t.project = projects(:bananorama)
    t.save!

    t.update_attributes(:project => projects(:second))
    assert_equal projects(:bananorama), t.project

    t.update_attributes(:project_id => projects(:second).id)
    assert_equal projects(:bananorama), t.project
  end
end
