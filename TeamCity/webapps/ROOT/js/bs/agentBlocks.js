(function($) {
  BS.AgentBlocks = OO.extend(BS.BaseMultiElementBlocks, {
    blocksType: "agentPool",
    collapsedByDefault: false,

    collapseAllHandler: function() {
      if (BS.AgentsReact) {
        BS.AgentsReact.collapseAll();
      }
      this.collapseAll();
    },

    expandAllHandler: function() {
      if (BS.AgentsReact) {
        BS.AgentsReact.expandAll();
      }
      this.expandAll();
    },

    getBlockContentElement: function(id) {
      return $(".agentRow-" + id);
    },

    iterateHandles: function(id, handler) {
      $(".agentBlockHandle-" + id).each(function() {
        handler(this);
      });
    },

    iterateBlocks: function(handler) {
      $(".agentBlockHandle").each(function() {
        handler(this.id.replace(/^agentBlockHandle:/, ''));
      });
    }
  });
})(jQuery);
