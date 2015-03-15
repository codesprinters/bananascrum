(function($) {
  $.widget("ui.selectCheckbox", {
    
    _optionHelper: function(data) {
      var text = "<label><input alt='" + data.label + "' class='checkbox-dropdown-input' type='checkbox' value='" + data.value.toString() + "' name='" + data.name + "'/>" + data.label + "</label>";
      return $(text);
    },
    
    _init: function() {
      var self = this;
      
      this.hidingPrevented = false;
     
      this.killerFn = function(e) {
        if ($(e.target).parents('.select-checkbox').size() === 0) {
          self.optionsDiv.hide();
          self._disableKillerFn();
        }
      };
      
      self.optionsDiv = $("<div class='select-checkbox'/>");
      
      if (self.options.paneClass) {
        self.optionsDiv.addClass(self.options.paneClass);
      }
      
      $.each(self.options.selectList, function(index, data) {
        var option = self._optionHelper(data);
        self.optionsDiv.append(option);
      });
      
      this._applyCss();
      this.fixPosition();
      if (!self.options.startOpen) {
        self.optionsDiv.hide();
      }

      this.element.after(self.optionsDiv);
      
      this.element.bind('click', function(e) { 
        self._toggleVisibility(e);
      });
      
      this.element.bind('focus', function(e) {
        self._showOptionsDiv(e);
        self._preventHiding();
      });
      
      this.element.bind($.browser.opera ? 'keypress' : 'keydown', function(e) {
        return self._keyDown(e);
      });
      
      this.optionsDiv.bind($.browser.opera ? 'keypress' : 'keydown', function(e) {
        return self._keyDown(e);
      });
      
      this.optionsDiv.find('input').bind('focus', function(e) { // checkboxes cannot be focused.. if they are browser binds them default keyboard actions which we don't want
        $(e.target).blur();
        $(self.element).focus();
      });

      this.element.blur(function() { self._enableKillerFn(); });
      
      this.element.parents('form').bind('reset', function(e) {
        return self._onReset(e);
      });
      
      this.optionsDiv.find('input').bind('change', function(e) {
        self._updateCheckedLabelClass($(this));
        self._updateLabel();
      });
      
      self._markDefaults();
    },
    
    _showOptionsDiv: function(e) {
      this.optionsDiv.show();
    },
    
    _markDefaults: function(e) {
      var self = this;
      self.optionsDiv.find('label').removeClass('checked');
      self.optionsDiv.find('input').each(function() {
        var input = $(this);
        if ($.inArray(input.attr('alt'), self.options.select) != -1) {
          input.attr('checked', true);
          input.parent().addClass('checked');
        }
      });
      self._updateLabel();
    },
    
    _onReset: function(e) {
      var self = this;
      setTimeout(function() { self._markDefaults(); }, 50);
      this.fixPosition();
      this.optionsDiv.hide();
    },
    
    _keyDown: function(e) {
      switch (e.keyCode) {
      case 27: //Event.KEY_ESC:
        this.optionsDiv.hide();
        break;
      case 13: //Event.KEY_RETURN:
        this.optionsDiv.hide();
        return true;
      case 9: //Event.KEY_TAB:
        this.optionsDiv.hide();
        return true;
      case 32: //Event.space
        this._toggleFocused();
        e.stopPropagation();
        return false;
      case 38: //event.key_up:
        this._arrowUp();
        e.stopPropagation();
        return false;
      case 40: //event.key_down:
        this._arrowDown();
        e.stopPropagation();
        return false;
      default:
        e.stopPropagation();
        return false;
      }
    },
    
    _toggleFocused: function() {
      var foc = this._getFocusedOption();
      if (foc) {
        var input = foc.find('input');
        input.attr('checked', !input.attr('checked'));
        this._updateCheckedLabelClass(input);
      }
      this._updateLabel();
    },
    
    _updateCheckedLabelClass: function(input) {
      if (input.attr('checked')) {
        input.parent().addClass('checked');
      } else {
        input.parent().removeClass('checked');
      }
    },
    
    _arrowDown: function() {
      var foc = this._getFocusedOption();
      if (foc) {
        this._unfocusOption();
        this._focusOption(foc.next('label'));
        
      } else {
        this._focusOption(this.optionsDiv.find('label:first'));
      }
    },
    
    _arrowUp: function() {
      var foc = this._getFocusedOption();
      if (foc) {
        this._unfocusOption();
        this._focusOption(foc.prev('label'));
      }
    },
    
    _focusOption: function(option) {
      if (option[0]) {
        option.addClass('focused');
        var offsetTop = option.position().top + this.optionsDiv.scrollTop() + option.height();
        var desiredScrollTop = (offsetTop > this.optionsDiv.height()) ? offsetTop - this.optionsDiv.height() : 0;
        this.optionsDiv.scrollTop(desiredScrollTop);
      }
    },
    
    _unfocusOption: function() {
      this.optionsDiv.find('label.focused').removeClass('focused');
    },
    
    _getFocusedOption: function() {
      var option = this.optionsDiv.find('label.focused');
      if (!option.length) {
        return null;
      }
      return option;
    },
    
    _enableKillerFn: function() {
      $(document).bind('click', this.killerFn);
    },

    _disableKillerFn: function() {
      $(document).unbind('click', this.killerFn);
    },
    
    _updateLabel: function() {
      var text = this.getSelectedLabels();
      
      if (!text || text === "") {
        text = this.options.emptyText;
      }
      this.element.attr('value', text);
    },
    
    _preventHiding: function(e) {
      var self = this;
      self.hidingPrevented = true;
      setTimeout(function() {
        self.hidingPrevented = false;
      }, 500);
    },
    
    _toggleVisibility: function(e) {
      this.fixPosition();     // for most of the time this is unnecessary. However if the page layout has changed the dropdown would be positioned wrong
      if (!(this.hidingPrevented && this.optionsDiv.is(':visible'))) {
        this.optionsDiv.toggle();
      }
    },
    
    _applyCss: function() {
      this.optionsDiv.css('position', 'absolute');
      this.optionsDiv.css('z-index', this.options.zindex);
      this.optionsDiv.css('max-height', this.options.maxHeight + 'px');
      this.optionsDiv.css('overflow', 'auto');
      this.optionsDiv.css('display', 'block');
      this.optionsDiv.css('text-align', 'left');
      this.optionsDiv.css('width', this.options.width + 'px');

      this.element.addClass('select-checkbox-input');
    },
    
    /* PUBLIC METHODS */
    
    getSelectedLabels: function() {
      var selected = [];
      this.optionsDiv.find("input:checked").each(function() {
        selected.push($(this).attr('alt'));
      });
      
      var text = selected.join();
      return text;
    },
    
    fixPosition: function() {
      var offset = this.element.offset();
      var offsetParent = this.element.offsetParent().offset();
      this.optionsDiv.css({ top: (offset.top + this.element.outerHeight() - offsetParent.top - 5) + 'px', left: offset.left - offsetParent.left - 5 + 'px' });
    }
  });
  
  $.ui.selectCheckbox.defaults = {
    emptyText: "unassigned",
    selectList: [], // list of hash with keys: name, label, value 
    select: [], // list of labels to start selected with
    zindex: 100,
    maxHeight: 70,
    paneClass: "checkbox-dropdown",
    width: 150
  };
  
  $.ui.selectCheckbox.getter = "getSelectedLabels";

})(jQuery);
