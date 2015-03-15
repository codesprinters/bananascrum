class SortableTask < SortableElements::Base
  def scope(attributes)
    "domain_id = #{attributes['domain_id']} AND item_id = #{attributes['item_id']}"
  end

  def has_scope?(attributes)
    return !attributes['item_id'].nil?    # this should always be true
  end

  def position_attribute
    "position"
  end

end
