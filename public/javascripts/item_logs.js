(function($) {

  $.widget("ui.itemlogs", {
    _init: function() {
      var self = this;
      this._readFilters();
      
      
      this.element.find(".show-more-logs").bind('click', function() { self._showMoreClickHandler($(this)); return false;});
      this._getFiltersForm().bind('submit', function() { self._submitFilterFormHandler($(this)); return false;});
    },
    
    _getFiltersForm: function() {
      return this.element.find(".log-filter-form");
    },
    
    _submitFilterFormHandler: function(form) {
      var self = this;
      var url = form.attr('action');
      this._readFilters();
      var params = this._buildRequestParams();
      var success = function(env) {
        self._getLogList().html(env.html);
        self._updateRemainingCount(env);
      };
      bs.get(url, params, success, null, 'json');
      return false;
    },
    
    _readFilters: function() {
      this.storedFilters = this._getFiltersForm().toJSON();
    },
    
    _getLogList: function() {
      return this.element.find('ul.item-logs');
    },
    
    _getNumberOfLogsVisible: function() {
      return this._getLogList().find('li.item-log').length;
    },
    
    _getFirstLogTimestamp: function() {
      return this._getLogList().find('li:first .history-date-field').attr('title');
    },
    
    _showMoreClickHandler: function(element) {
      var self = this;
      var params = this._buildRequestParams();
      var url = element.attr('href');
      if (element.hasClass('all')) {
        delete params.limit;
      }
      params['skip_count'] = this._getNumberOfLogsVisible();
      params['older_than'] = this._getFirstLogTimestamp();
      
      var success = function(env) {
        self._getLogList().append(env.html);
        self._updateRemainingCount(env);
      };
      
      bs.get(url, params, success, null, 'json');
      return false;
    },
    
    _buildRequestParams: function() {
      var params = this.storedFilters;
      params['limit'] = this.options['limit'];
      return params;
    },
    
    _updateRemainingCount: function(env) {
      this.element.find('.more-logs-count').html(env.logs_remaining);
    }
  });
  
  $.ui.itemlogs.defaults = {
    limit: 10
  };
  
})(jQuery);


