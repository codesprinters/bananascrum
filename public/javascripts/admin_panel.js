bs.admin = { };

/**
 * Moves user/project row to appropriate table when user is blocked or not
 * @param {Object} userRow jQuery singleton selector of user row
 *        (#user-row-<id>)
 * @param bool isAdmin
 */
bs.admin.updateStatus = function(row, isBlocked) {
  var source = row.parents('.section');
  var destination = isBlocked ? row.parents('.current-tab-content').find('.inactive.section') : row.parents('.current-tab-content').find('.active.section') ;
  
  if (destination[0] != source[0]) {
    row.remove();
    bs.admin.hideTableIfEmpty(source);
    destination.show().find('.table-wrapper').show().find('table.data').append(row);
  }
};

bs.admin.submitProjectSetting = function(values, errorHandler) {
  var params = {};
  var item = $(this);
  params['project[' + item.attr('id') + ']'] = values.current;
  bs.put(adminProjectPath(bs._project), params, null, errorHandler, 'json');
};

bs.admin.handleProjectDelete = function() {
  if (!confirm("Are you sure to delete project?")) { 
    return false;
  }
  var element = $(this);
  var url = bs.getUrl(element);
  var success = function() {  
    var table = element.parents('table.data');
    element.parents('tr.project-row').remove();
    table.recolorRows({'rowClass': '.project-row'});
    bs.admin.hideTableIfEmpty(table);
    bs.admin.handleEmptySectionMessage();
  };
  bs.destroy(url, {}, success);
  return false;
};

bs.admin.hideTableIfEmpty = function(table) {
  if (table.find('tr.row').length === 0) {
    var section = table.closest('.section');
    var toHide;
    if (section.hasClass('hide-table-only')) {
      toHide = section.find('.table-wrapper');
    } else {
      toHide = section;
    }
    toHide.hide();
  }
  bs.admin.handleEmptySectionMessage();
};

bs.admin.handleEmptySectionMessage = function() {
  var section = $('.current-tab-content');
  if (section.find('tr.row').length) {
    section.find('.empty-section-message').hide();
  } else {
    section.find('.empty-section-message').show();
  }
};

bs.admin.updateProjectTables = function(envelope) {
  var projectRow = $('#project-row-'+envelope.project);
  bs.admin.updateStatus(projectRow, envelope.archived);
  bs.admin.handleEmptySectionMessage();
};

bs.admin.handleBlockUser = function() {
  var link = $(this);
  var url = bs.getUrl(link);
  var value = (link.parents('#active-users').length == 0) ? 0 : 1;
  var params = {
    user_blocked: value
  };
  bs.put(url, params, bs.admin.updateUsersTables, null, 'json');
  return false;
};

bs.admin.updateUsersTables = function(envelope) {
  if (! envelope.user) {
    return false;
  }
  var userRow = $('#user-row-' + envelope.user);
  userRow.setClassIf(envelope.admin, 'admin');
  bs.admin.updateStatus(userRow, envelope.blocked);
};

bs.admin.handleCheckboxSubmit = function(success) {
  var element = $(this);
  var action = element.closest('form').attr('action');
  var params = {};
  params[element.attr('name')] = element.attr('checked') ? 1 : 0;
  bs.put(action, params, success, null, 'json');
};

bs.admin.handleUserDelete = function() {
  if (!confirm("Are you sure you want to delete user?")) {
    return false;
  }
  var element = $(this);
  var url = bs.getUrl(element);
  var success = function() {
    var table = element.parents('table.data');
    element.parents('tr.user-row').remove();
    table.recolorRows({'rowClass': '.user-row'});
    bs.admin.hideTableIfEmpty(table);
  };
  bs.destroy(url, {}, success);
  return false;
};

bs.admin.toggleNoteForUser = function () {
  if (this.checked) {
    $('#note-for-user').slideDown();
  } else {
    $('#note-for-user').slideUp();
  }
  return true;
};

bs.admin.settingsEstimateSequenceOnsubmit = function(values) {
  var itemEstimate = $(this);
  var action = estimateSettingsAdminProjectPath(bs._project);

  var complete = function(data) {
    itemEstimate.html(data.estimate);
  };

  bs.backlog.inplaceSubmitHandler(itemEstimate, action, values, complete, null, 'json');
};


