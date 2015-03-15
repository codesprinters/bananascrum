bs.marker = {};

bs.marker.element = '<li class="long-term-view-element marker"><div class="marker-info"></div><div class="triangle"></div></li>';

bs.marker.enableMarkers = false;

bs.marker.getBacklogElements = function() {
  return $('.product-backlog-not-on-planning .backlog-element');
};

bs.marker.setHeightAndPosition = function(markerInfo, previousMarkerPosition, containerHeight) {
  markerInfo.css('top', previousMarkerPosition + 8).css('height', containerHeight - 14);
};

/**
 * Called after initializing backlog and each drag of any item
 **/
bs.marker.updateMarkerInfosPosition = function(container) {
  var markers, containerHeight;
  var nthMarkerTopPosition = function(indx) {
    var marker = markers[indx];
    return $(marker).position().top;
  };
  container.find('.long-term-view:not(:hidden)').each(function(i) {
    markers = $(this).find('.marker');
    containerHeight = markers.closest('.backlog-items').height();
    if (markers.length > 1) {
      markers.not(':first-child').find('.marker-info').each(function(index) {
        bs.marker.setHeightAndPosition($(this), nthMarkerTopPosition(index), nthMarkerTopPosition(index + 1) - nthMarkerTopPosition(index));
      });
    } else if (markers.length == 1) {
      var markerInfo = markers.find('.marker-info');
      var containerTop = markers.closest('.backlog-items').position().top;
      bs.marker.setHeightAndPosition(markerInfo, containerTop - 8, containerHeight);
    }
    $(this).removeClass('markers-hidden');
  });
  // Last marker is in different container, so we treat it with different
  // formula
  if ($('#planning-marker-bottom').length) {
    var lastMarkerPosition = 0;
    try {
      lastMarkerPosition = $('#backlog-items .marker:last').position().top;
    } catch (e) {
    }
    containerHeight = $('#planning-marker-bottom .marker').position().top - lastMarkerPosition;
    var markerInfo = $('#planning-marker-bottom .marker-info');
    bs.marker.setHeightAndPosition(markerInfo, lastMarkerPosition, containerHeight);
  }
};

bs.marker.updateMarkerInfosPositionAfterExpandHandler = function(ev, link) {
  var container = $(ev.target).parents(".expandable.timeline");
  if (container.length) {
    bs.marker.updateMarkerInfosPosition(container);
  }
};

bs.marker.recalculateMarkers = function() {
  // Add planning marker from bottom container. It'll display stats for last
  // expected sprints
  var backlogElements = $('.product-backlog-not-on-planning li.backlog-element').
    add('#planning-marker-bottom li.marker');
  var itemsSinceLastMarker = [], markerPosition = 0;
  var elem, i, lastSprintNo = bs._lastSprintNumber || 0;

  bs.marker.sprintsWithName = 0;
  for (i = 0; elem = backlogElements[i]; i++) {
    elem = $(elem);
    if (elem.hasClass("item")) {
      itemsSinceLastMarker.push(backlogElements[i]);
    } else if (elem.hasClass("marker")) {
      lastSprintNo = bs.marker.updateMarkerData(elem, markerPosition, itemsSinceLastMarker, lastSprintNo);
      markerPosition++;
      itemsSinceLastMarker = [];
    }
  }

  $('#total-number-of-sprints').empty().text('Total number of sprints: ' + markerPosition);
};

/**
 * Number of sprints with name.
 * Used to calculate unplanned sprints numbers.
 */
bs.marker.sprintsWithName = 0;

/**
 * Updates markes infos content: sprint name, SP, dates etc.
 */
bs.marker.updateMarkerData = function(marker, newPosition, newItems, lastSprintNo) {
  marker.data("items", newItems.length);
  marker.data("position", newPosition);
  var stats = bs.stats.count($(newItems));
  var sprintNumber = lastSprintNo + 1;
  var endDate, sprint;
  var sprintName;
  
  if (bs._sprintsAfterToday && bs._sprintsAfterToday[newPosition]) {
    sprint = bs._sprintsAfterToday[newPosition];
    sprintName = sprint.name;
    bs.marker.sprintsWithName++;
    endDate = sprint.to_date;
  } else {
    sprintName = 'Sprint ' + (sprintNumber - bs.marker.sprintsWithName);
  }

  // limit sprint name characters
  var maxLength = 13;
  if (sprintName.length > maxLength) {
    sprintName = sprintName.substring(0, maxLength).replace(/\s$/, "") + '...';
  }

  var template = $.template("<div class='sprint-name'>${effort} ${unit}</div><div class='sprint-stats'>${sprintName}<br />${endDate}</div><div style='clear: both'></div>");

  marker.find("div.marker-info .info-content")
    .empty()
    .append(template, {sprintName: sprintName, effort: stats['items-effort'], unit: bs._backlog_unit, endDate: endDate});
    
  return sprintNumber;
};

