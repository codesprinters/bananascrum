// callbacks required by ofc2 flash plugin  
function open_flash_chart_data() {
  var background = "DAE0ED";
  return JSON.stringify({
    "elements": [], 
    "title": { "text": ""}, 
    "bg_colour": background, 
    "y_axis": {
      "labels": [ '' ],
      "grid-colour": background , 
      "colour": background 
    }, 
    "x_axis": {
      "grid-colour": background ,
      "colour": background 
    }
  });
}

function ofc_ready () {
  element = $('#burnchart-chart');
  if (element.length && typeof element.get(0).load == 'function') {
    if (bs.burnchart._data.hasOwnProperty(bs.burnchart.activeChart())) {
      element.get(0).load(bs.burnchart._data[bs.burnchart.activeChart()]);
    }
  }
}

// end of callbacks

bs.burnchart = {};

bs.burnchart._data = {};

bs.burnchart._cookieName = 'sprint-chart-type';

bs.burnchart._tabsHeight = $("#burntabs").height();

bs.burnchart.reload = function(text) {
  $.extend(bs.burnchart._data, text);
  if ($('object#burnchart-chart').length) {
    ofc_ready();
  }
};

bs.burnchart.handleSwitch = function() {
  var type = $(this).attr('id').split('-')[1];
  $.cookie(bs.burnchart._cookieName, type);
  ofc_ready();
  bs.burnchart.markActiveTab();
};

bs.burnchart.markActiveTab = function() {
  if (typeof bs.burnchart.forceChart == "undefined") {
    bs.burnchart.switchTab(bs.burnchart.getCurrentChartName());
  } else {
    $('#burntabs').hide();
  }
};

bs.burnchart.desiredWidth = function() {
  if (bs._layout === "new") {
    var leftWidth = $('#left-content').width();
    var margin = 16;

    // For timeline section
    var statsWidth = $('.chart-section .stats').width();
    if (statsWidth > 0) {
      margin = 26;
    }
    
    return leftWidth - statsWidth - 2 * margin;
  } else {
    return 800;
  }
};

bs.burnchart.resize = function() {
  if (bs._layout === "new") {
    var desiredWidth = bs.burnchart.desiredWidth();
    var desiredHeight = bs.burnchart.desiredHeight();
    $('object#burnchart-chart').attr('width', desiredWidth);
    $('object#burnchart-chart').attr('height', desiredHeight);
    var burnchart = $('.burnchart');
    var burnchartContainer = $('.burnchart-container');
    burnchart.width(desiredWidth);
    burnchart.height(desiredHeight);
    burnchartContainer.width(burnchart.outerWidth());
    burnchartContainer.height(burnchart.outerHeight() + bs.burnchart._tabsHeight);
    $('.burnchart-border').width(burnchartContainer.outerWidth());
    $('.burnchart-border').height(burnchartContainer.outerHeight() );
  }
};

/**
 * Retrieves name of appropriate chart depending if there's sth in cookie
 * and if this value has any data in bs.burnchart._data, if no fetch first
 * available
 */
bs.burnchart.getCurrentChartName = function() {
  if (bs.burnchart._data.hasOwnProperty($.cookie(bs.burnchart._cookieName))) {
    return $.cookie(bs.burnchart._cookieName);
  } else {
    return bs.burnchart.firstChartAvailable();
  }
}

/**
 * Switches chart tabs to the given one
 * @param {String} tabName must be part of id
 */
bs.burnchart.switchTab = function(tabName) {
  $('#burntabs').show();
  $('.burntype-switch').removeClass('active');
  $('#burn-' + tabName).addClass('active');
}


bs.burnchart.activeChart = function() {
  if (typeof bs.burnchart.forceChart != "undefined") {
    return bs.burnchart.forceChart;
  } else {
    return bs.burnchart.getCurrentChartName();
  }
};

bs.burnchart.firstChartAvailable = function() {
  var burnchartData = bs.burnchart._data;
  for (var chartName in burnchartData) {
    if (burnchartData.hasOwnProperty(chartName)) {
      return chartName;
    }
  }
  return '';
}

bs.burnchart.desiredHeight = function() {
  if (bs._chart_fullscreen) {
    return $(window).height() - 100;
  } else {
    return (bs._layout === 'new' ? '179' : '250');
  }
};


$(document).ready(function() {
  if (! $.cookie(bs.burnchart._cookieName)) {
    $.cookie(bs.burnchart._cookieName, bs.burnchart.firstChartAvailable());
  }
  bs.burnchart.markActiveTab();

  if (! $('object#burnchart-chart').length && $('div#burnchart-chart').length) { 
    swfobject.embedSWF(bs._burnchartPath, "burnchart-chart", bs.burnchart.desiredWidth().toString(), bs.burnchart.desiredHeight(), "9.0.0", null, {}, {wmode: 'transparent'}, {wmode: 'transparent'});
  }
  $('.burntype-switch:not(.active)').live('click', bs.burnchart.handleSwitch);
  bs.burnchart.resize();
});
