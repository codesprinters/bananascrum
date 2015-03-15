bs.juggernaut = {};

bs.juggernaut.callbacks = {};

// This method handles all messages that are recived from juggernaut
Juggernaut.fn.recivedData = function(msg) {
  var data = msg.body;
  if (data.session_id && data.session_id == bs._sessionId) { 
    return;   // ignore events triggered by our client
  }
  if (bs.sprint.checkIfDifferent(data.envelope['_sprint_id'])) {
    return;
  }
  bs.envelope.handle(data.envelope);
    
  var env = bs.unpackLayoutInformation(data.envelope);  // hack to choose proper html new for given layout. REMOVE THIS when old layout is gone
  
  var callback = bs.juggernaut.callbacks[data.operation];
  
  if (! $.isFunction(callback)) {
    console.log('Callback for operation ' + data.operation + ' is not defined!');
    return false;
  }
  setTimeout(function() { 
    callback.call(null, env);
  }, 0); // callback proccesed out of the flash object stack
};

bs.juggernaut.registerCallback = function(operation, callback) {
  if (bs.juggernaut.callbacks[operation])  {
    console.log('Callback for operation ' + operation + ' already defined!');
    return false;
  }
  bs.juggernaut.callbacks[operation] = callback;
};

bs.juggernaut.currentLocks = function(data) {
  // message always sent after client connects, current_locks
  // contains id's of all locked items
  if (data.locks) {
    $(data.locks).each(function(index, lockId) {
      bs.item.blockItem(lockId, "currently locked");
    });
  }
  bs.juggernaut.connectedUsers(data);
};

bs.juggernaut._locked = function(lock) {
  bs.item.blockItem(lock.item, lock.locked_by_name + " is currently " + lock.operation);
};

bs.juggernaut.sprintDeleted = function(data) {
  if (bs._sprintId && bs._sprintId == data.id) {
    document.location = projectSprintsPath(bs._project);
  }
};

bs.juggernaut.itemDescription = function(data) {
  bs.item.factory({id: data.item, callback: function(data) {
    this.find('.item-description-text form').trigger('reset');
    bs.item.setDescription.call(this, data);
  }, args: [ data ]});
};

bs.juggernaut.itemEstimate = function(data) {
  bs.item.factory({ id: data.item, args: [ data ], callback: function(data) {
    bs.item.updateEstimate.call(this, data);
    this.highlight();
  }});
};

bs.juggernaut.itemUserStory = function(data) {
  var set_story = function(text) {
    this.effect('highlight').find('.item-user-story').html(text);
  };

  bs.item.factory({ id: data.item, callback: set_story, args: [ data.value ]});
};


bs.juggernaut.itemAppendTag = function(data) {
  bs.item.factory({ id: data.item, callback: bs.item.appendTag, args: [ data ]});
};

bs.juggernaut.itemRemoveTag = function(data) {
  var remove_tag = function(tag) {
    this.find('li.tag:has(span[innerHTML=' + tag + '])').remove();
    bs.tags.notify();
  };
  bs.item.factory({ id: data.item, callback: remove_tag, args: [ data.tag ]});
};

bs.juggernaut.itemAttachmentAdd = function(data) {
  bs.item.factory({ id: data.item, callback: bs.item.addAttachment, args: [ data.html ]});
};

bs.juggernaut.itemAttachmenRemove = function(data) {
  var removeAttachment = function(id) {
    var element = this.find("#file_" + id);
    element.fadeOut('normal', function() {
      element.remove(); 
      $(document).trigger('bs:attachmentEvent');
    });
  };

  bs.item.factory({ id: data.item, onPageOnly: true, callback: removeAttachment, args: [ data.asset_id ]});
};

bs.juggernaut.disconnected = function(data) {
  $.each(data.unlocked, function(index, id) {
    bs.item.unblockItem(id);
  });
};

bs.juggernaut.connectedUsers = function(data) {
  $('#juggernaut-info-box .juggernaut-users').html(data.logged_users);
}