/* Gets or sets marker id */
bs.marker.id = function(markerSelector, id) {
  if (!id) {
    id = parseInt(markerSelector.attr('id').substring('marker-'.length));
  } else {
    markerSelector.attr('id', 'marker-' + id);
  }
  return isNaN(id) ? null : id;
};

/* Gets or sets marker position */
bs.marker.position = function(markerSelector, position) {
  if (!position) {
    position = bs.item.findItemPositionIn($('#backlog-elements'), markerSelector);
  } else {
    var backlogElements = $('#backlog-items .backlog-element');
    var element = $(backlogElements[position]);
    var markerId = bs.marker.id(markerSelector);
    if (element.hasClass('marker') && markerId && bs.marker.id(element) != markerId) {
      markerSelector.insertBefore(element);
      bs.marker.refreshMarkerInfos();
    }
  }
  return position;
};

bs.marker.create = function(markerSelector, position) {
  var success = function(envelope) {
    bs.marker.id(markerSelector, envelope.marker);
  };
  var error = function(xhr) {
    bs.__markerEnvelope = xhr;
  };
  bs.post(projectPlanningMarkersPath(bs._project), { position: position }, success, error, 'json');
};

bs.marker.createHandler = function(data) {
  if (!data || !data.marker || !data.position) {
    return;
  }
  var template = $('#planning-marker-top .marker');
  var items = $('#backlog-items .backlog-element');
  var marker = template.clone().insertBefore($(items[data.position]));
  bs.marker.id(marker, data.marker);
  $(document).trigger('bs:backlogOrderChanged');
};

bs.marker.update = function(markerSelector, position) {
  var markerId = bs.marker.id(markerSelector);
  var envelope;
  var success = function(envelope) {
  };
  var error = function(xhr) {
    switch (xhr.status) {
    case 404:
      markerSelector.remove();
      bs.marker.refreshMarkerInfos();
      break;
    case 409:
      envelope = JSON.parse(xhr.responseText);
      if (envelope._error && envelope._error.type == 'planning_marker_update') {
        bs.marker.position(markerSelector, envelope.position);
        bs.flash(envelope._error.message, 'error');
      } else {
        throw xhr;
      }
      break;
    default:
      throw xhr;
    }
  };
  bs.put(projectPlanningMarkerPath(bs._project, markerId), { position: position }, success, error, 'json');
};

bs.marker.updateHandler = function(resp) {
  if (!resp || !resp.marker || !resp.position) {
    return;
  }
  var index = 0;
  var items = $('#backlog-items .backlog-element');
  var marker = $('#marker-' + resp.marker);
  items.each(function(idx) {
    var $this = $(this);
    if ($this.attr('id') == marker.attr('id')) {
      index = idx;
      return true;
    }
  });
  if (index > resp.position) {
    marker.insertBefore($(items[resp.position]));
  } else {
    marker.insertAfter($(items[resp.position]));
  }
  $(document).trigger('bs:backlogOrderChanged');
};

bs.marker.removeCollection = function(markerIds) {
  $.each(markerIds, function() {
    var markerId = this;
    $('#marker-' + markerId).remove();
  });
};

/**
 * Saves via ajax markers positions.
 */
bs.marker.save = function(markerSelector, position) {
  var markerId = bs.marker.id(markerSelector);
  if (markerId) {
    bs.marker.update(markerSelector, position);
  } else {
    bs.marker.create(markerSelector, position);
  }
};

bs.marker.destroy = function(markerSelector) {
  var markerId = bs.marker.id(markerSelector);
  var success = function() {
    markerSelector.remove();
    bs.marker.refreshMarkerInfos();
  };
  var error = function(resp) {
    if (resp.status == 404) {
      markerSelector.remove();
      bs.marker.refreshMarkerInfos();
    } else {
      throw resp;
    }
  };
  if (markerId) {
    bs.destroy(projectPlanningMarkerPath(bs._project, markerId), {}, success, error);
  } else {
    success();
  }
};

bs.marker.destroyHandler = function(data) {
  $('#marker-' + data.marker).remove();
  $(document).trigger('bs:backlogOrderChanged');
};

bs.marker.destroyAllHandler = function(data) {
  $('#backlog-items .marker').remove();
  $(document).trigger('bs:backlogOrderChanged');
};

bs.marker.distributeSuccess = function(response) {
  if (!response) {
    return false;
  }
  var items, marker, markerElement;
  var template = $('#planning-marker-top .marker');

  $('#backlog-items .marker').remove();
  items = $('#backlog-items .backlog-element');
  
  $.each(response, function() {
    marker = this;
    markerElement = template.clone().insertAfter($(items[marker.position]));
    bs.marker.id(markerElement, marker.marker);
  });

  $(document).trigger('bs:backlogOrderChanged');
  
  return false;
};

/**
 * Distributes markers after click in submit in the Velocity widget.
 */
