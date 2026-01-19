BS.BuildChangesBlock = Class.create(BS.BlocksWithHeader, {

  initialize: function ($super, elementId) {
    $super(elementId, true);
  },

  getBlockContentElement: function (id) {
    var el = $(id + "_changes");
    if (!el) return;

    return el;
  },

  onHideBlock: function ($super, contentElement, id) {
    $super(contentElement, id);
    BS.ChangesPopup.updatePopup();
  },

  onShowBlock: function ($super, contentElement, id) {
    $super(contentElement, id);
    BS.ChangesPopup.updatePopup();
  }
});
