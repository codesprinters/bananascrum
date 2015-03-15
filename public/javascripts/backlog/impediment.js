bs.impediment = {};

bs.impediment.getId = function(impedimentChild) {
  return bs.modelId(impedimentChild, '.impediment', 'impediment-');
};

bs.impediment.hasOpenedImpediments = function() {
  return $('.impediment').length != $('.impediment-closed').length;
}

bs.impediment.switchNotification = function() {
  if (!bs.impediment.hasOpenedImpediments()) {
    bs.impediment.hideNotification();
  } else {
    bs.impediment.showNotification();
  }
}

bs.impediment.showNotification = function() {
  $('#impediments-icon').show();
}

bs.impediment.hideNotification = function() {
  $('#impediments-icon').hide();
}

bs.impediment.destroy = function(envelope) {
  $('#impediment-' + envelope.item).remove();
  if (!bs.impediment.hasOpenedImpediments()) {
    bs.impediment.hideNotification();
  }
};

bs.impediment.handleDelete = function(ev) {
  ev.preventDefault();

  var impedimentElement = $(ev.target).closest('li.impediment');
  var impedimentId = bs.impediment.getId(impedimentElement);
  var impedimentName = impedimentElement.find('span.impediment-name').text();
  
  if (confirm("Are you sure you want to delete impediment '" + impedimentName + "' ?")) {
    bs.destroy(projectImpedimentPath(bs._project, impedimentId), {},
          bs.impediment.destroy, null, 'json');
  }
};

bs.impediment.editableSummary = function() {
  $(this).cseditable({
    submit:       'OK',
    cancelLink:   'Cancel',
    editClass:    'editor-field',
    startEditing: true,
    onSubmit:     bs.impediment.summaryOnsubmit,
    onReset:      bs.backlog.enableHighlight,
    onEdit:       bs.backlog.suppressHighlight
  });
};

bs.impediment.setSummary = function(envelope) {
  $('#impediment-' + envelope.item).highlight().find('.impediment-name').html(envelope.value);
};

bs.impediment.setDescription = function(envelope) {
  $('#impediment-' + envelope.item).highlight().find('.impediment-description').html(envelope.html);
};

bs.impediment.summaryOnsubmit = function(values) {
  var impedimentSummary = $(this);
  var id = bs.impediment.getId(impedimentSummary);
  var action = impedimentSummaryProjectImpedimentPath(bs._project, id);
  bs.backlog.inplaceSubmitHandler(impedimentSummary, action, values, bs.impediment.setSummary);
};

bs.impediment.editableDescription = function() {
  var desc = $(this);
  desc.data('impediment_description.original_html', desc.html());
  desc.cseditable({
    type:         'textarea',
    submit:       'OK',
    cancelLink:   'Cancel',
    editClass:    'editor-field',
    startEditing: true,
    onSubmit:     bs.impediment.descriptionOnsubmit,
    onReset:      bs.impediment.descriptionOnreset,
    onEdit:       bs.impediment.descriptionOnedit
  });
};

bs.impediment.descriptionOnedit = function() {
  bs.backlog.suppressHighlight.call(this);
  var desc = $(this);
  var textarea = desc.find('textarea');
  textarea.val('Loading...');
  desc.parents('.impediment').find('.redcloth-legend').show();
  var id = bs.impediment.getId(desc);
  var onSuccess = function(resp) {
    textarea.val(resp).select();
  };

  var onError = function(xhr) {
    // Bring back old field
    desc.find('.editor-field').trigger('reset');
    if (xhr.status == 404) {
      alert("This impediment doesn't exist");
    } else {
      throw resp;
    }
  };
  bs.get(descriptionProjectImpedimentPath(bs._project, id), {}, onSuccess, onError);
};

bs.impediment.descriptionOnsubmit = function(values) {
  var desc = $(this);
  var id = bs.impediment.getId(desc);
  var action = impedimentDescriptionProjectImpedimentPath(bs._project, id);
  desc.parents('.impediment').find('.redcloth-legend').hide();

  bs.backlog.inplaceSubmitHandler(desc, action, values, bs.impediment.setDescription);
};

bs.impediment.descriptionOnreset = function() {
  var desc = $(this);
  bs.backlog.enableHighlight.call(this);
  desc.parents('.impediment').find('.redcloth-legend').hide();
  desc.html(desc.data('impediment_description.original_html'));
};

bs.impediment.substituteAndSelectHistory = function(envelope) {
  var impediment = bs.impediment.substitute(envelope);
  bs.tabs.setCurrentTab(impediment.find('.tab:last'));
};

