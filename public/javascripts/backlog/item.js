bs.item = {};

bs.item.getId = function(item_child) {
  return bs.modelId(item_child, '.item', 'item-');
};

bs.item.factory = function(opts) {
  var defaults = {
    onPageOnly: true,
    callback: null
  };
  opts = $.extend(defaults, opts);
  
  if (!$.isFunction(opts.callback)) {
    throw "Callback is required";
  }
  var item;
  var call = function() {
    opts.callback.apply(item, opts.args || []);
  };

  if (opts.item) { 
    item = opts.item;
    call(); 
  } else if(opts.child) {
    item = opts.child.parents('.item');
    call();

  } else if (opts.id || opts.html) {
    item = $('#item-' + opts.id);
    if (item[0]) {
      call();
    } else if (opts.html) {
      item = $(opts.html);
      call();
    } 
  } else {
    throw "Cannot instantiate item. Define either html or id or item or child";
  }
  return false;
};

bs.item.editableDescription = function() {
  var desc = $(this);
  // Store previous value as html to restore with br tags instead of newlines
  // plugin does no good in here
  desc.data('item_description.original_html', desc.html());
  desc.cseditable({
    type: 'textarea',
    submit: 'OK',
    cancelLink: 'Cancel',
    editClass: 'editor-field',
    startEditing: true,
    onSubmit: bs.item.descriptionOnsubmit,
    onReset: bs.item.descriptionOnreset,
    onEdit: bs.item.descriptionOnedit
  });
};

bs.item.descriptionOnsubmit = function(values) {
  var itemDescription = $(this);
  var id = bs.item.getId(itemDescription);
  var action = backlogItemDescriptionProjectItemPath(bs._project, id);
  itemDescription.parents('.item').find('.redcloth-legend').hide();
  
  var complete = function(data) {
    bs.item.factory({
      child: itemDescription,
      callback: bs.item.setDescription,
      args: [ data ]
    });
  };
  bs.backlog.inplaceSubmitHandler(itemDescription, action, values, complete, null, 'json');
};

bs.item.setDescription = function(data) {
  var element = this.find('.item-description-text');
  element.html(data.html);
  var button = element.closest('.item-description').find('a.more-less-button');
  bs.backlog.toggleDescriptionMoreLess.call(button[0], true);
  bs.backlog.toggleDescriptionMoreLess.call(button[0]);
  element.data('item_description.original_html', element.html());
  this.trigger('bs:itemChanged').trigger('bs:itemSizeChanged');
};

bs.item.descriptionOnedit = function() {
  bs.backlog.suppressHighlight.call(this);
  var itemDescription = $(this);
  var moreLessButton = itemDescription.closest('.item-description').find('a.more-less-button');
  bs.backlog.toggleDescriptionMoreLess.call(moreLessButton[0], true);
  moreLessButton.addClass('hidden');
  itemDescription.parents('.item').find('.redcloth-legend').show();

  var textarea = itemDescription.find('textarea');
  textarea.val('Loading...');

  var id = bs.item.getId(itemDescription);
  bs.get(itemDescriptionTextProjectItemPath(bs._project, id), {}, function(resp) {
    textarea.val(resp).select();
  });
  bs.mutex.lock(id);
  itemDescription.trigger('bs:itemSizeChanged');
};

bs.item.descriptionOnreset = function() {
  var desc = $(this);
  var id = bs.item.getId(desc);
  bs.backlog.enableHighlight.call(this);
  var button = desc.closest('.item-description').find('a.more-less-button').removeClass('hidden');
  desc.parents('.item').find('.redcloth-legend').hide();
  desc.html(desc.data('item_description.original_html'));
  bs.mutex.unlock(id);
  desc.removeClass('truncated');
  bs.backlog.toggleDescriptionMoreLess.call(button[0]);
  desc.trigger('bs:itemChanged').trigger('bs:itemSizeChanged');
};

bs.item.editableUserStory = function() {
  $(this).cseditable({
    submit:        'OK',
    cancelLink:    'Cancel',
    editClass:     'editor-field',
    startEditing:  true,
    onSubmit:      bs.item.userStoryOnsubmit,
    onReset:       function(){
      bs.backlog.enableHighlight.call(this);
      var id = bs.item.getId($(this));
      bs.mutex.unlock(id);
      $(this).removeClass('editing');
    },
    onEdit:        function() {
      $(this).addClass('editing');
      bs.backlog.suppressHighlight.call(this);
      var id = bs.item.getId($(this));
      bs.mutex.lock(id);
    }
  });
};

