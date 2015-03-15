// Namespace for tags related code
bs.tags = { };

bs.tags.tagName = function(tagContainer) {
  return tagContainer.find('.tag-name').text();
};

bs.tags.tagDescription = function(tagContainer) {
  return tagContainer.find('.tag-description').text();
};

bs.tags.attribute = function(tagField) {
  if (tagField.hasClass('tag-name')) {
    return 'name';
  } else if (tagField.hasClass('tag-description')) {
    return 'description';
  }
  return null;
}

bs.tags.notify = function(tagChangedData) {
  if (tagChangedData) {
    $(document).trigger('bs:tagEvent', [tagChangedData]);
  } else {
    $(document).trigger('bs:tagEvent');
  }
};

bs.tags.appendTag = function(envelope) {
  var tag = $(envelope.html);
  var tagName = bs.tags.tagName(tag);
  var tagNameLower = tagName.toLowerCase();
  
  var findPrecedor = function(tagNameLower) { //return the element to append the tag after or false (append at the beggining)
    var tagsInCloud = $('#tag-cloud-list .tag-cloud-item');
    var tagAtIndex = function(index) {
      return $(tagsInCloud[index]);
    };
    
    var isBefore = function(index) {
      var name = bs.tags.tagName(tagAtIndex(index)).toLowerCase();
      return (name > tagNameLower);
    };
    
    var first = 0;
    var last = tagsInCloud.length - 1;
    if (last === -1 || isBefore(first)) {
      return false;
    }
    if (! isBefore(last)) {
      return tagAtIndex(last);
    }
    while((last - first) > 1) {
      var toTest = Math.ceil(first + ((last - first) / 2));
      if (isBefore(toTest)) {
        last = toTest;
      } else {
        first = toTest;
      }
    }
    return tagAtIndex(first);
  };
  
  var precedor = findPrecedor(tagNameLower);
  if (precedor) {
    tag.insertAfter(precedor);
  } else {
    $('#tag-cloud-list').prepend(tag);
  }
  if (tag.is(":visible")) {
    tag.effect('highlight', {}, 500);
  }
  
  var tagChangedData = {'tagName': tagName};
  bs.tags.notify(tagChangedData);
};

bs.tags.updateTag = function(envelope) {
  var tag = $('#tag-' + envelope.id);
  var newTag = $(envelope.html);
  tag.replaceWith(newTag);
  newTag.effect('highlight', {}, 500);
  
  var tagsAssigned = $('.tag.tag-' + envelope.id);
  var tagName = bs.tags.tagName(newTag);
  var tagColorNo = envelope.color_no;
  var tagDescription = bs.tags.tagDescription(newTag);
  var tagContainer = tagsAssigned.find('.tag-name');

  tagContainer.html(tagName);
  tagContainer.attr('title', tagDescription);
  tagsAssigned.effect('highlight', {}, 500);
  var tagChangedData = {'tagName': tagName, 'tagColorNo': tagColorNo, 'tagId': envelope.id};
  bs.tags.notify(tagChangedData);
};

bs.tags.deleteTag = function(envelope) {
  var tag = $('#tag-' + envelope.id);
  var tags = $('.tag-' + envelope.id).add(tag);
  tags.fadeOut(function() {
    tags.remove();
    bs.tags.manager.clearFilters();
  });
  return false;
};

bs.tags.deleteTagClickHandler = function(ev) {
  var link = $(this);
  
  if (link.hasClass('disabled')) {
    return false;
  }
  link.addClass('disabled').timeoutRemoveClass(2000, 'disabled');
  var url = bs.getUrl(link);

  bs.destroy(url, {}, bs.tags.deleteTag, null, 'json');
  return false;
};

bs.tags.manageTagsClickHandler = function(ev) {
  var link = $(this);
  var tagCloud = link.parents('.tag-cloud');
  
  if (tagCloud.hasClass('hidden-controlls')) {
    tagCloud.removeClass('hidden-controlls');
    tagCloud.addClass('visible-controlls');

    bs.tags.uncheckTagsHandler();
    link.text('Close');
  } else {
    tagCloud.addClass('hidden-controlls');
    tagCloud.removeClass('visible-controlls');

    tagCloud.find('.editor-field').trigger('reset');
    link.text('Manage tags');
    tagCloud.find('.tag-name').cseditable('destroy').data('binder.was_bound', false);
  }

  return false;
};

bs.tags.uncheckTagsHandler = function(ev) {
  bs.tags.manager.clearFilters();
  $(document).trigger('bs:tagClicked');
  return false;
};

