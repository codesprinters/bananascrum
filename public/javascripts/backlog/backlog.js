// Namespace for various backlog related functions

bs.backlog = {};

bs.backlog.suppressHighlight = function() {
  // TODO: remove title
  jQuery(this).removeClass('highlight');
};

bs.backlog.enableHighlight = function() {
  // TODO: add title back
  jQuery(this).addClass('highlight');
};

/**
 * Helper function for ajax complete handler
 * @param {Object} element jQuery selector
 * @param {Object} data data returned from server
 */
bs.backlog.ajaxCompleteHandler = function(element, data) {
  element.addClass('highlight').html(data);
};

bs.backlog.toggleDescriptionMoreLess = function(expand) {
  var button = jQuery(this);
  var desc = button.closest('.item-description').find('.item-description-text');

  if (desc.hasClass('truncated') || expand) {
    desc.removeClass('truncated');
    button.text('Show less');
  } else {
    desc.addClass('truncated');
    button.text('Show more');
  }
  button.trigger('bs:itemSizeChanged');
};

/**
 * Helper function that sends submit when inplace form is to be submitted
 * It submits form only if values.previous is different then values.current
 * @param {Object} element jQuery selector
 * @param {String} action path to submit action
 * @param {Object} values hash with keys current and previous which stores
 *        modified value of inplace element and value that was there previously
 * @param {function} complete (optional) function called when ajax request is
 *        completed. Defaults to bs.backlog.ajaxCompleteHandler
 */
bs.backlog.inplaceSubmitHandler = function(element, action, values, complete, error, type) {
  if (typeof(type) == 'undefined') { 
    type = 'json';
  }

  if (!jQuery.isFunction(complete)) {
    complete = function(data) {
      bs.backlog.ajaxCompleteHandler(element, data.value);
    };
  }

  if (!jQuery.isFunction(error)) {
    error = function(data) {
      bs.backlog.ajaxCompleteHandler(element, values.previous);
    };
  }

  // Visual indicator
  element.text('Saving...');
  bs.post(action, { value: values.current }, complete, error, type);
};

bs.backlog.hideFormContainers = function () {
  $('.form-container:not(.new-task, .new-attachment)').hide();
};

bs.backlog.checkboxDropdownChange = function() {
  $(this).parent().setClassIf($(this).attr('checked'), 'checked');
};

bs.backlog.checkboxDropdownLabelClick = function() {
  $(this).find('input').change();
};

bs.backlog.attachImportFileClickHandler = function(ev) {
  var link = jQuery(ev.target);
  var target = bs.getUrl(link);

  if (bs._layout == "new") {
    bs.dialog.loadToModal(target, null, bs.backlog.setupImportAjaxUpload);
    
  } else {
  
    var success = function(envelope) {
      bs.backlog.hideFormContainers();
      var container = $('#import-csv-form');
      container.html(envelope.html).slideDown();
      bs.backlog.setupImportAjaxUpload(container);
    };
  
    bs.get(target, {}, success, null, 'json');
  }
  ev.stopPropagation();
  ev.preventDefault();
  return false;
};

/**
 * Prepends items stored as html to backlog
 * @param {String} itemsHtml html portion containing items
 */
bs.backlog.prependNewItems = function(itemsHtml) {
  if (itemsHtml && itemsHtml.length) {
    $('#backlog-items').prepend(itemsHtml);
    $(document).trigger('bs:backlog_changed');
  }
}

bs.backlog.setupImportAjaxUpload = function(container) {
  if (bs._layout == "new") {
    container = this; 
  }
  var form = container.find('form');
  var fileInput = form.find('button.upload');
  var ajaxUpload = new AjaxUpload(fileInput, {
    name: fileInput.attr('name'),
    action: form.attr('action'),

    autoSubmit: true,
    data: bs.hashWithToken(),

    onChange: function(file) { fileInput.text('Selected file: ' + file); },
    onSubmit: function() { form.find('.import-spinner').show(); },
    onComplete: function(file, response) {
      $('#import-spinner').hide();
      $('#import-csv-form').slideUp();
      response = bs.stripTag(response, 'pre');
      try {
        // We recieve JSON as plain text, because some browsers would want to
        // download JSON
        response = JSON.parse(response);
        response = bs.unpackLayoutInformation(response);      // hack to manage two layouts. REMOVE THIS when old layout is no longer supported
        bs.backlog.importItems(response);
        bs.envelope.handle(response);
        $.facebox.close();
      } catch(e) {
        bs.flash('There was an error parsing your CSV file', 'error');
        return false;
      }
    }
  });
  container.find('.hide-form').one('click', function() {
    ajaxUpload.destroy();
  });
  form.submit(function(ev) {
      ev.preventDefault();
      ajaxUpload.submit();
      return false;
  });
};

// slideup unless checkbox to stay open is checked
bs.backlog.formSlideUp = function(container, callback) {
  var leaveOpen = container.find('input[name=leave-open]');
  if (leaveOpen.attr('checked')) {
    var backlogEndChecked = container.find('form input#backlog-end').attr('checked');
    container.find('form').trigger('reset');
    container.find('form input#backlog-end').attr('checked', backlogEndChecked);
    container.find('.error-container').html('');
    
    if (callback) { callback(); }
    
    container.find('form').focusOnFirstInput();
    leaveOpen.attr('checked', true);
  } else {
    container.slideUp(function() {
      container.trigger('bs:itemSizeChanged');
    });
  }
};

bs.backlog.bulkAddClickHandler = function(ev) {
  ev.preventDefault();
  ev.stopPropagation();
  var link = $(ev.target);
  var target = bs.getUrl(link);

  bs.dialog.loadToModal(target, bs.backlog.importItems); 
  $(document).one('afterReveal.facebox', function() {
    $('.bulk-add-form textarea').watermark("User story 1\n - Task 1\n - Task 2\nUser story with estimate, 6\n - Task with estimate, 4");
  });
  return false;
};

bs.backlog.importItems = function(data) {
  bs.backlog.prependNewItems(data.html);
  if (data.tag_in_cloud && data.tag_in_cloud.replace(/\s/g,"")) {
    bs.tags.updateCloud(data.tag_in_cloud);
  }
  $(document).trigger('bs:backlogChanged');
};

bs.backlog.handleIndexCardsModalWindow = function(event) {
  url = bs.getUrl($(event.target));
  var onFaceboxLoadSuccess = function(envelope) {
    var contents = $(envelope.html);
    $.facebox(contents);
  };

  jQuery.facebox(function() {
    bs.get(url, {}, onFaceboxLoadSuccess, null, 'json');
  });
  return false;
};

bs.backlog.refreshNoItemsMessage = function(event) {
  if ($('.backlog-item').length) {
    $('.empty-backlog-note').hide();
  } else {
    $('.empty-backlog-note').show();
  }
  return false;
};

