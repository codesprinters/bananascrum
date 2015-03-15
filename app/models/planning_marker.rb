class PlanningMarker < BacklogElement
  validates_presence_of :position
  validate :forbidden_positions, :unless => Proc.new { |element| element.dont_validate_positions }

  attr_accessor :dont_validate_positions    # we don't want validations during distribute actions. It generates O(N) backlog loads

  def sprint_name
    sprints_to_plan_names = project.sprints_to_plan_names
    sprint_name = sprints_to_plan_names[project.planning_markers.index(self)]
    return sprint_name || "Sprint"
  end

  def effort
    elements = project.backlog_elements.not_assigned
    markers = project.planning_markers
    idx = markers.index(self)
    items = []
    if idx == 0
      items = elements.select { |e| e.type == 'Item' and e.position < self.position }
    else
      items = elements.select { |e| e.type == 'Item' and e.position > markers[idx - 1].position and e.position < self.position }
    end
    items.map { |i| (i.estimate.nil? or i.estimate == Item::INFINITY_ESTIMATE_REPRESENTATIVE) ? 0 : i.estimate }.sum
  end

  def sprint_to_date
    assosiated_sprint = project.sprints_to_plan[project.planning_markers.index(self)]
    return assosiated_sprint.nil? ? nil : assosiated_sprint.to_date
  end

  protected
  # PlanningMarkers cannot be saved at first, or last position and next to
  # another planning marker
  def forbidden_positions
    return if project.nil? or position.nil?
    elements = project.backlog_elements.not_assigned
    offset = new_record? ? 0 : 1
    if position <= 0 or position >= elements.length - offset
      errors.add(:position, "should not be first, or last")
    end
    offset = 1
    offset = 0 if new_record?
    # COALESCE is ugly hack for planning markers that are to be created
    # We cannot do id != NULL. It is guaranteed that -1 will not appear as
    # primary key, so we can check it this way
    neighbours = 0
    [ position - 1, position, position + offset ].each do |neihbour_position|
      if neihbour_position >= 0 && project.backlog_elements.not_assigned.any?{|element| element != self && element.position == neihbour_position && element.is_a?(PlanningMarker)} #cannot trust ActiveRecord reflection collection here: it is not wise enough
        neighbours += 1
      end
    end

    if neighbours > 0
      errors.add(:position, "should not be placed next to another planning marker")
    end
    
  end
end
