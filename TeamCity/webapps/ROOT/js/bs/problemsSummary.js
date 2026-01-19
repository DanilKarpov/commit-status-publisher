(function($) {
  BS.ProblemsSummary = {
    _buildTypes: [],
    _lastUpdate: new Date().getTime(),
    _timeout: 0,

    requestBuildTypeUpdate: function(btId) {
      if (this._buildTypes.indexOf(btId) == -1) {
        this._buildTypes.push(btId);
      }

      this._scheduleUpdate();
    },

    requestUpdateAll: function() {
      var that = this;
      $("#overviewMain").find("div.tableCaption").each(function() {
        var id = this.id;
        var btId = id.substr(0, id.length - 4);
        that.requestBuildTypeUpdate(btId);
      });
    },

    _scheduleUpdate: function() {
      if (!this._timeout) {
        var that = this;
        var timeDiff = new Date().getTime() - that._lastUpdate;
        var expTime = BS.internalProperty('teamcity.ui.problemsSummary.pollInterval') * 1000;
        var timeout = (timeDiff > expTime) ? 100 : Math.max(100, expTime - timeDiff);
        this._timeout = setTimeout(this.update.bind(this), timeout);
      }
    },

    update: function() {
      var currentBuildTypes = this._buildTypes;
      this._buildTypes = [];
      this._lastUpdate = new Date().getTime();
      this._timeout = 0;

      if (!currentBuildTypes.length) {
        return;
      }

      var parameters = $.extend({
                                   getProblemsSummary: currentBuildTypes.join(",")
                                 }, BS.Branch.getAllBranches());

      var that = this;
      BS.ajaxRequest(window['base_uri'] + "/ajax.html", {
        parameters: parameters,
        onSuccess: function(transport) {
          var root = BS.Util.documentRoot(transport);
          if (!root) {
            return;
          }

          var i;
          var buildTypeNodes = root.childNodes;
          for (i = 0; i < buildTypeNodes.length; ++i) {
            var node = buildTypeNodes[i];
            that._doUpdateInUI(node);

            // Remove from 'currentBuildTypes'.
            var btId = node.getAttribute("btId");
            currentBuildTypes.splice($.inArray(btId, currentBuildTypes), 1);
          }

          // Hide others.
          for (i = 0; i < currentBuildTypes.length; ++i) {
            that.hideSummaryFor(currentBuildTypes[i]);
          }
        }
      });
    },

    _doUpdateInUI: function(node) {
      var btId = node.getAttribute("btId");
      var projectExternalId = node.getAttribute("projectId");
      var failed = node.getAttribute("failed");
      var invest = node.getAttribute("invest");
      var fixed = node.getAttribute("fixed");
      var muted = node.getAttribute("muted");

      if (failed + invest + fixed + muted == 0) {
        return;
      }

      if (ReactUI) {
        ReactUI.createAndRender('problemsSummary:' + btId, ReactUI.ProblemsSummary, {
          btId: btId,
          projectExternalId: projectExternalId,
          failed: failed,
          invest: invest,
          fixed: fixed,
          muted: muted
        });

        return;
      }

      var caption = $("#" + btId + "-div");
      var currentSummary = caption.find(".problemsSummary");

      currentSummary.html("");

      var currentSummaryExists = currentSummary.length;

      if (!currentSummaryExists) {
        currentSummary = $('<span class="problemsSummary"/>').attr({
                                                                      title: "View problems summary for this build configuration"
                                                                    });
      }

      var link = $('<a class="summaryLink"/>').attr({
                                                       href: window['base_uri'] + "/project.html?projectId=" + projectExternalId + "&tab=problems&buildTypeId=" + btId
                                                     }).append("<span>Test<span class='problemDetails'> failure</span>s:</span> ");

      if (failed > 0) {
        this._getSpan("", failed, "not investigated", invest + fixed + muted > 0).appendTo(link);
      }
      if (invest > 0) {
        this._getSpan("taken", invest, "under investigation", fixed + muted > 0).appendTo(link);
      }
      if (fixed > 0) {
        this._getSpan("fixed", fixed, "marked as fixed", muted > 0).appendTo(link);
      }
      if (muted > 0) {
        this._getSpan("muted red", muted, "muted", false).appendTo(link);
      }

      link.appendTo(currentSummary);

      if (!currentSummaryExists) {
        currentSummary.appendTo(caption)
      }
    },

    _getSpan: function(icon, num, details, comma) {
      var iconSpan = $('<span class="icon icon16 problemIcon bp '+ icon + '"></span>');
      var numSpan = $('<span class="bp-number">'+ num +'</span>');
      var detailsSpan = $('<span class="problemDetails"/>').html(details).append(comma ? ", " : "");
      return $("<span/>").append(iconSpan).append(numSpan).append(' ').append(detailsSpan);
    },

    hideSummaryFor: function(btId) {
      $("#" + btId + "-div").find(".problemsSummary").html("");
    }
  };  
})(jQuery);

