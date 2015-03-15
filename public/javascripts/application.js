// Banana Scrum namespace
var bs = { };

// Rails' form_authenticity_token (set dynamically on page)
bs._token = null;

// all users assigned to project
bs._team = [];
// project name
bs._project = "";
// id of sprint, if on sprint page
bs._sprintId = "";

bs._projectEsimates = "";

bs._sessionId = "";

// which layout to use? envelope format is { 'html': { 'new': some_html, 'old': some_old_html } }. Value is either new or old, set in layout
bs._layout = "";  

// Returns hash with rails' auth token set
bs.hashWithToken = function() {
  return {"authenticity_token": bs._token, "session_id": bs._sessionId};
};

/**
 * Adds flash message with given severity
 * @param {String} message flash message to appear
 * @param {String} severity (optional) 'notice', 'warning' or 'error'
 */
bs.flash = function(message, severity) {
  var cls = severity ? 'flash ' + severity : 'flash';
  $('.flash').remove();
  var flash = $('<div id="flash-ajax" class="flash" style="display: none"></div>');
  flash.html(message).attr('class', cls);
  var container = $('#flash-container');
  var newFlash = container.find('#flash-left');

  // handling damn old layout
  if (newFlash.length > 0) {
    container.find('#flash-left').after(flash);
  } else {
    container.append(flash);
  }
  container.show();
  flash.fadeIn('medium');
  console.log(severity)
  if (severity && severity == 'persistant') {
    return false;
  }
  setTimeout(bs.flash.hide, 3000);
  return false;
};

bs.flash.hide = function() {
  var flashContainer = $('#flash-container');
  if (flashContainer.find('.persistant').length > 0) {
    return false;
  }
  $(flashContainer).fadeOut('medium');
  return false;
};

bs.addFlashes = function(flashes) {
  if (typeof(flashes) == 'undefined') {
    return;
  }
  $('.flash').remove();
  var severities = ['notice', 'warning', 'error', 'persistant'];
  var len = severities.length;
  for (var i = 0; i < len; ++i) {
    var severity = severities[i];
    if (typeof(flashes[severity]) != 'undefined') {
      bs.flash(flashes[severity], severity);
    }
  }
};