bs.impediment.substitute = function(envelope) {
  var impediment = $('#impediment-' + envelope.item);
  var expanded = impediment.hasClass('expanded');
  var newImpediment = $(envelope.html);
  var newForm = newImpediment.find('.impediment-status-form');
  
  impediment.replaceWith(newImpediment);
  if (expanded) { 
    bs.expand.toggle(newImpediment);
  }

  bs.impediment.switchNotification();
  newForm.submit(bs.impediment.statusSubmitHandler);
  return newImpediment;
};

bs.impediment.statusSubmitHandler = function(ev) {
  ev.preventDefault();
  ev.stopPropagation();
  var form = $(this);
  var submitHandler = bs.ajax.submitForm(bs.impediment.substitute, null, 'json');
  submitHandler.call(this, ev);
  return false;
};

bs.impediment.add = function(envelope) {
  $('#impediment-form').hide();
  var impedimentElement = $('#impediments-list').append(envelope.html).find('li.impediment:last').highlight();
  // Cannot use live -- submit is not supported on IE
  $('form.impediment-status-form', impedimentElement).submit(bs.impediment.statusSubmitHandler);      //old layout only

  // highlight header
  bs.impediment.showNotification();
};

bs.impediment.newImpedimentAjaxSuccessHandler = function(envelope) {
  var container = $('#impediment-form');
  container.html(envelope.html).slideDown();
  var success = function(envelope) {
    container.hide();
    var impedimentElement = $('#impediments-list').append(envelope.html).find('li.impediment:last').highlight();
    // Cannot use live -- submit is not supported on IE
    impedimentElement.find('form.impediment-status-form').submit(bs.impediment.statusSubmitHandler);
  };
  
  var error = function(resp) {
    var envelope = JSON.parse(resp.responseText);
    if (envelope.html) {
      container.html(envelope.html);
      bs.ajax.submitFormBinder(container.find('form'), bs.impediment.add, error, 'json');
    } else {
      throw resp;
    }
  };
  bs.ajax.submitFormBinder(container.find('form'), bs.impediment.add, error, 'json');
};

bs.impediment.addComment = function(envelope) {
  var impediment = $('#impediment-' + envelope.item).highlight();
  impediment.find('.new-comment').hide();
  impediment.find('ul.impediment-comments').prepend(envelope.html);
};

bs.impediment.newImpedimentClickHandler = function(ev) {
  ev.preventDefault();
  ev.stopPropagation();
  var link = $(ev.target);
  var target = bs.getUrl(link);
  bs.get(target, {}, bs.impediment.newImpedimentAjaxSuccessHandler, null, 'json');
};

bs.impediment.newCommentAjaxSuccessHandler = function(container, envelope) {
  container.html(envelope.html).slideDown();
  
  var error = function(resp) {
    var envelope = JSON.parse(resp.responseText);
    if (envelope._error && envelope._error.type == 'invalid_record') {
      container.find('.error-container').html(envelope.html)
        .find('li:last').effect('highlight', {}, 500);
    }
    throw resp;
  };
  bs.ajax.submitFormBinder(container.find('form'), bs.impediment.addComment, error, 'json');
};

bs.impediment.newCommentClickHandler = function(ev) {
  ev.preventDefault();
  ev.stopPropagation();
  var link = $(ev.target);
  var target = bs.getUrl(link);
  var container = link.parents('.impediment').find('.new-comment');
  var success = function(envelope) {
    bs.impediment.newCommentAjaxSuccessHandler(container, envelope);
  };
  bs.get(target, {}, success, null, 'json');
};


bs.impediment.postCommentClick = function(ev) { //new layout only
  var link = $(this);
  var url = bs.getUrl(link);
  var form = link.parents('.impediment').find('.new-impediment-comment');
  var comment = form.find('textarea');
  var value = comment.attr('value');
  if (value === "") { 
    return false;
  }
  form.trigger('reset');
  bs.post(url, { comment: value }, bs.impediment.addComment, null, 'json');
  return false;
};

bs.impediment.changeStatusClick = function(ev) { //new layout only
  var link = $(this);
  var url = bs.getUrl(link);
  var form = link.parents('.impediment').find('.new-impediment-comment');
  var comment = form.find('textarea');
  var value = comment.attr('value');
  
  var params = {};
  if (!(value === "")) {
    params['comment'] = value;
  }
  if (link.hasClass('reopen-impediment')) {
    params['impediment_status'] = "Opened"
  } else {
    params['impediment_status'] = "Closed"
  }
  
  bs.post(url, params, bs.impediment.substituteAndSelectHistory, null, 'json');
  return false;
};

bs.impediment.newImpedimentDialog = function(ev) { //new layout only
  var url = bs.getUrl($(this));
  
  bs.dialog.loadToModal(url, bs.impediment.add);
  return false;
};