// Attachments handling

bs.attachments = {};

// Set on attachments delete (trash) link
bs.attachments.deleteHandler = function(ev) {
  var deleteLink = jQuery(this);
  var url = bs.getUrl(deleteLink);

  var success = function(envelope) {
    var attachmentElement = deleteLink.parents('.file');
    
    attachmentElement.fadeOut('normal', function() {
      attachmentElement.remove(); 
      $(document).trigger('bs:attachmentEvent');
    });
  };

  if (confirm(deleteLink.attr('title'))) {
    bs.destroy(url, {}, success);
  }

  return false;
};

bs.attachments.refreshIcons = function() {
  $('.attachment-icon').addClass('hidden');
  $('.item:has(li.file) .attachment-icon').removeClass('hidden');
};

bs.attachments.attachFileClickHandler = function(ev) {
  var link = jQuery(ev.target);
  var target = bs.getUrl(link);
  var attachmentsTab = link.parents('.item').find('.tabs-links .tab-attachments a');
  bs.tabs.setCurrentTab(attachmentsTab);
  var container = link.parents('.item').find('.new-attachment');
  var success = function(envelope) {
    bs.item.factory({child: container, callback: bs.item.hideFormContainers});
    container.html(envelope.html).slideDown(function() { container.trigger('bs:itemSizeChanged'); });
    bs.attachments.setupAjaxUpload(container);
  };
  if (!container.is(':visible')) {
    bs.get(target, {}, success, null, 'json');
  }

  return false;
};

// Sets up ajax upload on form included in container
bs.attachments.setupAjaxUpload = function(container) {
  var form = container.find('form');
  var fileInput = form.find('button.upload');
  var ajaxUpload = new AjaxUpload(fileInput, {
      name: fileInput.attr('name'),
      action: form.attr('action'),
      autoSubmit: true,
      data: bs.hashWithToken(),
      onChange: function(file) { fileInput.after($("<span>").text('Uploading file: ' + file)); },
      onSubmit: function() { form.find('.import-spinner').show(); },
      onComplete: function(file, response) {
        $('.import-spinner').hide();
        response = bs.stripTag(response, 'pre');
        // We've sent JSON envelope as plain text
        // If we gave proper content-type header, firefox would want to
        // download this response.
        var envelope = null;
        try {
          envelope = JSON.parse(response);
        } catch(e) {
          // JSON response did not parse. Perhaps we tried to upload file to
          // archived project?
          alert("Unable to upload files");
          return false;
        }
        var elements = jQuery(envelope.html);
        // checking response by content
        if (elements.length > 1) {
          // if we have multiple elements, it means creating failed
          container.html(envelope.html);
          bs.attachments.setupAjaxUpload(container);
        } else {
          // one element (attachment item), meaning creating went ok
          bs.item.factory({child: container, callback: bs.item.addAttachment, args: [ envelope.html ]});
        }
      }
  });
  container.find('.hide-form').one('click', function() {
    if ($.isFunction(ajaxUpload.destroy)) { 
      ajaxUpload.destroy() 
    };
  });
  form.submit(function(ev) {
      ev.preventDefault();
      ajaxUpload.submit();
      return false;
  });
};


// "main"
$(document).ready(function() {
  $('.file .destroy').live('click', bs.attachments.deleteHandler);
  $(document).bind('bs:attachmentEvent', bs.attachments.refreshIcons);
});