bs.marker.distributeHandler = function(ev) {
  ev.preventDefault();
  ev.stopPropagation();
  var target = $(ev.target);
  var velocity = parseFloat($('.velocity-input').val());

  if (isNaN(velocity)) {
    alert("velocity is not a number");
    return false;
  }

  bs.post(distributeProjectPlanningMarkersPath(bs._project), target.serialize(), bs.marker.distributeSuccess, null, 'json');
};

bs.marker.isHidden = function() {
  return $('.product-backlog-timeline .long-term-view-element').is(':hidden');
};

/**
 * Refresh planning marker infos.
 * This function is operates only on product backlog section, because other
 * sections are non-modifiable.
 */
bs.marker.refreshMarkerInfos = function() {
  if (!bs.marker.enableMarkers) {
    return;
  }

  bs.marker.recalculateMarkers();
  bs.marker.showMarkerInfos();
  bs.marker.updateMarkerInfosPosition($('.product-backlog-timeline'));
};

/**
 * Hide planning marker infos.
 */
bs.marker.hideMarkerInfos = function() {
  if (bs.marker.isHidden()) {
    return;
  }

  var markerInfos = $('.product-backlog-timeline').addClass('markers-hidden');
  
};

bs.marker.showMarkerInfos = function() {
  var markerInfos = $('.product-backlog-timeline').removeClass('markers-hidden');
};

/*
 * Event handler, that is fired, when we start draggin top, or bottom planning
 * marker
 *
 * It creates new marker element, that should be saved in db after being
 * dropped
 */
bs.marker.sortStartHandler = function(ev, ui) {
  var li = ui.item;
  bs.marker.hideMarkerInfos();
  li.clone().attr('style', 'display: list-item;').prependTo(li.closest('ul'));
};

/**
 * Event handler, that is fired, when we drop planning marker on a backlog
 *
 * It does the following:
 * Planning marker is removed, when it's dropped next to other planning marker
 *
 * If it's dropped somewhere in the middle of the backlog, we save it's
 * position in database
 */
bs.marker.sortUpdateHandler = function(ev, ui) {
  var position = bs.item.findItemPositionIn("#backlog-items", ui.item);
  var backlogElements = bs.marker.getBacklogElements();
  var last = backlogElements.length - 1;
  var remove = false;
  var isBoundary = (position == last || position <= 0);
  var previous = $(backlogElements[position - 1]);
  var next = $(backlogElements[position + 1]);
  var isNextToMarker = (previous.hasClass('marker') || next.hasClass('marker'));

  if (isBoundary || isNextToMarker) {
    bs.marker.destroy(ui.item);
  } else {
    bs.marker.save(ui.item, position);
  }
};

/**
 * Handler called when planning marker is dropped on boundary containers,
 * which should only contain "teplate" markers, that are used to clone new
 * markers
 */
bs.marker.sortUpdateOnBoundsHandler = function(ev, ui) {
  if (ui.item.closest('ul').attr('id') != 'backlog-items') {
    bs.marker.destroy(ui.item);
  }
};

bs.marker.draggableBoundaryMarkers = function() {
  var options = bs.item.optionsForSortable({
    start: bs.marker.sortStartHandler,
    update: bs.marker.sortUpdateOnBoundsHandler,
    deactivate: bs.marker.refreshMarkerInfos
  });
  $('#planning-marker-top, #planning-marker-bottom').cssortable(options);
};

bs.marker.removeAllMarkers = function(ev) {
  ev.preventDefault();
  ev.stopPropagation();

  var callback = function() {
    $('#backlog-items .marker').remove();
    $(document).trigger('bs:backlogOrderChanged');
  };
  var url = bs.getUrl($(this));
  if (confirm("This will remove all of your planned sprint markers. Are you sure?")) {
    bs.post(url, {}, callback);
  }
}

$(document).ready(function() {
  var velocityWidget = $('.velocity-widget');
  velocityWidget.find('.distribute-markers').bind('submit', bs.marker.distributeHandler);
  velocityWidget.find('.remove-markers').bind('click', bs.marker.removeAllMarkers);
});

/**
 * Initialize long term wigdet.
 * 
 * It loads markers position stored in database
 * and recreates long term view elements.
 */
bs.marker.init = function () {
  if (bs.marker.enableMarkers) {
    bs.marker.enableMarkers = ($('.long-term-view').length > 0);
  }
  if (!bs.marker.enableMarkers) {
    return;
  } else {
    var elements = $('.long-term-view-element');
    elements.show();
    bs.marker.draggableBoundaryMarkers();
    bs.marker.updateMarkerInfosPosition($('.expandable-list.timeline.expanded'));
    var elementsWithMarkers = ".product-backlog-items,.ongoing-sprints-timeline,.past-sprints-timeline";
    
    $(elementsWithMarkers).bind('bs:expandToggle', bs.marker.updateMarkerInfosPositionAfterExpandHandler);
    $(elementsWithMarkers).bind('bs:tabChanged', bs.marker.updateMarkerInfosPositionAfterExpandHandler);
    $(elementsWithMarkers).bind('bs:itemSizeChanged', bs.marker.updateMarkerInfosPositionAfterExpandHandler);
    
  }

};