bs.item.userStoryOnsubmit = function(values) {
  var itemUserStory = $(this);
  var id = bs.item.getId(itemUserStory);
  var action = backlogItemUserStoryProjectItemPath(bs._project, id);
  bs.backlog.inplaceSubmitHandler(itemUserStory, action, values);
};

bs.item.estimateChoices = function(allowInfinity) {  
  var estimateArray = bs._projectEsimates.split(',');
  var estimates = {};
  var i = 0, currentEstimate;
  var estimateArrayLength = estimateArray.length;

  for(i = 0; i < estimateArrayLength; i++) {
    currentEstimate = estimateArray[i];
    if (i === 0 && currentEstimate == '') {
      estimates[currentEstimate] = '?';
    } else if (i == estimateArrayLength - 1 && currentEstimate == '9999') {
      estimates[currentEstimate] = '\u221e';
    } else {
      estimates[currentEstimate] = currentEstimate;
    }
  }

  if (! allowInfinity) {
    delete(estimates[9999]);
  }
  return estimates;
};

bs.item.editableEstimate = function() {
  var estimate = $(this);
  estimate.cseditable({
    type:          'select',
    options:       bs.item.estimateChoices(estimate.hasClass('infinite')),
    submitBy:      'change',
    cancelLink:    'Cancel',
    editClass:     'inplaceeditor-form nosort editor-field',
    startEditing:  true,
    onSubmit:      bs.item.estimateOnsubmit,
    onReset:       bs.backlog.enableHighlight,
    onEdit:        bs.backlog.suppressHighlight
  });
};

bs.item.updateEstimate = function(data) {
  this.find('.item-estimate').html(data.estimate);
  if (data.estimate == '?') {
    this.addClass('unestimated-backlog-item').removeClass('root');
  } else if (data.estimate == '\u221e') {
    this.addClass('infinity-estimate-backlog-item').removeClass('unestimated-backlog-item');
  } else {
    this.addClass('root').removeClass('infinity-estimate-backlog-item').removeClass('unestimated-backlog-item');
  }
  $(document).trigger('bs:backlogChanged');
};

bs.item.estimateOnsubmit = function(values) {
  var itemEstimate = $(this);
  var id = bs.item.getId(itemEstimate);
  var action = backlogItemEstimateProjectItemPath(bs._project, id);
  var complete = function(data) {
    bs.backlog.ajaxCompleteHandler(itemEstimate, data.estimate);
    bs.item.factory({ 
      id: id,
      callback: bs.item.updateEstimate,
      args: [data]
    });
  };
  bs.backlog.inplaceSubmitHandler(itemEstimate, action, values, complete, null, 'json'); 
};

bs.item.remove = function(data, after) {
  bs.item.factory({
    id: data.item,
    callback: bs.item.doRemove,
    args: [after]
  });
};

bs.item.handleDelete = function(ev) {
  ev.preventDefault();
  var itemElement = $(ev.target).closest('li.item');
  var itemId = itemElement.attr('id').substr(5);
  var itemSummary = itemElement.find('.item-user-story').text();

  var success = function (data) {
    bs.item.remove(data, function () {
      bs.marker.refreshMarkerInfos();
      $(".empty-backlog-note").show();
    });
  };

  if (confirm("Are you sure you want to delete '" + itemSummary + "' ?")) {
    bs.destroy(projectItemPath(bs._project, itemId), {}, success, null, 'json');
  }
};

bs.item.sortStartHandler = function(ev, ui) {
  var li = ui.item;
  if (li.hasClass('item')) {
    var id = bs.item.getId(ui.item);
    bs.mutex.lock(id, 'dragging');
  }

  bs.marker.hideMarkerInfos();
};

bs.item.sortStopHandler = function(ev, ui) {
  if (ui.item.hasClass('nosort')) {
    var id = bs.item.getId(ui.item);
    bs.mutex.unlock(id);
  }

  bs.marker.refreshMarkerInfos();
};

bs.item.backlogSortUpdateHandler = function(ev, ui) {
  if (ui.item.hasClass('item')) {
    var url = sortProjectBacklogPath(bs._project);
    bs.item.commonSortupdateHandler(ev, ui, "#backlog-items", url);
  } else if (ui.item.hasClass('marker')) {
    bs.marker.sortUpdateHandler(ev, ui);
  }
  $(document).trigger('bs:backlogOrderChanged');
};