bs.admin.handleNewUserModalWindow = function(event) {
  var callback = function(envelope){
    $("#active-users .data tbody").append(envelope.html);
    bs.admin.handleEmptySectionMessage();
  };

  var initializeForm = function(envelope) {
    var container = this;
    container.find("#form_to_assign").selectCheckbox({
      selectList: envelope.projects_list,
      select: envelope.select_projects,
      emptyText: "",
      width: 200
    });
  };

  var url = bs.getUrl($(event.target));

  bs.dialog.loadToModal(url, callback, initializeForm);

  return false;
};

bs.admin.handleEditUserModalWindow = function(event) {
  var callback = function(envelope) {
    bs.admin.updateRoles(envelope, "roles");
    if (envelope.html) {
      var newRow = $(envelope.html);
      var id = newRow.attr('id');
      var oldRow = $('#'+id);
      var table = oldRow.parents('table.data');
      oldRow.replaceWith(newRow);
      table.recolorRows({rowClass: '.user-row'});
    }
  };
  url = bs.getUrl($(event.target));

  bs.dialog.loadToModal(url, callback);

  return false;
};

/**
 * Replaces user-project-roles div content with given
 * within envelope.
 * @param {Object} envelope
 * @param {String} partialName name of partial that should be within envelope,
 *  'roles' by default
 */
bs.admin.updateRoles = function(envelope, partialName) {
  partialName = partialName || "roles";
  if (envelope[partialName]) {
    $("#user-project-roles").replaceWith(envelope[partialName]);
  }
};

// FIXME: 2 functions below are (UGLY and..) very similar think about sth preetier
bs.admin.removeRoleForUser = function() {
  var callback = function(envelope) {
    if (envelope.roles) {
      $("#user-project-roles").replaceWith(envelope.roles);
    }
  };
  bs.admin.removeRoleReq(bs.getUrl($(this)), callback);

  return false;
};

bs.admin.removeRoleForProject = function() {
  var callback = function(envelope) {
    if (envelope.roles_for_project) {
      $("#user-project-roles").replaceWith(envelope.roles_for_project);
    }
  };
  bs.admin.removeRoleReq(bs.getUrl($(this)), callback);

  return false;
};

bs.admin.removeRoleReq = function(url, callback) {
  if (confirm('Are you sure you want to remove this role?')) {
    bs.destroy(url, {}, callback, null, 'json');
  }
};

// used in newProject and editProject modal windows
bs.admin.handleInitialEnvelopeForGraphs = function(env) {
  $('.visible-graphs').selectCheckbox({
    selectList: env.all_graphs,
    select: env.selected_graphs,
    width: 200,
    emptyText: 'None'
  });
}

bs.admin.handleNewProjectModalWindow = function(event) {

  var callback = function(envelope){
    $("#active-projects .data tbody").append(envelope.html);
    bs.admin.handleEmptySectionMessage();
    $("#active-projects").show();
    $("#active-projects .data").recolorRows({'rowClass': '.project-row'});
  };

  var url = bs.getUrl($(event.target));
  
  var init = function(env) {
    bs.admin.handleInitialEnvelopeForGraphs(env);
    this.find("#assign-members").selectCheckbox({
      selectList: env.mass_assignment.team_member,
      select: env.mass_assignment_selected.team_member,
      width: 200,
      emptyText: ''
    });
    this.find("#assign-scrum-masters").selectCheckbox({
      selectList: env.mass_assignment.scrum_master,
      select: env.mass_assignment_selected.scrum_master,
      width: 200,
      emptyText: ''
    });
    this.find("#assign-product-owners").selectCheckbox({
      selectList: env.mass_assignment.product_owner,
      select: env.mass_assignment_selected.product_owner,
      width: 200,
      emptyText: ''
    });
  };
  bs.dialog.loadToModal(url, callback, init);

  return false;
};

bs.admin.handleEditProjectModalWindow = function(event) {
  var callback = function(envelope) {
    bs.admin.updateRoles(envelope, "roles_for_project");
    $("#projects").html(envelope.html);
  };

  var url = bs.getUrl($(event.target));
  bs.dialog.loadToModal(url, callback, bs.admin.handleInitialEnvelopeForGraphs);
  
  $(document).one('afterReveal.facebox', function() {
    bs.tabs.setCurrentTab($('#facebox .current-tab'));
  });
  return false;
};