bs.tags.tagClickHandler = function(ev) {
  bs.tags.manager.tagClickHandler.call(this, ev);
  $(document).trigger('bs:backlogChanged');
  $(document).trigger('bs:tagClicked');
  return false;
};

// Controls for tags on items
bs.tags.deattachTagClickHandler = function(ev) {
  var link = $(this);
  // handles old and new layout, when removing old layout just remove 'if' statement
  if (!link.is("a")) {
    link = link.find("a");
  }

  var url = bs.getUrl(link);

  var success = function() {
    var tag = link.parents('.tag');
    tag.fadeOut('normal', function() {
      tag.remove();
      var tagName = bs.tags.tagName(tag);
      var tagChangedData = {'tagName': tagName};
      bs.tags.notify(tagChangedData);
    });
  };

  bs.destroy(url, {}, success, null, 'json');
  return false;
};

bs.tags.assignTagFormClickHandler = function(ev) {
  var link = $(this);
  var item_id = bs.item.getId(link);
  var url = bs.getUrl(link);
  var container = link.parents('.assign-tag-form');
  var containerOldHtml = container.html();
  var killAndHide;
  bs.item.factory({child: link, callback: bs.mutex.lock, args: [item_id]});
  $('input').blur();

  var hideForm = function () {
    container.html(containerOldHtml);
    return false;
  };

  var submitComplete = function(envelope) {
    bs.item.factory({child: container, callback: bs.item.appendTag, args: [ envelope ]});
    killAndHide();
  };

  var error = function () {
    killAndHide();
    // silent fail
  }; 
  
  var success = function(envelope) {
    container.html(envelope.html);
    var form = container.find('form');
    var select = form.find('select');
    select.change(function() {form.submit();});
    var input = form.find('input#tag');
    input.focus();
    var au = input.autocomplete({ 
      lookup: envelope.tags,
      onSelect: function() {form.submit();}
    })[0];
    
    if ($.browser.msie) { /* Have to wait for the reflow before we can focus. Fixes #866 */
      setTimeout(function() {input.focus();}, 50);
    }
    au.onValueChange();

    killAndHide = function() {
      bs.item.factory({child: container, callback: bs.mutex.unlock, args: [item_id]});
      au.killSuggestions();
      hideForm();
      killAndHide = function () {};
    };

    var killerFn = function(e) {  // this is bound on 'click' to body after the blur event
      if (($(e.target).parents('.autocomplete').size() === 0) && ($(e.target).parents('.assign-tag-form').size()) === 0) { //click not on suggestion nor submit button
        killAndHide();
      }
    };
    au.killerFn = killerFn;
  
    form.submit(function(ev) {
      if ($.trim(input.val()) === "") {
        killAndHide();
        return false;
      }
      bs.ajax.submitForm(submitComplete, error, 'json').call(this, ev);
      return false;
    });

    input.bind($.browser.opera ? 'keypress' : 'keydown', function(e) {
      if (e.keyCode == 27) {
        killAndHide();
        return false;
      }

    });
     
    form.find('.cancel').click(function () { 
      killAndHide();
      return false;
    });

    return false;
  };

  bs.get(url, {}, success, null, 'json');

  return false;
};