bs.item.sprintSortupdateHandler = function(ev, ui) {
  var url = sortProjectSprintPath(bs._project, bs._sprintId);
  $(document).trigger('bs:sprintBacklogOrderChanged');
  return bs.item.commonSortupdateHandler(ev, ui, "#assigned-backlog-items", url);
};

bs.item.commonSortupdateHandler = function(ev, ui, backlog, url) {
  if (ui.sender) { 
    return;
  }
  var id = bs.item.getId(ui.item);
  var position = bs.item.findItemPositionIn(backlog, ui.item);
  if (position == -1) {
    return;
  }
  var success = function(resp) {
    ui.item.highlight();
  };
  bs.post(url, {
    item: id,
    position: position
  }, success, null, 'json');
};

bs.item.findItemPositionIn = function(backlog, item) {
  return $(backlog).find("li.backlog-element").index(item);
};

bs.item.dndAssignHandler = function(ev, ui) {
  var position = bs.item.findItemPositionIn("#assigned-backlog-items", ui.item);
  bs.item.assign(ui.item, position);
  return true;
};

bs.item.assignClickHandler = function() {
  var item = $(this);
  if (item.hasClass('disabled')) { 
    return;
  }
  item.addClass('disabled');
  item.timeoutRemoveClass(2000, 'disabled');

  bs.item.assign(item.parents('.item'));
};

bs.item.sprintAppendCallback = function(data) {  
  bs.item.factory({
    id: data.item,
    html: data.html,
    callback: bs.item.appendToSprint,
    args: [ data.position, data._sprint_id ]
  });
};

/**
 * In case of error, we should recieve item id and it's previous position.
 * In such case, put item back to it's original position.
 * Default error handler is always run
 */
bs.item.sprintAppendCallbackError = function(xhr) {
  window.sprint_data = xhr;
  var envelope = JSON.parse(xhr.responseText);
  if (envelope._error && envelope._error.type == 'infinite_estimate_error') {
    if (envelope.item && typeof(envelope.position) != 'undefined') {
      bs.item.backlogAppendCallback(envelope);
    }
  }
  throw envelope;
};

bs.item.assign = function(item, position) {
  var itemId = bs.item.getId(item);

  var url = assignItemToSprintProjectSprintPath(bs._project, bs._sprintId);
  var data = {
    'item_id': itemId
  };
  if (position !== undefined) { 
    data.position = position;
  }
  bs.post(url, data, bs.item.sprintAppendCallback, bs.item.sprintAppendCallbackError, 'json');
};

bs.item.dndBacklogReceiveItem = function(ev, ui) {
  if (ui.item.hasClass('item')) {
    bs.item.dndDropHandler(ev, ui);
  }
};

bs.item.dndDropHandler = function(ev, ui) {
  var position = bs.item.findItemPositionIn("#backlog-items", ui.item);
  bs.item.drop(ui.item, position);
};

bs.item.dropClickHandler = function() {
  var item = $(this);
  if (item.hasClass('disabled')) { 
    return;
  }

  if (confirm('Are you sure you want to drop this item to backlog?')) {
    item.addClass('disabled');
    item.timeoutRemoveClass(2000, 'disabled');
    bs.item.drop(item.parents('.item'), 0);
  }
};

bs.item.backlogAppendCallback = function(data) {
  bs.item.factory({
    id: data.item,
    html: data.html,
    callback: bs.item.appendToProductBacklog,
    args: [ data.position ]
  });
  bs.tags.updateCloud(data.tags);
};

bs.item.drop = function(item, position) {
  var itemId = bs.item.getId(item);
  var url = removeItemFromSprintProjectSprintPath(bs._project, bs._sprintId);
  
  bs.post(url, {
    'item_id': itemId,
    'position': position
  }, bs.item.backlogAppendCallback, null, 'json');
};

bs.item.optionsForSortable = function(override) {
  var defaults = {
    axis: 'y',
    items: '.backlog-element',
    cancel: '.nosort, :input, option, a, img, div.marker-info, .tabbed-content',
    placeholder: 'placeholder',
    connectWith: '.backlog-items',
    opacity: '0.7',
    delay: 300,
    // fix for opera
    stop: function(e,ui) {
      ui.item.css({'top':'0','left':'0'})
    }
  };
  return $.extend(defaults, override);
};

