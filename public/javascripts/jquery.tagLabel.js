(function($) {
  $.widget("ui.tagLabel", {
    _init: function() {
      var self = this;
      // clean up
      $('.tag-color-options-container').remove();
      $('.set-tag-color').removeClass("opened");
      // prepare the widget html
      self.optionsContainer = $('<div class="tag-color-options-container">');
      for (i = 1; i <= 24; i++) {
        var colorOption = self._renderOption(i);
        self.optionsContainer.append(colorOption);
      }

      // display
      self.open();
    },

    _renderOption: function(colorNumber) {
      var html = '<div class="tag-color-option tag-color-' + colorNumber + '">a</div>';
      return $(html);
    },

    outerClose: function(ev) {
      if ($(ev.target).hasClass("set-tag-color")) { return };

      var self = ev.data.instance;
      if ($(ev.target).parents('.tag-color-options-container').size() === 0) {
        $('.tag-color-options-container').remove();
        $(document).unbind('click.tagLabel', self.outerClose);
        self._close();
      }
    },

    open: function() {
      var self = this;
      $(self.element).after(self.optionsContainer);
      this.fixPosition();
      $(self.element).addClass("opened");
      $(self.optionsContainer).find('.tag-color-option').bind('click', {instance: self}, self.saveColor);
      $(document).bind('click.tagLabel', {instance: self}, self.outerClose);
    },

    close: function(ev) {
      var self = ev.data.instance;
      ev.stopPropagation();
      self._close();
    },

    _close: function() {
      var self = this;
      self.element.removeClass("opened");
      $(self.optionsContainer).remove();
      self.destroy();
    },

    fixPosition: function() {
      var offset = this.element.offset();
      var offsetParent = this.element.parent().offset();
      this.optionsContainer.css({left: offset.left - offsetParent.left + 'px' });
    },

    getTagId: function() {
      var self = this;
      var activatorId = $(self.element).attr("id");
      return activatorId.split('-').pop();
    },

    _findColorNo: function(element) {
      var classes = $(element).attr('class').split(' ');
      for (i = 0; i < classes.length; i++) {
        var className = classes[i];
        if (className.match(/tag-color-\d/)) {
          return className.split('-').pop();
        }
      }
      return null;
    },

    saveColor: function(ev) {
      var self = ev.data.instance;
      var tagId = self.getTagId();
      var colorNo = self._findColorNo(ev.target);
      var action = projectTagPath(bs._project, tagId);
      var params = {};
      params['tag[color_no]'] = colorNo;
      bs.put(action, params, bs.tags.updateTag, null, 'json');
    }
  });

  $.ui.tagLabel.getter = "getTagId"
})(jQuery);