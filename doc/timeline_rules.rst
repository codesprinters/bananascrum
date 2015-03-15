##############
Timeline rules
##############

Why timeline view exists?
=========================

Timeline view is to help product owners estimate future sprints, based on past
and current sprint view. It displays all items, from all sprints (past and
current) and also entire product backlog with some planning markers, that help
to estimate future sprits for the team.

There are following sections on the timeline view.

Past sprints section
====================

Displays all items from past sprints. Each sprint is separated by a marker.
This section is collapsed by default.


Project graphs and statistics
=============================

This section displays two graphs:
 * Sprints load: bar graph displaying number of story points for each sprint
 * Project burnup: displays total number of story points done for each sprint

Additional information displayed is average velocity.


Ongoing sprints
===============

Displays list of sprints that are in progress. We support multiple concurrent
sprints for different teams.



Product backlog
===============

This section displays all items not assigned to any sprint, separated by
planning markers. Each planning marker corresponds to some sprint. If one last
current sprint has no items assigned, it'll be displayed as first sprint.
Other planning markers correspond to future sprints.

Product owner can plan future sprint load by mannually dragging
planning markers on this section, or by using velocity widget, that will
equally divide sprint load, by effort story points.

TODO: If some sprint from future, has some items assigned, we should display a
warning message, next to planning marker information. It is against scrum
methodology.
