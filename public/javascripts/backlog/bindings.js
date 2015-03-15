// "main"
$(function () {
  var backlogItemsEditable = $(".backlog-items:not(.read-only)");
  var backlogItemsEditableItems = backlogItemsEditable.find(".item");
  var backlogItemsEditableTasks = backlogItemsEditable.find(".task");


  $(backlogItemsEditableTasks.find('.task-users')).live('click',
    bs.buildBinder(bs.task.editableUser));
  $(backlogItemsEditableTasks.find('.task-estimate')).live('click',
    bs.buildBinder(bs.task.editableEstimate));

  $('.task-summary', backlogItemsEditableTasks).live('click',
    bs.buildBinder(bs.task.editableSummary));

  // unfortunatelly this is located elsewhere in old layout so we cannot
  // simply narrow the search by adding context
  $('.new-comment input.button:visible').live('click',
    bs.buildBinder(bs.comments.bindForm));

  $('a.more-less-button', $(".item")).live('click', function(ev) {
    bs.backlog.toggleDescriptionMoreLess.call(ev.target);
    return false;
  });

  //  Item related
  $('.item-description-text a', $('.item')).live('click', bs.openLink)
  $('.item-description-text', backlogItemsEditableItems).live('click',
      bs.buildBinder(bs.item.editableDescription));
  $('.item-user-story', backlogItemsEditableItems).live('click',
      bs.buildBinder(bs.item.editableUserStory));
  $('.item-estimate', backlogItemsEditableItems).live('click',
      bs.buildBinder(bs.item.editableEstimate));
  $('img.delete-item', backlogItemsEditableItems.find(".controls")).live('click', bs.item.handleDelete);
  backlogItemsEditableItems.bind('bs:tabChanged', bs.item.displayFormsIfEmpty);
  $('#new-item-form').live('reset', function() {
    $('.checkbox-dropdown input').trigger('change');
  });
  $('.drop-arrow:not(:hidden)', backlogItemsEditableItems).live('click', bs.item.dropClickHandler);
  $('.assign-arrow:not(:hidden)', backlogItemsEditableItems).live('click', bs.item.assignClickHandler);
  $('a.attach-file-link:not(:hidden)',backlogItemsEditableItems).live('click', bs.attachments.attachFileClickHandler);
  $('#item-history').itemlogs();
  $('.task:not(.done) .tick', backlogItemsEditable).live('click', bs.task.close);

  // Impediment related
  var impedimentsContainer = $("#impediments_container")[0];
  $('.impediment-description a', impedimentsContainer).live('click', bs.openLink)
  $('.impediment-name', impedimentsContainer).live('click',
      bs.buildBinder(bs.impediment.editableSummary));
  $('.impediment-description', impedimentsContainer).live('click',
      bs.buildBinder(bs.impediment.editableDescription));
  $('a.new-impediment-comment', impedimentsContainer).live('click', bs.impediment.newCommentClickHandler);
  $('img.delete-task', backlogItemsEditableTasks.find(".controls")).live('click', bs.task.handleDelete);
  $('img.delete-impediment', impedimentsContainer).live('click', bs.impediment.handleDelete);
  // Cannot use live -- submit is not handled propertly in IE
  $(impedimentsContainer).find('form.impediment-status-form').submit(bs.impediment.statusSubmitHandler);
  //actions for impediment in new layout
  $('a.post-impediment-comment', $(".impediment")).live('click', bs.impediment.postCommentClick);
  $('a.close-impediment, a.reopen-impediment', $(".impediment")).live('click', bs.impediment.changeStatusClick);
  $('#new-impediment', $("#impediments-info-box")[0]).live('click', bs.impediment.newImpedimentDialog);

  // navcotainer links
  var navcontainer = $("#navcontainer");
  $('a.new-backlog-item').bind('click', bs.item.newItemClickHandler); // damn old/new layout differences
  navcontainer.find('a.bulk-add-items').bind('click', bs.backlog.bulkAddClickHandler);
  navcontainer.find('a.new-impediment').bind('click', bs.impediment.newImpedimentClickHandler);
  navcontainer.find('a.attach-import-file-link').live('click', bs.backlog.attachImportFileClickHandler);
  $('a.new-task-link', backlogItemsEditableItems).live('click', bs.task.newTaskClickHandler);
  $(".navcontainer").find('a.index-cards').bind('click', bs.backlog.handleIndexCardsModalWindow);
  $('a.copy-item-link').live('click', bs.item.copyItemHandler);

  $('.unlock').live('click', function() {
    bs.mutex.unlock(bs.item.getId($(this)));
    $(this).closest('.item').unblock();
    return false;
  });
  $('ul.tasks:not(.ui-sortable)', backlogItemsEditable).live('mouseover', bs.task.makeSortable);
  bs.item.draggableBacklog();
  bs.item.draggableSprint();
  bs.marker.init();
  bs.sprint.setupFilter();

  $('form.double-submit-blocked').live('submit', bs.blockOnSubmit);
  $('.checkbox-dropdown input').live('change', bs.backlog.checkboxDropdownChange);
  $('.checkbox-dropdown label').live('click', bs.backlog.checkboxDropdownLabelClick);
  $('form.formal-link a').live('click', bs.formalLinkClick);
  $(document).bind('bs:backlogChanged', bs.processFilters);
  $(document).bind('bs:backlogChanged', bs.item.refreshEmptySprintMessage);
  $(document).bind('bs:backlogChanged', bs.stats.refreshSprintStats);
  $(document).bind('bs:backlogChanged', bs.stats.refreshBacklogStats);
  $(document).bind('bs:backlogChanged', bs.backlog.refreshNoItemsMessage);

  $(document).bind('bs:backlogOrderChanged', bs.marker.refreshMarkerInfos);

  $(document).bind('bs:itemChanged', bs.item.hideMoreLinkIfUnnecessary);

  $(document).trigger('bs:backlogChanged');
  // Bind this callback later, to avoid unneccessary processing at startup
  // (it's lengthy)
  $(document).bind('bs:backlogChanged', bs.marker.refreshMarkerInfos);
 
  $('.velocity-input').watermark('Velocity');
  $('#user_activation_key').watermark("Activation key", '#999');
  $('.domain-remove-container #key').watermark("Validation key", '#999');
  $('#split-bar').click(bs.toggleSplitBar);
  $('.theme-name').live('click', bs.buildBinder(bs.profile.editableTheme));
  $(window).resize(bs.burnchart.resize);
  $('a[rel="facebox"]').live('click', bs.dialog.faceboxLink);
  $('#edit-customer-link').live('click', bs.admin.editCustomerLinkClick);
  $(".change-plan-form,form.domain-activation").submit(bs.admin.submitFromCreatingCustomerFirst);
  
  $('#flash-container').live('click', bs.flash.hide);
  setTimeout(bs.flash.hide, 3000);
});
