// Simply overwrites prototype specific functions 
// with jquery specific versions 

Juggernaut.fn.fire_event = function(fx_name) {
     jQuery(document).trigger("juggernaut:" + fx_name);
   };

Juggernaut.fn.bindToWindow = function() {
    jQuery(window).bind("load", this, function(e) {
      juggernaut = e.data;
      e.data.appendFlashObject();
    });
  };

Juggernaut.toJSON = function(hash) {
    return jQuery.toJSON(hash) ;
  };

Juggernaut.parseJSON = function(string) {
    return jQuery.parseJSON(string);
  };

Juggernaut.fn.swf = function(){
    return jQuery('#' + this.options.swf_name)[0];
  };
  
Juggernaut.fn.appendElement = function() {    
    this.element = jQuery('<div id=juggernaut>');
    jQuery("body").append(this.element);
  };

Juggernaut.fn.refreshFlashObject = function(){
    jQuery(this.swf()).remove();
    this.appendFlashObject();
  };

Juggernaut.fn.reconnect = function () {
  var i;
  if (this.options.reconnect_attempts) {
    this.attempting_to_reconnect = true;
    this.fire_event('reconnect');
    this.logger('Will attempt to reconnect ' +
        this.options.reconnect_attempts + ' times, the first in ' +
        (this.options.reconnect_intervals || 3) + ' seconds');
    var self = this;
    for (i=0; i < this.options.reconnect_attempts; i++) {
      setTimeout(function () {
        if (!self.is_connected) {
          self.logger('Attempting reconnect');
          if (!self.ever_been_connected) {
            self.refreshFlashObject();
          } else {
            self.connect();
          }
        }
      }, (this.options.reconnect_intervals || 3) * 1000 * (i + 1));
    }
  }
};

Juggernaut.fn.connected = function (e) {
  var json = Juggernaut.toJSON(this.handshake());
  var self = this;
  this.sendData(json);
  this.ever_been_connected = true;
  this.is_connected = true;
  setTimeout(function () {
    if (self.is_connected) self.attempting_to_reconnect = false;
  }, 1 * 1000);
  this.logger('Connected');
  this.fire_event('connected');
};
