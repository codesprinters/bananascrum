class Theme < ActiveRecord::Base
  attr_accessible :name
  attr_accessible :slug
  attr_accessible :margin_background
  attr_accessible :content_background
  attr_accessible :buttons_background
  attr_accessible :info_box_header_background
  attr_accessible :inplace_hover_background
  attr_accessible :item_background
  attr_accessible :item_description_background
  attr_accessible :task_even_background
  attr_accessible :task_odd_background
end