bs.admin.resetPassword = function() {
  var callback = function() {
    $.facebox.close();
  };
  var url = bs.getUrl($(this));
  if (confirm("This will block user's current password and send mail\nasking to reset password.\nAre sure you want to do this?")) {
    bs.post(url, {}, callback);
  }
};

bs.admin.refreshProjectMembers = function(envelope) {
  $.each(envelope, function(index, project) {
    var row = $("#project-row-" + project.id);
    if (row.length) {
      row.find("td.team-members").text(project.members);
    }
  });
};

bs.admin.resetSettingsToDefaults = function() {
  var link = $(this);
  var url = bs.getUrl(link);
  if (!confirm("Are you sure to reset the settings to default values?")) {
    return false;
  }
  var success = function(envelope) {
    link.parents('#settings').find('table.data').replaceWith(envelope.html);
  };
  bs.post(url, {}, success, null, 'json');
};

bs.admin.editCustomerLinkClick = function() {
  var url = $(this).attr('href');
  bs.admin.editCustomerFormHandler(url);
  return false;
};

bs.admin.editCustomerFormHandler = function(url, callback) {
  var success = function(envelope) {
    if (!envelope.updateForm) {
      $('#billing-details').replaceWith(envelope.html);
      if ($.isFunction(callback)) {
        callback.call();
      };
    }
  };

  bs.dialog.loadToModal(url, success);
};

bs.admin.submitFromCreatingCustomerFirst = function() {
  var form = $(this);
  var submitForm = function() {
    form.removeClass('create-customer-first');
    form.submit();
  };
  
  if (form.hasClass('create-customer-first')) {
    bs.admin.editCustomerFormHandler(newAdminCustomerPath(), submitForm);
    return false;
  } else {
    return true;
  }
};

$(function() {
  $('.delete-project').live('click', bs.admin.handleProjectDelete);
  $('.delete-user').live('click', bs.admin.handleUserDelete);
  $('#add_note_checkbox').live('click', bs.admin.toggleNoteForUser);
  
  $('.admin-user-checkbox').live('change', function() { 
    bs.admin.handleCheckboxSubmit.call(this, bs.admin.updateUsersTables);
  });
  $('.archive-project-checkbox').live('click', function() {
    var checked = $(this).is(':checked');
    var confirm_text = checked ? "This will block access to this project for non admin users.\nAre sure you want to do this?" : "This will allow assigned non-admin users to edit this project content.\nAre sure you want to do this?" ;
    if (!confirm(confirm_text)) {
      $(this).attr('checked', !checked);
      return false;
    }
    bs.admin.handleCheckboxSubmit.call(this, bs.admin.updateProjectTables);
  });
  $('#active-users table.data, #blocked-users table.data').tableSort({
    headRow: 0,
    columns: {
      0: { type: 'string', sorted: 'asc' },
      1: { type: 'string' },
      2: { type: 'string' },
      3: { type: 'html' }
    }
  });
  $('#active-projects table.data, #archived-projects table.data').tableSort({
    headRow: 0,
    columns: {
      0: { type: 'string', sorted: 'asc' },
      1: { type: 'string' },
      2: { type: 'string' },
      3: { type: 'string' },
      4: { type: 'integer' }
    }
  });

  $('form.checkbox-form').trigger('reset');
  $('.new-user-link').live('click', bs.admin.handleNewUserModalWindow);
  $('.edit-user-link').live('click', bs.admin.handleEditUserModalWindow);
  $('.block-user:not(.disabled)').live('click', bs.admin.handleBlockUser);
  $('.new-project-link').live('click', bs.admin.handleNewProjectModalWindow);
  $('.user-project-roles .remove-role').live('click', bs.admin.removeRoleForUser);
  $('.project-users-roles .remove-role').live('click', bs.admin.removeRoleForProject);
  $('.edit-project-link').live('click', bs.admin.handleEditProjectModalWindow);
  $('#reset-password').live('click', bs.admin.resetPassword);
  bs.envelope.registerHandler("_project_members", bs.admin.refreshProjectMembers);
  $('#reset-to-defaults').live('click', bs.admin.resetSettingsToDefaults);
});

