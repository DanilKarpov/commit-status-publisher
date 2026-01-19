(function($) {
  BS.CompatibilityUtils = {
    rewriteUrlIfAllHash: function() {
      if (location.hash == "#all") {
        location.href = this._getUrlWithoutHash() + "&showAll=true";
      }
    },

    showFromOtherPools: function(showButton) {
      this._togglePoolDetailsMessage();
      $('#inactiveConfigurationsTableParent').show();

      var additionalParams = 'showAll=true';
      if (BS.AgentRunPolicy._getCheckedBuildTypeIds().length > 0) {
        additionalParams += '&buttonEnabled=true';
      }
      $('#inactiveConfigurationsTable').get(0).refresh(null, additionalParams + (showButton ? '&showButton=true' : ''), function() {
        BS.AgentRunPolicy.showAll = true;
        BS.CompatibilityUtils._rewriteUrlAfterInactiveLoaded();
      });
      var offset = $("#inactiveConfigurationsTable").offset();
      window.scrollTo(0, offset ? offset.top : 0);
      return false;
    },

    hideFromOtherPools: function() {
      this._togglePoolDetailsMessage();
      $("#inactiveConfigurationsTableParent").hide();
      this._rewriteUrlAfterInactiveHidden();
      BS.AgentRunPolicy.showAll = false;
      return false;
    },

    _replaceUrl: function(url, hash) {
      if (history.replaceState) {
        history.replaceState(null, null, url);
      } else {
        location.hash = hash;
      }
    },

    _rewriteUrlAfterInactiveLoaded: function() {
      this._replaceUrl(location.hash ? this._getUrlWithoutHash() + "&showAll=true" + location.hash : location.href + "&showAll=true", "#all");
    },

    _rewriteUrlAfterInactiveHidden: function() {
      if (location.hash == "#all") {
        location.hash = "";
      } else {
        this._replaceUrl(this._getUrlWithoutHash().replace("&showAll=true", ""), "");
      }
    },

    _togglePoolDetailsMessage: function() {
      $("#poolDetails > span, #poolDetailsBottom").toggle();
    },

    _getUrlWithoutHash: function() {
      var length = location.href.indexOf("#");
      return length == -1 ? location.href : location.href.substr(0, length);
    },

    initAgentCompatibility: function() {
      $("div.compatibilityDetailsToolbar span.expand-collapse a").each(function(idx) {
        $(this).click(function() {
          var expandOrCollapse = (idx != 0);
          if (expandOrCollapse) {
            BS.CollapsableBlocks.expandAll(true, 'all');
          } else {
            BS.CollapsableBlocks.collapseAll(true, 'all');
          }
          return false;
        })
      });
    }
  };
})(jQuery);