bs.item.draggableBacklog = function() {
  var options = bs.item.optionsForSortable({
    start: bs.item.sortStartHandler,
    update: bs.item.backlogSortUpdateHandler,
    receive: bs.item.dndBacklogReceiveItem,
    deactivate: bs.marker.refreshMarkerInfos
  });
  $('#backlog-items:not(.read-only)').cssortable(options);
};

bs.item.draggableSprint = function() {
  var options = bs.item.optionsForSortable({
    start: bs.item.sortStartHandler,
    update: bs.item.sprintSortupdateHandler,
    receive: bs.item.dndAssignHandler,
    items: '.item'
  });
  $('#assigned-backlog-items:not(.read-only)').cssortable(options);
};

bs.item.hideFormContainers = function() {
  this.find('.form-container').hide();
};

bs.item.showWatermarks = function() {
  $("#item_user_story").watermark("As a ... I would like to ... so that ...", "#999");
  $("#item_description").watermark("*Acceptance criteria*\n\nI do this ...\nThis happens ...", "#999");
  $("#new_item_tag").watermark("Create new tag", "#999");
};

bs.item.newItemAjaxSuccessHandler = function(envelope) {
  var container = $('#new-item-form');
  // break if the form has been already activated
  if ( container.is(":visible") ) {
    return false;
  }
  bs.backlog.hideFormContainers();
  container.html(envelope.html).slideDown(function() {
    bs.item.showWatermarks();
    // focus on first form field
    container.find("input:visible:first").trigger('focus');
  });

  var success = function(envelope) {
    bs.item.factory({ 
      html: envelope.html,
      callback: function() {
        bs.item.appendToProductBacklog.call(this, envelope.position);
        bs.tags.updateCloud(envelope.tag_in_cloud);
        bs.backlog.formSlideUp(container, bs.item.showWatermarks);
        $(".empty-backlog-note").hide();
      }
    });
  };

  var error = function(resp) {
    var envelope = JSON.parse(resp.responseText);
    container.empty().html(envelope.html);
    bindForm();
  };

  var bindForm = function() {
    var form = container.find('form');
    // FIXME: this is temporary addition, so on server side
    // we know how to generate sprint assign button
    if (bs._sprintId) {
      form.append($("<input type='hidden' />")
        .attr('name', 'sprint').val(bs._sprintId));
    }
    bs.ajax.submitFormBinder(form, success, error, 'json');
  }
  
  bindForm();
};

bs.item.copyItemHandler = function(ev) {
  ev.preventDefault();
  ev.stopPropagation();
  var link = $(ev.target);
  var target = bs.getUrl(link);

  var success = function(envelope) {
    bs.item.factory({ 
      html: envelope.html,
      callback: function() {
        if (bs._sprintId) {
            bs.item.appendToSprint.call(this, envelope.position_in_sprint, bs._sprintId);
        } else {
            bs.item.appendToProductBacklog.call(this, envelope.position);
        }
        //bs.tags.updateCloud(envelope.tag_in_cloud);
      }
    });
  };

  var error = function(resp) {
    var envelope = JSON.parse(resp.responseText);
    alert(envelope);
  };
  bs.post(target, {}, success, error, 'json');
};

bs.item.newItemClickHandler = function(ev) {
  ev.preventDefault();
  ev.stopPropagation();
  var link = $(ev.target);
  var target = bs.getUrl(link);
  bs.get(target, {}, bs.item.newItemAjaxSuccessHandler, null, 'json');
};

bs.item.blockItem = function(id, msg) {
  $('#item-' + id).addClass('nosort');
  $('#item-' + id).block({
    message: msg + '&nbsp;(<a href="#" class="unlock">unlock</a>)',
    applyPlatformOpacityRules: false,
    css: {
      backgroundColor: '#C9D4F0',
      border: '1px solid #a6a1aA',
      fontSize: '11px',
      margin: '0px',
      padding: '0px' 
    },
    overlayCSS: {
      backgroundColor: '#dadafc'
    }
  });
};

bs.item.unblockItem = function(id) {
  $('#item-' + id).removeClass('nosort').unblock().css('position', '');
};

bs.item.allowInfiniteEstimate = function(item, allow) {
  var estimateElement = item.find('.item-estimate');
  if (allow) {
    estimateElement.addClass('infinite');
  } else {
    estimateElement.removeClass('infinite');
  }
};

/*
 * Shows forms for new task and new attachment if current item hasn't any
 * Triggered by bs:tabChanged event, see application.js
 */
