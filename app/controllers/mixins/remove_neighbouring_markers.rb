module RemoveNeighbouringMarkers
  def remove_neighbouring_markers(item)
    @removed_markers = []
    return if item.position.nil?
    is_item_last = Project.current.backlog_elements.not_assigned.find(:all,
      :conditions => ['position > ?', item.position]).length == 0
    neighbours = Project.current.backlog_elements.not_assigned.find(:all,
      :conditions => ["type = 'PlanningMarker' AND position IN (?, ?)",
        item.position - 1, item.position + 1]).map { |n| n }
    marker_to_remove = nil
    if neighbours.length == 2
      marker_to_remove = neighbours[1]
    elsif item.position == 0 or is_item_last
      marker_to_remove = neighbours[0]
    end
    if marker_to_remove
      @removed_markers << marker_to_remove.id
      marker_to_remove.destroy
    end
  end
end
