require File.dirname(__FILE__) + '/../test_helper'

class ImpedimentActionTest < ActiveSupport::TestCase
  fixtures :impediment_actions
  
  def test_creation_frm_defaults
    ImpedimentLog.delete_all 
    Impediment.delete_all
    ImpedimentAction.any_instance.expects(:save!).never
    ImpedimentAction.create_defaults
    
    # only create the single missing one
    impediment_actions(:created).destroy
    ImpedimentAction.any_instance.expects(:save!).once
    ImpedimentAction.create_defaults
    
    #create all missing entries
    ImpedimentAction.destroy_all
    ImpedimentAction.any_instance.expects(:save!).times(4)
    ImpedimentAction.create_defaults
  end
  
end
