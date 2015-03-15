/**
 * Namespace for dialog-related functions
 */
bs.dialog = {};

bs.dialog.faceboxLink = function() {
  var url = $(this).attr('href');
  bs.dialog.loadToModal(url);
  return false;
};

bs.dialog.loadToModal = function(url, callback, initialize) {
  var form;
  
  var updateForm = function () {
    form = jQuery("#facebox form");
    form.focusOnFirstInput();
    bindFormEvents();
  };

  // changes form behaviour to post via AJAX
  var bindFormEvents = function () {
    bs.ajax.submitFormBinder(form, submitSuccess, submitError, 'json');
  };

  var submitSuccess = function(envelope) {
    if (callback) {
      callback(envelope);
    }
    if (!envelope.leaveOpen) {
      $.facebox.close();
    }
    if (envelope.updateForm) {
      $.facebox(envelope.html);
      updateForm();
    }
  };

  var triggerEventAfterReveal = function(envelope) {
    if ($.isFunction(initialize)) {
      $(document).one('afterReveal.facebox', function() {
        initialize.call($("#facebox"), envelope);
      });
    }
  };

  var submitError = function (xhr) {
    if (xhr.status != 409) {
      throw "aaa";
    }
    var envelope = JSON.parse(xhr.responseText);
    if (envelope.html) {
      triggerEventAfterReveal(envelope);
      $.facebox(envelope.html);
      updateForm();
    } else {
      throw(envelope);
    }
    return false;
  };

  var onFaceboxLoadSuccess = function(envelope) {
    var contents = $(envelope.html);
    triggerEventAfterReveal(envelope);
    $.facebox(contents);
    form = $("#facebox form:not(.no-default-binding)");
    if (form[0]) {
      bindFormEvents();
    }
  };

  jQuery.facebox(function() {
    bs.get(url, {}, onFaceboxLoadSuccess, null, 'json');
  });
};

jQuery(document).ready(function() {
  $.facebox.settings.opacity = 0.6;
});