bs.item.displayFormsIfEmpty = function() {
  var container = $(this);
  if (container.parents('.backlog-items').hasClass('read-only')) {
    return true;
  }
  // we don't want to catch click when item is being collapsed
  if (container.find('.expandable-link div').hasClass('expand')) {
    return true;
  }
  
  var tab = container.find(".current-tab-content");
  if (tab.hasClass("tab-content-tasks") && tab.find(".tasks li").length == 0) {
    container.find(".new-task-link").trigger('click');
  }
  else if(tab.hasClass("tab-content-attachments") && tab.find(".attachment-list li").length == 0) {
    container.find(".attach-file-link").trigger('click');
  }
  return true;
}

bs.item.appendToBacklog = function(item, backlog, position) {
  if (item.hasClass('single-item')) {   // do not touch the item if we are on single-item page
    return false;
  }
  item.find('form.editor-field').trigger('reset'); // close all inplaces, after removal all events, and jquery data would be lost (bug #800)
  item.detach(); // remove so it can be appended
  var afterRemoval = function() {
    backlog.appendAt(item, '.backlog-element', position);
    if (item.is(':visible')) {
      item.effect('highlight');
    }
    $(document).trigger('bs:backlogChanged');
    $(document).trigger('bs:backlogOrderChanged');
  };
  if ($.browser.msie && $.browser.version == 8) { /* this solves #902... really shity bug  */
    setTimeout(afterRemoval, 50);
  } else {
    return afterRemoval();
  }
  return false;
};

bs.item.appendToSprint = function(position, sprint_id) {
  if (position === undefined) { 
    position = -1;
  }
  var backlog = $('#assigned-backlog-items');
  if (! backlog.length) {
    backlog = $('.long-term-view.sprint-' + sprint_id);
  }
  bs.item.appendToBacklog(this, backlog, position);
  bs.item.allowInfiniteEstimate(this, false);
  $("#empty-sprint-msg").hide();
};

bs.item.appendToProductBacklog = function(position) {
  if (position === undefined) { 
    position = 0;
  }
  bs.item.appendToBacklog(this, $('#backlog-items'), position);
  bs.item.allowInfiniteEstimate(this, true);
};

bs.item.doRemove = function(callback) {
  var item = this;
  item.fadeOut(function() { 
    item.remove();
    if (callback) {
      callback.call();
    }
    $(document).trigger('bs:backlogChanged');
    $(document).trigger('bs:backlogOrderChanged');
  });
};

bs.item.appendTag = function(envelope) {
  var tag_in_cloud = $('#tag-' + envelope.tag_id);
  if (tag_in_cloud.length === 0) {
    bs.tags.appendTag({html: envelope.tag_in_cloud})
  }
  var tagList = this.find('.tags-list');
  var newTag = $(envelope.html);
  tagList.append(newTag);
  if (newTag.is(":visible")) {
    newTag.highlight();
  }
  
  bs.tags.notify(bs.tags.tagName(newTag));
};

bs.item.addAttachment = function(html) {
  this.find('.attachment-list').append(html);
  this.find('.new-attachment').slideUp(function() {$(this).trigger('bs:itemSizeChanged');});
  
  $(document).trigger('bs:attachmentEvent');
};

bs.item.setNumberOfComments = function(number) {
  this.find('.show-comments-link span.item-log').text("[" + number + "]"); // this is for OLD LAYOUT
  this.find('.number-of-comments').text(number);
  this.effect('highlight')
};

bs.item.findTask = function(id) {
  return this.find('#task-' + id);
};

$.fn.findTask = bs.item.findTask;

bs.item.hideNewTaskForm = function() {
  var item = this;
  bs.backlog.formSlideUp(this.find('.new-task'));
  
};

bs.item.refreshEmptySprintMessage = function() {
  if ($('#assigned-backlog-items li.item').length === 0) { 
    $("#empty-sprint-msg").show();
  }
};

bs.item.hideMoreLinkIfUnnecessary = function(ev) {
  var item = $(ev.target).closest('.item'); 
  var link = item.find('a.more-less-button');
  var innerHeight = item.find('.text-wrapper').height();
  var outer = item.find('.item-description-text');
  var outerHeight = outer.height();
  var alreadyExpanded = !outer.hasClass('truncated');
  link.setClassIf(!alreadyExpanded && (innerHeight <= outerHeight), 'hidden');
};