// Creates tags manager responsible for applying tags filters
bs.tags.createTagsManager = function() {

  // stores filters info, tag_id is key and tag DOM element is value
  var activeTagsFilters = {
    'filtered-in': {},
    'filtered-out': {}
  };

  var addToFilter = function(filterName, tag) {
    var id = tag.attr('id');
    activeTagsFilters[filterName][id] = tag;
    tag.addClass(filterName);
  };

  var removeFromFilter = function(filterName, tag) {
    delete activeTagsFilters[filterName][tag.attr('id')];
    tag.removeClass(filterName);
  };

  var clearFilters = function() {
    activeTagsFilters = {
      'filtered-in': {},
      'filtered-out': {}
    };
    $('.tag-cloud-item').removeClass('filtered-in').removeClass('filtered-out');
    $(document).trigger('bs:backlogChanged');
  };

  var toFilterIn  = function(tag) {
    addToFilter('filtered-in', tag);
    filterItems($('.item.visible'));
  };

  var toFilterOut = function(tag) {
    removeFromFilter('filtered-in', tag);
    addToFilter('filtered-out', tag);
    filterItems();
  };

  var turnOffFilter = function(tag) {
    removeFromFilter('filtered-out', tag);
    filterItems();
  };

  var enabled = function() {
    var key = null;
    for (key in activeTagsFilters['filtered-in']) {
      if (activeTagsFilters['filtered-in'].hasOwnProperty(key)) {
        return true;
      }
    }
    key = null;
    for (key in activeTagsFilters['filtered-out']) {
      if (activeTagsFilters['filtered-out'].hasOwnProperty(key)) {
        return true;
      }
    }
    return false;
  };

  var itemWithTagExpr = function(tagId) {
    return '.item:has(.' + tagId + ')';
  };

  // very simple algorithm: hide all and decide what to show
  // again by stacking $ filters
  // @param items  filtering scope (aka items that will be
  //               touched), if none, all items is assumed
  var filterItems = function(items) {
    items = items || $('.item');
    var hasTag = "";
    var toShow = items.data('visible', false);

    $.each(activeTagsFilters['filtered-in'], function(inTagId) {
      hasTag = itemWithTagExpr(inTagId);
      toShow = toShow.filter(hasTag);
    });

    $.each(activeTagsFilters['filtered-out'], function(outTagId) {
      hasTag = itemWithTagExpr(outTagId);
      toShow = toShow.not(hasTag);
    });

    toShow.data('visible', true);
  };

  var tagClickHandler = function(ev) {
    var tag = $(this).closest('.tag-cloud-item');
    if (tag.hasClass('filtered-in')) {
      toFilterOut(tag);
    } else if (tag.hasClass('filtered-out')) {
      turnOffFilter(tag);
    } else {
      toFilterIn(tag);
    }
    return false;
  };

  // public methods
  return {
    tagClickHandler: tagClickHandler,
    clearFilters: clearFilters,
    filterItems: filterItems,
    enabled: enabled
  };
};

// single instance
bs.tags.manager = bs.tags.createTagsManager();

bs.tags.recountTags = function() {
  $('.tag-cloud-item').each(function(index, element) {
    element = $(element);
    var count = $('.' + element.attr('id')).length;
    var tagCount = element.find('.tag-count');
    if (tagCount.length > 0) {
      tagCount.html(count);
    }
  });
};

bs.tags.updateColors = function(ev, data) {
  if (data['tagColorNo']) {
    var colorNo = data['tagColorNo'];
    var tagId = data['tagId'];
    var tagsAssigned = $('.tag.tag-' + tagId);
    if (tagsAssigned.length) {
      var classes = $(tagsAssigned).attr("class").split(' ');
      for (i = 0; i < classes.length; i++) {
        var className = classes[i];
        if (className.match(/tag-color-\d/)) {
          $(tagsAssigned).removeClass(classes[i]);
          $(tagsAssigned).addClass('tag-color-' + colorNo);
        }
      }
    }
  }
};

bs.tags.setDescription = function() {
  var link = $(this);
  var tag = link.parent('.tag-cloud-item').find('.tag-description');
  tag.trigger('click');
  return false;
};

bs.tags.editable = function() {
  var tag = $(this);
  tag.data('item_description.original_html', tag.html());
  tag.cseditable({
    type: 'text',
    submit: 'OK',
    cancelLink: 'Cancel',
    editClass: 'editor-field edit-tag-form',
    startEditing: true,
    onSubmit: bs.tags.onSubmit
  });
};

bs.tags.onSubmit = function(values, errorHandler) {
  var tagField = $(this);

  var id = bs.modelId(tagField, '.tag-cloud-item', 'tag-');
  var attribute = bs.tags.attribute(tagField);
  if (! id || ! attribute) {
    return false;
  }
  var action = projectTagPath(bs._project, id);

  var params = {};
  params['tag[' + attribute + ']'] = values.current;
  
  bs.put(action, params, bs.tags.updateTag, errorHandler, 'json');
};

bs.tags.updateCloud = function(tags) {
  if (tags) {
    var list = $(tags);
    list.each(function() {
      bs.tags.appendTag({html : this});
    });
  }
};

/**
 * Functions to handle tags list when creating new backlog item.
 */
bs.tags.list = {};
bs.tags.list.createTagInputHandle = function(e) {
  var input = $(this);
  if (e.keyCode == 13) {
    e.preventDefault();
    e.stopPropagation();
    var tag = e.target.value;
    input.val("");
    $(document).trigger('bs:tagListEvent', [{"tagName" : tag, "checked" : true}]);
  }
};


bs.tags.list.findTag = function(tag, tagList) {
  tagList = tagList || $(".checkbox-dropdown");
  var labelElem = null;

  // checks if tag is already there
  $.each(tagList.children("label"), function() {
    if (tag === $(this).text()) {
      labelElem = $(this);
      return;
    }
  });

  return labelElem;
};

