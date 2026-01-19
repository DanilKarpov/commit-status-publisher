BS.CollapsableBlocks = {

  registerBlock: function(block, blocksType) {
    var blocks = this._blocks(blocksType);
    var id = block.getId();
    blocks[id] = block;
  },

  unregisterBlocks: function(blocksType) {
    if (blocksType) {
      delete this._allBlocks[blocksType];
    }
  },

  collapseAll: function(saveState, blocksType) {
    var blocks = this._blocks(blocksType);
    for (var id in blocks) {
      if (!blocks.hasOwnProperty(id)) continue;

      var block = blocks[id];
      if (block.isExpanded(id)) {
        if (block.hideBlock) {
          block.hideBlock();
        } else {
          block.changeState(id, true, false);
          if (saveState) {
            block._saveState();
          }
        }
      }
    }
    return false;
  },

  expandAll: function(saveState, blocksType) {
    var blocks = this._blocks(blocksType);
    for (var id in blocks) {
      if (!blocks.hasOwnProperty(id)) continue;

      var block = blocks[id];
      if (!block.isExpanded(id)) {
        if (block.showBlock) {
          block.showBlock();
        } else {
          block.changeState(id, true, true);
          if (saveState) {
            block._saveState();
          }
        }
      }
    }
    return false;
  },

  _blocks: function(blocksType) {
    blocksType = blocksType || "default";
    this._allBlocks[blocksType] = this._allBlocks[blocksType] || {};
    return this._allBlocks[blocksType];
  },

  _allBlocks: {}
};
