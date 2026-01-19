BS.QueueLikeSorter = {
  containerId: null,

  getActionUrl: function () {
  },

  getActionParameters: function (node, selector) {
  },

  afterOrderSaving: function () {
  },

  _timoutHandle: null,

  scheduleUpdate: function (node, selector) {
    this.updateMoveTopIcons();
    if (this._timoutHandle) {
      clearTimeout(this._timoutHandle);
    }
    this._timoutHandle = setTimeout(this.saveOrder.bind(this, node, selector), 1000);
  },

  updateMoveTopIcons: function () {
    var queue = $(this.containerId);
    if (!queue) {
      return;
    }
    var moveTopIcons = queue.select(".tc-icon_move-top");
    if (!moveTopIcons) return;
    for (var i = 0; i < moveTopIcons.length; i++) {
      if (moveTopIcons[i] == null) continue;
      if (i == 0) {
        moveTopIcons[i].style.visibility = 'hidden';
      } else {
        moveTopIcons[i].style.visibility = '';
      }
    }
  },

  saveOrder: function (node, selector) {
    if (!node) return;
    this.setOrderSaving(true);
    var that = this;
    BS.ajaxRequest(that.getActionUrl(), {
      parameters: that.getActionParameters(node, selector),
      onComplete: function (transport, object) {
        that.setOrderSaving(false);
        that.afterOrderSaving();
      }
    });
  },

  setOrderSaving: function (saving) {
    if (saving) {
      BS.Util.hide("dataSaved");
      BS.Util.show('savingData');
    } else {
      window.setTimeout(function () {
        BS.Util.hide('savingData');
        BS.Util.show("dataSaved");
        window.setTimeout(function () {
          BS.Util.hide("dataSaved");
        }, 3000);
      }, 1000);
    }
  },

  moveToTop: function (node) {
    var elem = $(node);
    var parent = elem.parentNode;
    if (parent.firstChild.id == elem.id) return; // do not move first item
    parent.removeChild(elem);
    parent.insertBefore(elem, parent.firstChild);
    this.scheduleUpdate(parent);
  },

  computeOrder: function (node, prefix, selector) {
    var toProcess = [];
    if (selector) {
      toProcess = $('buildQueueTable').select(selector);
    } else if (node.childNodes && node.childNodes.length > 0) {
      $(node).cleanWhitespace();
      toProcess = node.childNodes;
    }
    var order = "";
    for (var i = 0; i < toProcess.length; i++) {
      var id = toProcess[i].id;
      if (!id || id.indexOf(prefix) != 0) continue;
      order += toProcess[i].id.substring(prefix.length) + ";";
    }
    return order;
  }
};
