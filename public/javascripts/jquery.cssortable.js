(function($) {

  $.widget("ui.cssortable", $.extend( $.ui.sortable.prototype, {
    // methods _getItemsAsjQuery and _refreshItems are overloaded only because of the different plugin name 'sortable' -> 'cssortable'

    _getItemsAsjQuery: function(connected) {
      var self = this;
      var items = [];
      var queries = [];
      var connectWith = this._connectWith();

      if(connectWith && connected) {
        for (var i = connectWith.length - 1; i >= 0; i--){
          var cur = $(connectWith[i]);
          for (var j = cur.length - 1; j >= 0; j--){
            var inst = $.data(cur[j], 'cssortable');    // here is change in comparision to the original method
            if(inst && inst != this && !inst.options.disabled) {
              queries.push([$.isFunction(inst.options.items) ? inst.options.items.call(inst.element) : $(inst.options.items, inst.element).not(".ui-sortable-helper"), inst]);
            }
          };
        };
      }

      queries.push([$.isFunction(this.options.items) ? this.options.items.call(this.element, null, { options: this.options, item: this.currentItem }) : $(this.options.items, this.element).not(".ui-sortable-helper"), this]);

      for (var i = queries.length - 1; i >= 0; i--){
        queries[i][0].each(function() {
                items.push(this);
        });
      };

      return $(items);
    },

    _refreshItems: function(event) {

      this.items = [];
      this.containers = [this];
      var items = this.items;
      var self = this;
      var queries = [[$.isFunction(this.options.items) ? this.options.items.call(this.element[0], event, { item: this.currentItem }) : $(this.options.items, this.element), this]];
      var connectWith = this._connectWith();

      if(connectWith) {
        for (var i = connectWith.length - 1; i >= 0; i--){
          var cur = $(connectWith[i]);
          for (var j = cur.length - 1; j >= 0; j--){
            var inst = $.data(cur[j], 'cssortable');      // here is change in comparision to the original method
            if(inst && inst != this && !inst.options.disabled) {
              queries.push([$.isFunction(inst.options.items) ? inst.options.items.call(inst.element[0], event, { item: this.currentItem }) : $(inst.options.items, inst.element), inst]);
              this.containers.push(inst);
            }
          };
        };
      }

      for (var i = queries.length - 1; i >= 0; i--) {
        var targetData = queries[i][1];
        var _queries = queries[i][0];

        for (var j=0, queriesLength = _queries.length; j < queriesLength; j++) {
          var item = $(_queries[j]);

          item.data('sortable-item', targetData); // Data for target checking (mouse manager)

          items.push({
            item: item,
            instance: targetData,
            width: 0, height: 0,
            left: 0, top: 0
          });
        };
      };

    },
  

    // this method is overloaded to ignore vertical/horizontal intersection if widget's axis is set
    _intersectsWithPointer: function(item) {

      var isOverElementHeight = $.ui.isOverAxis(this.positionAbs.top + this.offset.click.top, item.top, item.height),
        isOverElementWidth = $.ui.isOverAxis(this.positionAbs.left + this.offset.click.left, item.left, item.width),
        weCareAboutHeight = (!this.options.axis || this.options.axis === 'y'),
        weCareAboutWidth = (!this.options.axis || this.options.axis === 'x'),
        isOverElement = (!weCareAboutHeight || isOverElementHeight) && (!weCareAboutWidth  || isOverElementWidth),
        verticalDirection = this._getDragVerticalDirection(),
        horizontalDirection = this._getDragHorizontalDirection();

      if (!isOverElement)
        return false;

      return this.floating ?
        ( ((horizontalDirection && horizontalDirection == "right") || verticalDirection == "down") ? 2 : 1 )
        : ( verticalDirection && (verticalDirection == "down" ? 2 : 1) );
    }
  }));

  $.ui.cssortable.defaults = $.ui.sortable.defaults;
  $.ui.cssortable.eventPrefix = $.ui.sortable.eventPrefix;
  $.ui.cssortable.getter = $.ui.sortable.getter;
})(jQuery);