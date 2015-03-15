(function($){

  $.fn.recolorRows = function(options) {
    var defaults = {
      rowClass: ''
    };
  
    options = $.extend(defaults, options);
  
    this.find(options.rowClass).removeClass('odd').removeClass('even');
    this.find(options.rowClass + ':odd').addClass('odd');
    this.find(options.rowClass + ':even').addClass('even');
  
    return this;
  };

  $.fn.focusOnFirstInput = function() {
    var input = this.find(":text:enabled:first").trigger('focus');
    
    return this;
  };
  
  $.fn.appendAt = function(element, selector, position) {
    var destination = this.find(selector + ':eq(' + position + ')');
    if (! destination.length || position == -1) {
      this.append(element);
    } else {
      destination.before(element);
    }
    return this;
  };

  $.fn.toJSON = function() {
    var result = {};
    var array = this.serializeArray();
    $.each(array, function(i, element) { result[element.name] = element.value; } );
    return result;
  };

  $.fn.toJSONWithoutWatermarks = function() {
    var results = this.toJSON();

    // clear watermarked fields
    var watermarkedFields = this.find('.has-watermark');
    $.each(watermarkedFields, function() {
      delete(results[this.name]);
    });

    return results;
  }
  
  $.fn.setClassIf = function(condition, klass) {
    if (condition) {
      this.addClass(klass);
    } else {
      this.removeClass(klass);
    }
    return this;
  };
  
  $.fn.highlight = function() {
    return this.effect('highlight');
  };
  
  $.fn.timeoutRemoveClass = function(timeout, klass) {
    var element = this;
    setTimeout(function() {
      element.removeClass(klass);
    }, timeout);
    return this;
  };

})(jQuery);