$(document).ready(function() {
  bs.juggernaut.registerCallback('disconnected', bs.juggernaut.disconnected);
  bs.juggernaut.registerCallback('current_locks', bs.juggernaut.currentLocks);
  bs.juggernaut.registerCallback('items/unlock', function() {} ); // unlocking is handled by envelope
  bs.juggernaut.registerCallback('items/lock', bs.juggernaut._locked);
  bs.juggernaut.registerCallback('sprints/sort', bs.item.sprintAppendCallback);
  bs.juggernaut.registerCallback('sprints/assign_item_to_sprint', bs.item.sprintAppendCallback);
  bs.juggernaut.registerCallback('sprints/remove_item_from_sprint', bs.item.backlogAppendCallback);
  bs.juggernaut.registerCallback('sprints/destroy', bs.juggernaut.sprintDeleted);
  bs.juggernaut.registerCallback('sprints/update', bs.sprint.update);
  bs.juggernaut.registerCallback('items/sort', bs.item.backlogAppendCallback);
  bs.juggernaut.registerCallback('items/create', bs.item.backlogAppendCallback);
  bs.juggernaut.registerCallback('items/destroy', bs.item.remove);
  bs.juggernaut.registerCallback('items/import_csv', bs.backlog.importItems);
  bs.juggernaut.registerCallback('items/bulk_add', bs.backlog.importItems);
  bs.juggernaut.registerCallback('items/backlog_item_description', bs.juggernaut.itemDescription);
  bs.juggernaut.registerCallback('items/backlog_item_estimate', bs.juggernaut.itemEstimate);
  bs.juggernaut.registerCallback('items/backlog_item_user_story', bs.juggernaut.itemUserStory);
  bs.juggernaut.registerCallback('backlog_item_tags/create', bs.juggernaut.itemAppendTag);
  bs.juggernaut.registerCallback('backlog_item_tags/destroy', bs.juggernaut.itemRemoveTag);
  bs.juggernaut.registerCallback('attachments/create', bs.juggernaut.itemAttachmentAdd);
  bs.juggernaut.registerCallback('attachments/destroy', bs.juggernaut.itemAttachmenRemove);
  bs.juggernaut.registerCallback('comments/create', bs.comments.createSuccess);
  bs.juggernaut.registerCallback('tags/create', bs.tags.appendTag);
  bs.juggernaut.registerCallback('tags/update', bs.tags.updateTag);
  bs.juggernaut.registerCallback('tags/destroy', bs.tags.deleteTag);
  bs.juggernaut.registerCallback('tasks/create', bs.task.add);
  bs.juggernaut.registerCallback('tasks/destroy', bs.task.destroy);
  bs.juggernaut.registerCallback('tasks/sort', bs.task.reorder);
  bs.juggernaut.registerCallback('tasks/assign', bs.task.assignUser);
  bs.juggernaut.registerCallback('tasks/task_estimate', bs.task.setEstimate);
  bs.juggernaut.registerCallback('tasks/task_summary', bs.task.setSummary);
  bs.juggernaut.registerCallback('impediments/impediment_summary', bs.impediment.setSummary);
  bs.juggernaut.registerCallback('impediments/impediment_description', bs.impediment.setDescription);
  bs.juggernaut.registerCallback('impediments/create_comment', bs.impediment.addComment);
  bs.juggernaut.registerCallback('impediments/create', bs.impediment.add);
  bs.juggernaut.registerCallback('impediments/destroy', bs.impediment.destroy);
  bs.juggernaut.registerCallback('impediments/status', bs.impediment.substitute);
  bs.juggernaut.registerCallback('planning_markers/distribute', bs.marker.distributeSuccess);
  bs.juggernaut.registerCallback('planning_markers/create', bs.marker.createHandler);
  bs.juggernaut.registerCallback('planning_markers/update', bs.marker.updateHandler);
  bs.juggernaut.registerCallback('planning_markers/destroy', bs.marker.destroyHandler);
  bs.juggernaut.registerCallback('planning_markers/destroy_all', bs.marker.destroyAllHandler);
  bs.juggernaut.registerCallback('connected_users', bs.juggernaut.connectedUsers);
});
