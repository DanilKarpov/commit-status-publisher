BS.Blocks = Class.create({

  _blocks: {},
  blocksType : "",
  collapsedByDefault: true,   // if true, we store in DB expanded blocks
                              // if false, we store in DB collapsed blocks
  mustPersistState: true,

  initialize: function() {
    this._blocks = {};
  },

  getBlockContentElement: function(id) {},
  onHideBlock: function(contentElement, id) {},
  onShowBlock: function(contentElement, id) {},

  toggleBlock: function(el, now) {
    this._realToggle(el, now);
    this._saveState();
  },

  restoreSavedBlocks: function() {
    if (!this.mustPersistState) return;
    var blocks = BS.Blocks._saved[this.blocksType];
    if (!blocks) return;
    var savedArray = blocks.split(":");
    for(var i = 0; i < savedArray.length; i++) {
      if (savedArray[i] && savedArray[i] != 'null') {
        this.changeState(savedArray[i], true, this.collapsedByDefault);
      }
    }
  },

  _saveState: function(onStateSaved) {
    if (!this.mustPersistState) {
      if ($j.isFunction(onStateSaved)) {
        onStateSaved();
      }
      return;
    }

    var saved = "";
    for(var i in this._blocks) {
      saved += i + ":";
    }

    BS.ajaxRequest(window['base_uri'] + "/ajax.html", {
      parameters: "blocksType=" + this.blocksType + "&state=" + saved,
      onComplete: function () {
        if($j.isFunction(onStateSaved)) {
          onStateSaved();
        }
      }
    });
  },

  _realToggle: function(id, now, type) {
    type = type || '';

    var contentElement = this.getBlockContentElement(id);
    if (!contentElement) return;
    BS.blockRefreshTemporary();

    // When action type is specified explicitly, visibility won't be tested - speed-up
    if (type == 'collapse' || this.isVisible(contentElement)) {
      this.changeState(id, now, false);
    } else if (type == 'expand' || !this.isVisible(contentElement)) {
      this.changeState(id, now, true);
    }
    contentElement = null;
  },

  isExpanded: function(id) {
    var contentElement = this.getBlockContentElement(id);
    if (!contentElement) return false;
    return this.isVisible(contentElement);
  },

  changeState: function(id, now, showBlock) {
    var contentElement = this.getBlockContentElement(id);
    if (!contentElement) return;

    //console.warn("changeBlock show " + this.blocksType + " " + id + ": " + !!showBlock);
    if (showBlock) {
      this.doShow(id, contentElement);

      if (this.collapsedByDefault) {
        this._addBlockData(id);
      }
      else {
        this._deleteBlockData(id);
      }

      this.onShowBlock(contentElement, id);
    } else {
      this.doHide(id, contentElement);

      if (this.collapsedByDefault) {
        this._deleteBlockData(id);
      }
      else {
        this._addBlockData(id);
      }

      this.onHideBlock(contentElement, id);
    }
  },

  isVisible: function(contentElement) {
    return BS.Util.visible(contentElement);
  },

  doShow: function(id, contentElement) {
    $j(contentElement).show(); // can't use BS.Util.show here because it is no longer synchronous
  },

  doHide: function(id, contentElement) {
    $j(contentElement).hide(); // can't use BS.Util.hide here because it is no longer synchronous
  },

  _addBlockData: function(id) {
    this._blocks[id] = true;
  },

  _deleteBlockData: function(id) {
    delete this._blocks[id];
  }
});

BS.Blocks._saved = {};

BS.BaseMultiElementBlocks = new (Class.create(BS.Blocks, {
  collapsedIcon: "",
  expandedIcon: "",
  
  iterateHandles: function(id, handler) {},
  iterateBlocks: function(handler) {},
  
  collapseAll: function() {
    var that = this;
    this.iterateBlocks(function(id) {
      if (that.isExpanded(id)) {
        that._realToggle(id, true, 'collapse');
      }
    });
    this._saveState();
  },

  expandAll: function() {
    var that = this;
    this.iterateBlocks(function(id) {
      if (!that.isExpanded(id)) {
        that._realToggle(id, true, 'expand');
      }
    });
    this._saveState();
  },

  isVisible: function(contentElements) {
    return contentElements.length && BS.Util.visible(contentElements[0]);
  },

  doShow: function(id, contentElements) {
    contentElements.each(function() {
      BS.Util.show(this);
    });
    var that = this;
    this.iterateHandles(id, function(handle) {
      if ($j(handle).is('span.handle')) {
        $j(handle).removeClass('handle_collapsed').addClass('handle_expanded');
      } else if (handle) {
        handle.src = window['base_uri'] + that.expandedIcon;
      }
    });
  },

  doHide: function(id, contentElements) {
    contentElements.each(function() {
      BS.Util.hide(this);
    });
    var that = this;
    this.iterateHandles(id, function(handle) {
      if ($j(handle).is('span.handle')) {
        $j(handle).addClass('handle_collapsed').removeClass('handle_expanded');
      } else if (handle) {
        handle.src = window['base_uri'] + that.collapsedIcon;
      }
    });
  }
}))();
