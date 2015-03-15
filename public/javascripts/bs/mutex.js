function do_nothing(){}

bs.mutex = {
  // object variables
  sessionId : '',
  channel : '',
  clientId : 0,
  lockCount : {},
  
  init: function() {
    bs.mutex.sessionId = bs.juggernautOptions.session_id;
    bs.mutex.channel = bs.juggernautOptions.channels[0];
    bs.mutex.clientId = bs.juggernautOptions.client_id;
    return(this);
  },

  juggernautConnected: function() {
    return juggernaut && juggernaut.is_connected
  },

  // locks the resource (identified by a string id)
  // silently ignores any errors
  // operation defaults to 'editing',
  // operations are white listed in controller
  lock: function(elementId, operation) {
    var numberOfLocks = bs.mutex.lockCount[elementId] || 0;
    if (bs.mutex.juggernautConnected()) {
      if (numberOfLocks === 0) {
        $('#item-' + elementId).addClass('nosort');
        var url = lockProjectItemPath(bs._project, elementId) ;
        var data = { 'operation': (operation || "editing") };
        bs.post(url, data, null, null, 'json');
      }
      bs.mutex.lockCount[elementId] = numberOfLocks + 1;
    }
  },

  // unlocks the resource (identified by a string id)
  // silently ignores any errors
  // unlocks resource only if lock was creatd by current user
  unlock: function(elementId) {
    var numberOfLocks = bs.mutex.lockCount[elementId] || 1;
    if (bs.mutex.juggernautConnected()) {
      if (numberOfLocks == 1) {
        var url = unlockProjectItemPath(bs._project, elementId);
        bs.post(url, {}, null, null, 'json');
        $('#item-' + elementId).removeClass('nosort');
      }
      bs.mutex.lockCount[elementId] = numberOfLocks - 1;
    }
  },

  timeoutId: null,

  connect: function(){
    bs.mutex.changeStatusIcon("connecting");
    console.log("Connecting to Juggernaut...");
    bs.mutex.clearTimeout();
    bs.mutex.timeoutId = setTimeout('bs.mutex.errorConnecting()', 60000);
  },

  errorConnecting: function(){
    bs.mutex.changeStatusIcon("errorConnecting");
    console.log("Error connecting to Juggernaut");
    bs.mutex.clearTimeout();
  },

  connected: function(){
    bs.mutex.changeStatusIcon("connected");
    console.log("Connected to Juggernaut");
    bs.mutex.clearTimeout();
  },

  disconnected: function(){
    bs.mutex.changeStatusIcon("disconnected");
    bs.mutex.clearTimeout();
  },

  clearTimeout: function(){
    if (bs.mutex.timeoutId) {
      clearTimeout(bs.mutex.timeoutId);
      bs.mutex.timeoutId = null;
    }
  }

};

bs.mutex.alts = {
  "connected" : "Connected to synchronization server",
  "connecting" : "Connecting to synchronization server",
  "disconnected" : "Lost connection to synchronization server",
  "errorConnecting" : "Couldn't connect to synchronization server"
};

bs.mutex.statusTexts = {
  "connected" : "",
  "connecting" : "",
  "disconnected" : "",
  "errorConnecting" : ""
};

bs.mutex.statusFlag = null;

bs.mutex.changeStatusIcon = function(status) {
  if (bs.mutex.alts[status] == null) {
    return false;
  }

  if (bs.mutex.statusFlag == null) {
    bs.mutex.statusFlag = $("#juggernaut-status");
  }
  if (bs.mutex.statusFlag.parents('#juggernaut-info-box')[0]) { //new layout
    
    var statusText = bs.mutex.statusTexts[status];
    bs.mutex.statusFlag.html(statusText);
  } else { //old layout
    var alterText = bs.mutex.alts[status];
    bs.mutex.statusFlag.attr("title", alterText);
  }
  bs.mutex.statusFlag.attr("class", "juggernaut-status-" + status);
  
  return false;
}

$(document).bind('juggernaut:connected', bs.mutex.connected);
$(document).bind('juggernaut:connect', bs.mutex.connect);
$(document).bind('juggernaut:errorConnecting', bs.mutex.errorConnecting);
$(document).bind('juggernaut:disconnected', bs.mutex.disconnected);
