bs.sprint = { };

bs.sprint.findTasksForUser = function(username) {
  var withClosedInplace = $('.task:has(.task-users .user-login):contains("' + username + '")');
  var withOpenedInplace = $('.task:has(.task-users .editor-field input:checked[alt=' + username +'])');
  return withClosedInplace.add(withOpenedInplace);
};

bs.sprint.findItemsForTasks = function(tasks) {
  return $(tasks).parents('.item');
};

// find all items that in which user don't have any tasks
bs.sprint.findItemsWithoutUser = function(username) {
  return $('.item:not(:has(.task-users[innerHTML=' + username + ']))');
};

// this function initializes the filter behaviour on select box and runs default filter
bs.sprint.setupFilter = function() {
  var form = $('form#filters-form');
  var select = form.find('select');

  if (!select[0]) { 
    return; 
  }
  
  var selection = $.cookie('filter_for_' + bs._sprintId) || "All";
  select[0].value = selection;
  
  select.change(function() {
    $(document).trigger('bs:backlogChanged');
  });

  // Old layout only
  $('input#hide-finished').change(function() {
    $(this).data("hide-finished", $('input#hide-finished').attr('checked'));
    $(document).trigger('bs:backlogChanged');
  });

  if ($.browser.msie) {   // this for IE not firing change event
    $('input#hide-finished').live('click', function() {
      $(this).trigger('change');
    });
  }

  $('a#hide-finished').bind('click', function(){}).toggle(
   function() {
      $(this).data("hide-finished", true);
      $(this).text("Show Completed");
      $(document).trigger('bs:backlogChanged');
    },
    function() {
      $(this).data("hide-finished", false);
      $(this).text("Hide Completed");
      $(document).trigger('bs:backlogChanged');
    }
  );

};

bs.sprint.applyFilter = function() {
  var form = $('form#filters-form');
  var selected = form.find('select').attr('value');

  if (!selected) { 
    return; 
  }
  var username = form.find('select :selected').text();
  
  $.cookie('filter_for_' + bs._sprintId, selected);

  var allTasks = $('.task').show();
  var allStories = $('.item');
  var stories;
  var tasks;

  if (username == "All") {
    tasks = allTasks;
    stories = allStories;
  } else {
    tasks = bs.sprint.findTasksForUser(username);
    stories = bs.sprint.findItemsForTasks(tasks);

    var storiesToHide = bs.sprint.findItemsWithoutUser(username);
    $(storiesToHide).data('filtered-out', true);

    $(allTasks).addClass('filtered-out');
  }

  $(stories).data('filtered-out', false);

  if ($('#hide-finished').data('hide-finished') === true) {
    allTasks.show().filter(":has(input[name='task_estimate'][value='0'])").hide();
    $('.item-done').data('filtered-out', true);
  }

  $(tasks).removeClass('filtered-out');
};

bs.sprint.deleteHandler = function() {
  if (!confirm("Are you sure you want to delete the sprint?")) { 
    return false;
  }
  var element = $(this);
  var url = bs.getUrl(element);
  var success = function() {  
    var table = element.parents('table.data');
    element.parents('tr.sprint-row').remove();
    table.recolorRows({'rowClass': '.sprint-row'});
  };
  bs.destroy(url, {}, success);
  return false;
};

bs.sprint.initializeDatePickers = function(){
  if (typeof bs.dateFormat != 'undefined') {
      Date.format = bs.dateFormat;
  }
  
  $('.date-field').datePicker({
    'startDate': '1996-01-01',
    'position': 'r'
  });
};

bs.sprint.reloadParticipants = function(text) {
  $('#participants-tab').setClassIf(!text, 'hidden');
  $('.participants').html(text);
};

bs.sprint.focusOnSprintName = function () {
  $('.new-sprint input[name=sprint[name]]').focus();
};

bs.sprint.calculateCountSprintLength = function () {
    if (typeof bs.dateFormat != 'undefined') {
        Date.format = bs.dateFormat;
    }
    var fromDateString = $("#sprint_from_date").val();
    var toDateString = $("#sprint_to_date").val();
    if (!fromDateString || !toDateString) {
        return;
    }
    var fromDate = Date.fromString(fromDateString);
    var toDate = Date.fromString(toDateString);
    var i;
    var sprintLengthExcludingFreeDays = 0;
    var sprintLength = 0;

    for (i = fromDate; i <= toDate; i.addDays(1)) {
        sprintLength += 1;
        if (!(bs.sprint.freeDays[i.getDay()] == "1")) {
            sprintLengthExcludingFreeDays += 1;
        }
    }

    $('.sprint-length').text('Sprint length in days: ' + sprintLength +
        ' (excluding free days: ' + sprintLengthExcludingFreeDays + ')');
}


bs.sprint.checkIfDifferent = function (checkedSprintId) {
  if (!bs._sprintId || !checkedSprintId) {
    return undefined;
  }
  if (bs._sprintId === checkedSprintId) {
    return false;
  } 
  return true;
};

bs.sprint.bindFormEvents = function() {
  $("#sprint_from_date, #sprint_to_date").change(bs.sprint.calculateCountSprintLength);
  bs.sprint.calculateCountSprintLength();
  bs.sprint.initializeDatePickers();
  bs.sprint.focusOnSprintName();
};

bs.sprint.update = function(envelope) {
  if (!bs.sprint.checkIfDifferent(envelope.sprint.id)) {
    $(".sprint-goals").html(envelope.sprint.goals);
    $(".sprint-title").html(envelope.sprint.name);
    $(".sprint.information:not(.items-count)").html(envelope.sprint.information_text);
  }
  
  if ($('.data.sprints-list').length) {
    var sprint = $('.data.sprints-list #sprint-' + envelope.sprint.id);
    if (sprint.length) {
      sprint.replaceWith(envelope.sprint.row_html);
    } else {
      $('.data.sprints-list').append(envelope.sprint.row_html);
    }
    $('.data.sprints-list').recolorRows({rowClass: '.sprint-row'});
  }
};

bs.sprint.editHandler = function() {
  var url = bs.getUrl($(this));
  bs.dialog.loadToModal(url, bs.sprint.update, bs.sprint.bindFormEvents);
};

$(document).ready(function() {
  Date.format = 'yyyy-mm-dd';
  $(".delete-sprint").live('click', bs.sprint.deleteHandler);
  $('.edit-sprint-link').live('click', bs.sprint.editHandler);
  $('.new-sprint-link').live('click', bs.sprint.editHandler);
});

