BS.ChangeBlock = Class.create(BS.BlocksWithHeader, {
  initialize: function($super, elementId) {
    $super(elementId);
  },

  getBlockContentElement: function(id) {
    var el = $(id);

    if (!el || !el.parentNode) return;

    $(el.parentNode).cleanWhitespace();
    var contentDiv = el.nextSibling.nextSibling;
    if (!contentDiv) alert("No contentDiv for " + el.id);
    return contentDiv;
  }
});