bs.openLink = function(ev) {
  ev.stopPropagation();
  ev.preventDefault();
  var url = $(this).attr('href');
  if (!url.match(/^https?:\/\//)) {
    url = "http://" + url;
  }
  window.open(url);
  return false; 
};

/**
 * Utility function to escape text used as input in regular expressions
 */
bs.escapeRegExp = function(text) {
  if (!arguments.callee.sRE) {
    var specials = [
      '/', '.', '*', '+', '?', '|',
      '(', ')', '[', ']', '{', '}', '\\'
    ];
    arguments.callee.sRE = new RegExp(
     '(\\' + specials.join('|\\') + ')', 'g'
    );
  }
  return text.replace(arguments.callee.sRE, '\\$1');
}

/**
 * Removes surrounding tagName from text, eg.
 * bs.stripTag("<pre class="foo">bar</pre>", "pre") => "bar"
 */
bs.stripTag = function(text, tagName) {
  text = $.trim(text);
  var matcher = new RegExp('<\s*\/?\s*' + bs.escapeRegExp(tagName) + '\s*.*?>', 'ig');
  var matches = text.match(matcher);
  if (matches && matches.length) {
    var openingTag = matches[0];
    var closingTag = matches[matches.length - 1];
    text = text.substring(matches[0].length);
    if (matches.length > 1) {
      text = text.substring(0, text.length - closingTag.length);
    }
  }
  return text;
};

bs.ajax = {};

bs.ajax._defaultErrorHandler = function(resp) {
  try {
    var envelope = JSON.parse(resp.responseText);
    if (typeof(envelope._error.message) == 'undefined') {
      throw true;
    }
    alert('Error: ' + envelope._error.message);
  } catch (e) {
    console.log(resp);
    bs.flash('An error occured while processing your request', 'error');
  }
};

/**
 * Function called on ajaxComplete event
 */
bs.ajax.completeHandler = function(ev, resp) {
  try {
    var envelope = JSON.parse(resp.responseText);
    $('.flash').remove();
    bs.envelope.handle(envelope);
  } catch (e) {
    if (e.name != "SyntaxError") { //Syntax error is thrown by parse if non-json is received
      throw e;
    }
  }
};

bs.ajax.send = function(method, action, params, success, error, type) {
  var errorHandler;
  if (typeof(type) == 'undefined') {
    // TODO: Switch to json, when controllers are ready
    type = 'text';
  }
  if ($.isFunction(error)) {
    errorHandler = function(xhr, textStatus, errorThrown) {
      try {
        error(xhr, textStatus, errorThrown);
      } catch (e) {
        console.log(e);
        bs.ajax._defaultErrorHandler(xhr);
      }
    };
  } else {
    errorHandler = bs.ajax._defaultErrorHandler;
  }
  if (method.toUpperCase() != "GET") { 
    params.session_id = bs._sessionId;
  }
  
  var unpackEnvelopeAndFireSuccess = function(env) {    // html key can have new and old version to make this work with juggernaut. REMOVE THIS when old layout is no longer supported
    if (type.toUpperCase() === "JSON") {
      env = bs.unpackLayoutInformation(env);
    }
    if ($.isFunction(success)) {
      success.call(this, env);
    }
  };
  
  $.ajax({
    type: method,
    url: action,
    data: params,
    success: unpackEnvelopeAndFireSuccess,
    error: errorHandler,
    dataType: type
  });
  
};

bs.unpackLayoutInformation = function(env) {    // choose proper html version out of envelope. SHOULD BE REMOVED when old layout is gone
  if (env.html && env.html['new']) { 
    env.html = env.html[bs._layout];
  }
  if (env.tag_in_cloud && env.tag_in_cloud['new']) { 
    env.tag_in_cloud= env.tag_in_cloud[bs._layout];
  }
  return env;
};
/**
 * Returns function that will submit form via ajax, using functions given as
 * argments as callbacks to ajax call
 * @param {function} success handler called on ajax success
 * @param {function} error (optional) handler called on ajax error response
 * @param {String} type (optional) type of request ('json', 'text', 'xml')
 * @return function handler to submit event via ajax
 */
bs.ajax.submitForm = function(success, error, type) {
  var handler = function(ev) {
    ev.preventDefault();
    ev.stopPropagation();
    var form = $(ev.target);
    
    form.block({message:null, timeout: 2000}); // block form for 1 second to prevent multiple submits

    var params = form.toJSONWithoutWatermarks();
    bs.ajax.send(form.attr('method'), form.attr('action'), params, success, error, type);
  };
  return handler;
};

/**
 * Method that binds submit event on form element, that will send ajax
 * request, instead of sending standard submit
 * @param {Object} form selector of form tag to submit
 * @param {function} success callback launched on success
 * @param {function} error (optional) callback called on error
 * @param {String} type type of ajax request to send (text, json, ...)
 */
bs.ajax.submitFormBinder = function(form, success, error, type) {
  form.bind('submit', bs.ajax.submitForm(success, error, type));
};


/**
 * Wrapper for JQuery.ajax that sends POST XmlHttpRequest with authenticity token
 * @param {String} action url to send request to
 * @param {Object} params hash of parameters to be sent
 * @param {function} complete callback called when recieving successful
 * response
 * @param {function} error (optional) callback called when recieving error
 * response. Defaults to complete
 * @param {String} type (optional) request type. See $.ajax documentation
 * for more details
 */
bs.post = function(action, params, success, error, type) {
  params.authenticity_token = bs._token;
  bs.ajax.send('POST', action, params, success, error, type);
};

/**
 * As bs.ajax.post, except it uses get method and does not provide auth token
 */
bs.get = function(action, params, success, error, type) {
  bs.ajax.send('GET', action, params, success, error, type);
};

/**
 * Sends PUT method by adding _method parameter to post request.
 * Used for browser compatibility
 */
bs.put = function(action, params, success, error, type) {
  params._method = 'PUT';
  bs.post(action, params, success, error, type);
};

/**
 * Sends DELETE method by adding _method parameter to post request.
 * Used for browser compatibility
 * Note it is called destroy, because delete name might be dangerous in some
 * javascript implementations
 */
bs.destroy = function(action, params, success, error, type) {
  params._method = 'DELETE';
  bs.post(action, params, success, error, type);
};

// To be used with $.live
// @param  handler function to be called on 'this'
bs.buildBinder = function(handler) {
  var binder = function() {
    var elem = $(this);
    if (! elem.data('binder.was_bound')) {
      elem.data('binder.was_bound', true);
      handler.call(elem);
    }
  };
  return binder;
};

/**
 * Finds closest parent element that is expected to have id of record stored
 * in id of element with given prefix
 * @param {Object} child $ singleton instance
 * @param {String} selector selector to find element that stores id
 * @param {String} id_prefix prefix of id attribute (without number
 * @return {int} model id of given element
 */
bs.modelId = function(child, selector, idPrefix) {
  var element = child.closest(selector);
  return parseInt(element.attr('id').replace(idPrefix, ''), 10);
};

bs.news = {};

bs.news.dissmissLinkClickHandler = function(ev) {
  var link = $(this);
  var url = bs.getUrl(link);

  var success = function() {
    var news = link.parents('.news-reminder');
    news.fadeOut(function() {
      news.remove();
    });
  };

  bs.post(url, {}, success, null, 'json');
  return false;
};

/**
 * Expand namespace. Used for toggling element's visibility
 */
bs.expand = {};

/**
 * Expand/collapse element expandableElement
 * It shows/hides elements with class toggableVisibility
 * that are inside expandableElement
 * imageLink is link that was clicked to cause expansion/collaption
 * @param {Object} expandableElement
 * @param {Object} imageLink (optional) $ selector of link with image
 *              that triggered event
 */
bs.expand.toggleWithImage = function(expandableElement, imageLink) {
  if (expandableElement.hasClass('collapsed')) {
    expandableElement.removeClass('collapsed').addClass('expanded');
    imageLink.find('.expand-icon').removeClass('expand').addClass('collapse');
    expandableElement.trigger('bs:itemChanged');
  } else {
    expandableElement.addClass('collapsed').removeClass('expanded');
    imageLink.find('.expand-icon').removeClass('collapse').addClass('expand');
  }
};

bs.expand.expandClosestSection = function() {

  var expandableElement = $(this).closest('.expandable');
  if (expandableElement.hasClass('collapsed')) {
    bs.expand.toggle(expandableElement);
  }
};

bs.expand.toggle = function(expandableElement) {
  expandableElement.each(function() {
    var expandable = $(this);
    bs.expand.toggleWithImage(expandable, expandable.find('.expandable-link').first());
  });
  expandableElement.find('.expandable-link').first().trigger('bs:expandToggle');
};

/**
 * Handler called when clicking on expand/collapse link
 * After expand is performed, event bs:expandToggle is fired on link that was
 * clicked. Useful, if you want to perform some other action after section is
 * expanded.
 */
bs.expand.toggleHandler = function(ev) {
  ev.preventDefault();
  var link = $(this);
  var expandable = link.closest('.expandable');
  bs.expand.toggleWithImage(expandable, link);

  var tabs;
  if (expandable.hasClass("item") && expandable.parent(".read-only").length == 0) {
    tabs = expandable.find(".tabbed-content");
  }
  if (tabs != undefined && tabs.length > 0) {
    tabs.trigger("bs:tabChanged");
  }
  
  link.trigger('bs:expandToggle');
  $(document).trigger('bs:expandToggle');
};

bs.expand.listExpandHandler = function(ev) {
  ev.preventDefault();
  var link = $(this);

  $(document).unbind('bs:itemChanged', bs.item.hideMoreLinkIfUnnecessary);
  try {
    bs.expand.toggle(link.closest('.expandable-list').find('.expandable.collapsed'));
  } finally {
    $(document).bind('bs:itemChanged', bs.item.hideMoreLinkIfUnnecessary);
  }
};

bs.expand.listCollapseHandler = function(ev) {
  ev.preventDefault();
  var link = $(this);
  bs.expand.toggle(link.closest('.expandable-list').find('.expandable.expanded'));
};

bs.expand.hideFormClickHandler = function(ev) {
  ev.preventDefault();
  ev.stopPropagation();
  var target = $(ev.target);
  target.parents('.form-container').slideUp(function() {
    $(this).text('');
    $(this).trigger('bs:itemSizeChanged');
  });
};

bs.expand.escKeyHideForm = function(ev) {
  if (ev.keyCode == 27) {
    var hideFormLink = $(this).find('.hide-form');
    if (hideFormLink[0]) {
      ev.preventDefault();
      ev.stopPropagation();
      hideFormLink.click();
      return false;
    }
  }
  return true;
};

/**
 * Namespace for handling sprint/backlog stats
 * Contains functions for retrieving stats from server
 * number of backlog items, estimate sum, etc.
 */
bs.stats = {};

bs.stats.fieldUpdate = function(statField, data) {
  $.each(data, function(key, value) {
    statField.find('.' + key).text(value);
  });
};

bs.stats.count = function(items) {
  var result = {};
  var itemEffort = 0;
  var taskEffort = 0;
  items = items.filter('.item:visible');
  var tasksCount = 0;

  result['items-total-count'] = items.length;
  result['items-not-estimated-count'] = items.filter('.unestimated-backlog-item').length;

  var itemTasksSum;
  items.each(function(index, item) {
    itemTasksSum = 0;
    item = $(item);
    // sum the sp's
    if (!item.hasClass("unestimated-backlog-item") && !item.hasClass("infinity-estimate-backlog-item")) {
      itemEffort = itemEffort + parseFloat(item.find(".item-estimate").text());
    }

    var tasks = item.find(".task").not('.filtered-out');
    // sum total number of tasks
    tasksCount = tasksCount + tasks.length;
    tasks.find('.task-estimate').each(function(index, estimate) {
      estimate = parseInt($(estimate).text());
      // sum tasks effort
      taskEffort = taskEffort + estimate;
      // sum effort for this item
      itemTasksSum = itemTasksSum + estimate;
    });
    
    item.find(".total-tasks-value").text(itemTasksSum);
  });

  result['items-effort'] = itemEffort;
  result['tasks-count'] = tasksCount;
  result['tasks-effort'] = taskEffort;
  
  return result;
};

bs.stats.refreshSprintStats = function() {
  if (!$('.sprint.items-count').length && !$('.timeline').length) {
    return;
  }
  var statListenerFields = bs.stats.count($('.sprint-items-container .item'));
  bs.stats.fieldUpdate($('.sprint.items-count'), statListenerFields);
};

bs.stats.refreshBacklogStats = function() {
  if (!$('.backlog.items-count').length) {
    return;
  }
  var statListenerFields = bs.stats.count($('#backlog-items .item'));
  bs.stats.fieldUpdate($('.backlog.items-count'), statListenerFields);
};

bs.IE6Warning = function() {
  if ($.browser.msie && bs.showIE6Warning) {
    var version = parseFloat($.browser.version);
    if (version < 7.0) {
      alert("We're sorry, but we don't support Internet Exporer versions lower" +
        " than 7.0.\nIf you want to have full Banana Scrum experience, please use" +
        " newer browser, such as Internet Explorer 7/8 or Firefox 3.");
    }
  }
};

bs.envelope = {};

bs.envelope._handlers = {};

bs.envelope.handle = function(json) {
  $.each(bs.envelope._handlers, function(key, handler) {
    if (typeof json[key] != 'undefined') {
      handler.call(json[key], json[key]);
    }
  });
};

bs.envelope.registerHandler = function(key, handler) {
  if (bs.envelope._handlers[key]) {
    throw RuntimeError('Handler for ' + key + ' is already defined!');
  }
  bs.envelope._handlers[key] = handler;
};

// returns url for link wrapped in functional form
bs.getUrl = function(link) {
  return link.parents('.functional-form').find('input[name="url"]').attr('value');
};

// action bind to links created with formal_link_to helper. makes full http request via form submit
bs.formalLinkClick = function(ev) {
  ev.stopPropagation();
  ev.preventDefault();
  var form = $(this).parents('.formal-link');
  var confirm_i = form.find('input[name=confirm]');
  if (confirm_i[0]) {
    var text = confirm_i.attr('value');
    if (!confirm(text)) {
      return false;
    }
  }
  form.submit();
  return false;
};

// Function written to prevent using to many DOM manipulation during calculating which items to show. Chaning of CSS classes was very slow // combined with Adblock Plus. Instead we use jQuery data for each element and hide them using  { display: none } style property
bs.processFilters = function () {
  if ($('.product-backlog-timeline').length) {
    return;   //disable this function on timeline view - we don't have filters nor tags there
  }
  bs.tags.manager.filterItems();
  bs.sprint.applyFilter();

  $('.item').show();
  $('.item').each(function() {
    var el = $(this);
    if (!el.data('visible') || el.data('filtered-out')) {
      el.hide();
    }
  });
};

bs.openInNewWindow = function(ev) {
  window.open(this.href);
  return false;
};

// Prevents double submits of non-ajax forms 
// set double-submit-blocked class on the form to use it
bs.blockOnSubmit = function() {
  var form = $(this);
  form.block({message:null, timeout: 2000});
  return true;
};

bs.refreshProjects = function(options) {
  $('#project_id').html(options);
};

bs.fixOperaBodyHeight = function() { // fixes #498
  if ($.browser.opera) {
    var windowHeight = $(window).height();
    var bodyHeight = $('body').height();
    if (windowHeight > bodyHeight) {
      $('body').height(windowHeight);
    }
  }
};

bs.toggleSplitBar = function() {
  $('#splitter').toggleClass('right-visible');
  $(window).trigger('resize');
};

bs.detectDisabledCookies = function() {
  $.cookie('test_cookie', 'test');
  if ($.cookie('test_cookie') != 'test') {
    alert("Banana Scrum requires browser to store cookies to log in.\nYou can enable cookies in your browser privacy settings.");
  };
  $.cookie('test_cookie', null);
};

$(document).ready(function() {
  $(document).bind('ajaxComplete', bs.ajax.completeHandler);
  $('#project_id').change(function() {
    if (this.value) {
      window.location = this.value;
    }
  });
  $('.expandable .expandable-link').live('click', bs.expand.toggleHandler);
  $('.expandable-list .expand-list').bind('click', bs.expand.listExpandHandler);
  $('.expandable-list .collapse-list').bind('click', bs.expand.listCollapseHandler);
  $('.form-container a.hide-form').live('click', bs.expand.hideFormClickHandler);
  $('.form-container').live($.browser.opera ? 'keypress' : 'keydown', bs.expand.escKeyHideForm);
  $("a[rel*='external']").live('click', bs.openInNewWindow);

  $('.news-reminder .dismiss-link').live('click', bs.news.dissmissLinkClickHandler);
  bs.IE6Warning();
  $("#login").select().focus();

  bs.envelope.registerHandler("_flashes", bs.addFlashes);
  bs.envelope.registerHandler("_projects", bs.refreshProjects);
  bs.envelope.registerHandler("_burnchart", bs.burnchart.reload);  
  bs.envelope.registerHandler("_participants", bs.sprint.reloadParticipants);
  bs.envelope.registerHandler("_unlock", bs.item.unblockItem);
  bs.envelope.registerHandler("_removed_markers", bs.marker.removeCollection);
  bs.tabs.install();
  bs.fixOperaBodyHeight();
  bs.detectDisabledCookies();
});

// Juggernaut can be a lot of pain with debugging output
if (typeof console == 'undefined') {
  console = {log: function() {}};
}
