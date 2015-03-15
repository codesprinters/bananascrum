// Name space for task related functions
bs.task = {};

bs.task.getId = function(taskChild) {
  return bs.modelId(taskChild, '.task', 'task-');
};

// @param this  DOM element representing task
bs.task.editableSummary = function() {
  $(this).cseditable({
    submit: 'OK',
    cancelLink: "Cancel",
    editClass: 'editor-field',
    startEditing: true,
    onSubmit: bs.task.summaryOnsubmit,
    onReset: function(){
      bs.backlog.enableHighlight.call(this);
      var id = bs.item.getId(this);
      bs.mutex.unlock(id);
      $(this).removeClass('editing');
    },
    onEdit: function() {
      $(this).addClass('editing');
      bs.backlog.suppressHighlight.call(this);
      var id = bs.item.getId(this);
      bs.mutex.lock(id);
    }
  });
};

bs.task.setSummary = function(envelope) {
  bs.item.factory({id: envelope.item, args: [ envelope ], callback: function(envelope){
    var task = this.findTask(envelope.id);
    var summary = task.highlight().find('.task-summary');
    summary.html(envelope.value);
    bs.backlog.enableHighlight.call(summary);
  }});
};

// @param this  DOM element
// @param values  hash with current and previous values
bs.task.summaryOnsubmit = function(values) {
  var summary = $(this);
  var id = bs.task.getId(summary);
  var action = taskSummaryProjectTaskPath(bs._project, id);
  
  bs.backlog.inplaceSubmitHandler(summary, action, values, bs.task.setSummary);
};

bs.task.editableUser = function() {
  $(this).cseditable({
    type: 'selectCheckbox',
    options: bs._team,
    submit: 'OK',
    cancelLink: 'Cancel',
    editClass: 'editor-field',
    startEditing: true,
    onSubmit: bs.task.userOnsubmit,
    onReset: bs.backlog.enableHighlight,
    onEdit: bs.backlog.suppressHighlight
  });
};

bs.task.assignUser = function(envelope) {
  bs.item.factory({id: envelope.item, args: [envelope], callback: function(envelope) {
    var task = this.findTask(envelope.id);
    task.effect('highlight').find('.task-users').html(envelope.login);
    $(document).trigger('bs:backlogChanged');
  }});
};

bs.task.userOnsubmit = function(values) {
  var taskUser = $(this);
  var id = bs.task.getId(taskUser);
  var action = assignProjectTaskPath(bs._project, id);
  
  bs.backlog.inplaceSubmitHandler(taskUser, action, values, bs.task.assignUser);
};

bs.task.editableEstimate = function() {
  $(this).cseditable({
    submit: 'OK',
    cancelLink: 'Cancel',
    editClass: 'editor-field',
    startEditing: true,
    onSubmit: bs.task.estimateOnsubmit,
    onReset: bs.backlog.enableHighlight,
    onEdit: bs.backlog.suppressHighlight
  });
};

bs.task.setEstimate = function(envelope) {
  bs.item.factory({id: envelope.item, args: [ envelope ], callback: function(envelope){
    var task = this.findTask(envelope.id);
    task.highlight().setClassIf(envelope.task_done, 'done').find('.task-estimate').html(envelope.value);
    task.find('input[name=task_estimate]').attr('value', envelope.value);
    this.setClassIf(envelope.item_done, 'item-done');
    $(document).trigger('bs:backlogChanged');
  }});
};

bs.task.estimateOnsubmit = function(values) {
  var taskEstimate = $(this);
  var id = bs.task.getId(taskEstimate);
  var action = taskEstimateProjectTaskPath(bs._project, id);

  bs.backlog.inplaceSubmitHandler(taskEstimate, action, values, bs.task.setEstimate);
};

bs.task.close = function() {
  var id = bs.task.getId($(this));
  var action = taskEstimateProjectTaskPath(bs._project, id);
  bs.post(action, { value: 0 }, bs.task.setEstimate, null, 'json');
};

/**
 * Function to handle deletion of backlog items' tasks
 *
 * @param {Object} ev event
 */
bs.task.handleDelete = function(ev) {
  ev.preventDefault();

  var taskListElement = $(ev.target).closest('li.task');
  var taskId = bs.task.getId(taskListElement);
  var taskName = taskListElement.find('.task-summary').text();
  
  if (confirm("Are you sure you want to delete '" + taskName + "' ?")) {
    bs.destroy( projectTaskPath(bs._project, taskId), {}, bs.task.destroy, null, 'json' );
  }
};

