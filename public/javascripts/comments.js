bs.comments = {};

bs.comments.createSuccess = function(data) {
  bs.item.factory({id: data.item, callback: function() {
    bs.item.setNumberOfComments.call(this, data.number);
    var comment = $(data.html);
    var comments = this.find('.comments');
    var form = this.find('.new-comment');
    if (! comments[0]) { //fallback for old layout
      comments = $('#facebox .comments');
      form = $('#facebox form');
    }
    
    comment.prependTo(comments);
    comments.scrollTop(0);
    comment.highlight();
    form.replaceWith(data.form);
    bs.comments.bindForm.call(form);
    comments.trigger('bs:itemSizeChanged');
  }});
  return false;
};


bs.comments.bindForm = function() { 
  var form = $(this).closest('form.new-comment');
  bs.ajax.submitFormBinder(form, bs.comments.createSuccess, null, 'json');
};

bs.comments.showCommentsLinkClick = function(ev) {  // this link is present only in old layout
  var link = jQuery(this);
  var url = bs.getUrl(link);
  
  bs.dialog.loadToModal(url);
  return false;
};


jQuery(document).ready(function() {
  jQuery('.show-comments-link').live('click', bs.comments.showCommentsLinkClick);
});

