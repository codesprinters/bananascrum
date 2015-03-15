/**
 * Sample markup that will be handled by the following script.
 *
 * <div class="tabbed-content">
 *    <!-- Tab links -->
 *    <div class="tabs-links" id="tabs-identifier">
 *        <a class="tab current-tab" href="#tab1-content">
 *        <a class="tab" href="#tab2-content">
 *        <div class="floatClearer" />
 *    </div>
 *    <div class="tabs-contents tabs-identifier">
 *        <!-- Content div ids correspond to hrefs in tab links.
 *             Element with current-tab class is visible. Clicking on proper link
 *             will change current-tab class and make other tab visible
 *        -->
 *        <div id="tab1-content" class="tab-content current-tab-content">Tab1 content</div>
 *        <div id="tab2-content" class="tab-content">Tab2 content</div>
 *    </div>
 * </div>
 */

bs.tabs = {};

/**
 * Returns element that containis tabs contents
 * @param {Object} element jQuery selector for tab link
 * @return {Object} jQuery selector for tabs-contents
 */
bs.tabs.getTabsContentsContainer = function(element) {
  var identifier = element.parents('.tabs-links').attr('id');
  return $('.tabbed-content.' + identifier).find('.tabs-contents');
};

/**
 * Returns element that containis tab links
 * @param {Object} element jQuery selector for tab link
 * @return {Object} jQuery selector for tabs-links
 */
bs.tabs.getTabsLinksContainer = function(element) {
  return element.parents('.tabs-links');
};


/**
 * Handles action of clicking on the link within the tab
 */
bs.tabs.tabClickedHandler = function(ev) {
  ev.stopPropagation();
  ev.preventDefault();
  
  var tab = $(this);
  bs.tabs.setCurrentTab(tab);

  return false;
};

/**
 * Sets given tab as current
 * @param {Object} tab jQuery selector for tab
 */
bs.tabs.setCurrentTab = function(tab) {
  // find link and element again as we're not sure what was clicked
  // and we have to handle whether it was li or a or div with round graphic
  var tabLinkContainer = tab.closest(".tab");
  var tabLink;
  if (tabLinkContainer.is("a")) {
    tabLink = tab;
  } else {
    tabLink = tabLinkContainer.find("a");
  }

  // Current tab was clicked don't need to do anything.
  if (tabLink.hasClass("current-tab") || tabLink.parent().hasClass("current-tab")) {
    return false;
  }

  var tabsContainer = bs.tabs.getTabsLinksContainer(tabLink);
  tabsContainer.find('.tab').removeClass('current-tab').parent().removeClass('current');
  tabLinkContainer.addClass('current-tab').parent().addClass('current');
  
  var hashPart = ($.browser.msie && $.browser.version == 7) ? "#" + tabLink.attr("href").split("#")[1] : tabLink.attr("href");
  
  if (!tabsContainer.hasClass('ignore-hashpart')) { 
    window.location.hash = hashPart;
  }
  var contentContainer = bs.tabs.getTabsContentsContainer(tabLinkContainer);
  contentContainer.find('.tab-content').removeClass("current-tab-content");
  contentContainer.find(hashPart).addClass('current-tab-content').trigger('bs:tabChanged');
};

/**
 * Handles case when given url has hash part. Ex. #users
 */
bs.tabs.handleHashPart = function(tabs) {
  var hashPart = window.location.hash;
  if (! hashPart || hashPart.length === 0) {
    return;
  }
  tabs.each(function() {
    var link = $(this);
    if (link.attr('href') == hashPart) {
      link.trigger('click');
      return false;
    }
    return true;
  });
};

/**
 * Detects and installs tabs behaviour on elements with tabbed-content class
 */
bs.tabs.install = function() {
  var tabs = $('.tabs-links .tab').live('click', bs.tabs.tabClickedHandler);
  bs.tabs.handleHashPart(tabs);
};