/**
 * Marks given li element with tag as checked
 * @param {Object} labelElement jQuery object with li element with tag inside
 */
bs.tags.list.markChecked = function(labelElement) {
  var tagList = $(".checkbox-dropdown");
  if (tagList.length === 0) {
    return false;
  }

  labelElement.addClass("checked").find("input").attr("checked", "checked");
  tagList.scrollTop(0); // go to the top
  var tagY = labelElement[0].offsetTop; // get Y axis of element relatively to the list
  tagList.scrollTop(tagY); // scroll to element
  return false;
};

bs.tags.list.addToSelect = function(tag, tagList) {
  tagList = tagList || $(".new-item .checkbox-dropdown");
  var labelElement = bs.tags.list.findTag(tag, tagList);
  if (labelElement) {
    return labelElement;
  }
  var tagId = "new_tag_" + tag;
  labelElement = $("<label>").attr('for', tagId).text(tag);
  var inputDiv = $("<input/>").addClass("checkbox-dropdown-input").
    attr('type', "checkbox").attr('value', tag).attr("name", "new_tags[" + tagId + "]");
  tagList.append(labelElement.prepend(inputDiv));
  return labelElement;
};

/**
 * Triggered by bs:tagListEvent and bs:tagEvent
 * Appends tag to taglist if it's not there.
 * If tagHash has checked option to set to true element will be checked on the
 * list as selected.
 * @param {Object} event
 * @param {Object} tagHash Object with following format {"tagName" : tag, "checked" : true}
 */
bs.tags.list.update = function(event, tagHash) {
  if (tagHash && tagHash.tagName) {
    var labelElement = bs.tags.list.addToSelect(tagHash.tagName);
    if (tagHash.checked) {
      bs.tags.list.markChecked(labelElement);
    }
  }
  return false;
};

bs.tags.submitNewTag = function() {
  var tag = $(this).find("input[name='tag']").attr('value');
  if (tag === "") { 
    return false;
  }
  $(this).trigger('reset');
  bs.post(projectTagsPath(bs._project), {'tag[name]': tag}, bs.tags.appendTag, null, 'json');
  return false;
};

bs.tags.toggleTagDeleteClass = function() {
  $(this).toggleClass('show-delete')
  return false;
};


bs.tags.tagLabelHandler = function(ev) {
  var element = $(ev.target);
  if (!element.hasClass("opened")) {
    return element.tagLabel();
  }
  return false;
}

// "main"
$(document).ready(function() {

  $("#manage-tags-link").click(bs.tags.manageTagsClickHandler);
  $('#uncheck-tags-link').click(bs.tags.uncheckTagsHandler);

  $(".tag-cloud.hidden-controlls .tag-cloud-item").live('click', bs.tags.tagClickHandler);

  $(".tag-cloud:not(.hidden-controlls) .tag-name").live('click', bs.buildBinder(bs.tags.editable));
  $(".tag-cloud:not(.hidden-controlls) .tag-description").live('click', bs.buildBinder(bs.tags.editable));
  $(".set-tag-description-link").live('click', bs.tags.setDescription);

  $(".tag-cloud-controls .destroy").live('click', bs.tags.deleteTagClickHandler);

  var backlogItemsEditable = $(".backlog-items:not(.read-only)");
  $('.deattach-tag-link', backlogItemsEditable).live('click', bs.tags.deattachTagClickHandler);
  $(".assign-tag-form-link", backlogItemsEditable).live('click', bs.tags.assignTagFormClickHandler);
  $(".tag", backlogItemsEditable).live('mouseenter', bs.tags.toggleTagDeleteClass);
  $(".tag", backlogItemsEditable).live('mouseleave', bs.tags.toggleTagDeleteClass);
  $(".set-tag-color").live('click', bs.tags.tagLabelHandler);
  
  $(document).bind('bs:backlogChanged', bs.tags.recountTags);
  $(document).bind('bs:tagEvent', bs.tags.recountTags);
  $(document).bind('bs:tagListEvent', bs.tags.list.update);
  $(document).bind('bs:tagEvent', bs.tags.list.update);
  $(document).bind('bs:tagEvent', bs.tags.updateColors);

  $("#new_item_tag").live(($.browser.opera ? 'keypress' : 'keydown'), bs.tags.list.createTagInputHandle);
  bs.tags.recountTags();

  $(".tag-cloud form.assign-tag-form").live('submit', bs.tags.submitNewTag);
  if ($.browser.msie) {
    $(".tag-cloud form.assign-tag-form input[type='submit']").live('click', function() { bs.tags.submitNewTag.call($(this).parent()); return false;});
  }
});
