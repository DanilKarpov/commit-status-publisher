BS.BaseAgentMatrixBlocks = OO.extend(BS.BaseMultiElementBlocks, {
  collapsedByDefault: false,
  collapsedIcon: "/img/tree/plus16.png",
  expandedIcon: "/img/tree/minus16.png"
});

BS.AgentMatrixAgentBlocks = OO.extend(BS.BaseAgentMatrixBlocks, {
  _blocks: {}, // this overriding is needed to prevent sharing of this field between BS.AgentMatrixAgentBlocks and BS.AgentMatrixBuildTypeBlocks
  _blockContentElements: {},
  blocksType: "agentMatrixPool",
  poolHeaderColSpanById: {},

  getBlockContentElement: function(id) {
    return this._blockContentElements[id] = this._blockContentElements[id] || $j(".poolCell-" + id);
  },

  iterateHandles: function(id, handler) {
    handler($("poolHandle:" + id));
  },

  iterateBlocks: function(handler) {
    $j(".poolHandle").each(function() {
      handler(this.id.replace(/^poolHandle:/, ''));
    });
  },

  onHideBlock: function(contentElement, id) {
    $("poolHeader:" + id).colSpan = 1;
  },

  onShowBlock: function(contentElement, id) {
    $("poolHeader:" + id).colSpan = this.poolHeaderColSpanById[id] || 1;
  }
});

BS.AgentMatrixBuildTypeBlocks = OO.extend(BS.BaseAgentMatrixBlocks, {
  _blocks: {}, // this overriding is needed to prevent sharing of this field between BS.AgentMatrixAgentBlocks and BS.AgentMatrixBuildTypeBlocks
  _blockContentElements: {},
  blocksType: "agentMatrixProject",

  getBlockContentElement: function(id) {
    return this._blockContentElements[id] = this._blockContentElements[id] || $j(".projectRow-" + id);
  },

  iterateHandles: function(id, handler) {
    handler($("projectHandle:" + id));
  },

  iterateBlocks: function(handler) {
    $j(".projectHandle").each(function() {
      handler(this.id.replace(/^projectHandle:/, ''));
    });
  }
});