bs.task.destroy = function(envelope) {
  bs.item.factory({id: envelope.item, onPageOnly: true, args: [ envelope ], callback: function(envelope) {
    this.findTask(envelope.id).remove();
    this.setClassIf(envelope.item_done, 'item-done');
    $(document).trigger('bs:backlogChanged');
  }});
};

bs.task.sortStartHandler = function(ev, ui) {
};

bs.task.sortStopHandler = function(ev, ui) {
  // fix for opera
  ui.item.css({'top':'0','left':'0'});
  
  var success = function(resp) {
    ui.item.closest('.tasks').recolorRows({rowClass: '.task'});
    ui.item.highlight();
  };
  var id = ui.item.attr('id');
  ui.item.parent().find('li.task').each(function(idx) {
    if (id == this.id) {
      var taskId = bs.modelId(ui.item, '.task', 'task-');
      var itemId = bs.item.getId(ui.item);
      bs.post(sortProjectTaskPath(bs._project, taskId), {
        item: itemId,
        position: idx
      }, success, null, 'json');
      return false;
    }
    return true;
  });
};

bs.task.makeSortable = function() {
  $(this).sortable({
    axis: 'y',
    opacity: '0.7',
    start: bs.task.sortStartHandler,
    stop: bs.task.sortStopHandler,
    cancel: '.nosort, :input, option, a, img, div.marker-info'
  });
};

bs.task.add = function(envelope) {
  bs.item.factory({id: envelope.item, args: [ envelope ], callback: function() {
    var newTask = this.find('ul.tasks').append(envelope.html).recolorRows({rowClass: '.task'}).find('.task:last');
    newTask.highlight();
    this.setClassIf(envelope.item_done, 'item-done');
    this.trigger('bs:itemSizeChanged');
    $(document).trigger('bs:backlogChanged');
  }});
};

bs.task.newTaskAjaxSuccessHandler = function(container, envelope) {
  bs.item.factory({child: container, callback: bs.item.hideFormContainers});
  container.html(envelope.html).slideDown(function() { 
    container.focusOnFirstInput(); 
    container.find('#task-users').selectCheckbox('fixPosition'); //widget is initialized while form field is still moving, have to fix position after it finishes
    container.trigger('bs:itemSizeChanged');
  });
  container.find('.hide-form').click(bs.task.newTaskCancelHandler);
  container.find('#task-users').selectCheckbox({
    selectList: bs._team,
    select: envelope.mark,
    paneClass: "checkbox-dropdown nosort",
    width: 175
  });
  
  var handleEnterKeySubmits = function() {
    container.find('form select').bind('keypress', function(event) {
      if (event.which == 13) { //enter key
        container.find('form').submit(); 
        event.stopPropagation();
        container.find('form select').unbind('keypress'); //prevent multiple submits by users with shaking hands
        setTimeout(handleEnterKeySubmits, 1000); 
      }
    });
  };
  
  var error = function(resp) {
    var envelope = JSON.parse(resp.responseText);
    if (envelope._error && envelope._error.type == 'invalid_record') {
      container.find('.error-container').html(envelope.html);
      container.trigger('bs:itemSizeChanged');
    } else {
      throw resp;
    }
  };
  handleEnterKeySubmits();
  bs.ajax.submitFormBinder(container.find('form'), function(envelope) {
    bs.item.factory({id: envelope.item, args: [ envelope ], callback: bs.item.hideNewTaskForm});
    bs.task.add(envelope);
  }, error, 'json');
};

bs.task.newTaskClickHandler = function(ev) {
  ev.preventDefault();
  ev.stopPropagation();
  var link = $(ev.target);
  var tasksTab = link.parents('.item').find('.tabs-links .tab-tasks a');
  if (tasksTab.length) { 
    bs.tabs.setCurrentTab(tasksTab);
  }
  var target = bs.getUrl(link);
  var container = link.parents('.item').find('.new-task');
  var success = function(envelope) {
    bs.task.newTaskAjaxSuccessHandler(container, envelope);
  };
  if (!container.is(':visible')) {
    bs.get(target, {}, success, null, 'json');
  }
};

bs.task.newTaskCancelHandler = function(ev) {
  ev.preventDefault();
  ev.stopPropagation();
  
  bs.expand.hideFormClickHandler(ev);
  return false;
};

bs.task.reorder = function(envelope) {
  bs.item.factory({id: envelope.item, onPageOnly: true, args: [ envelope ], callback: function(envelope) {
    var element = this.findTask(envelope.id);
    element.remove();
    this.find('.tasks').appendAt(element, '.task', envelope.position).effect('highlight').recolorRows({rowClass: '.task'});
  }});
};
