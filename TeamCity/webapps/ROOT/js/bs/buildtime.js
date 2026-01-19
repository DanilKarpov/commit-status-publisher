(function ($) {
  BS.BuildTime = {
    dateRange : 'LAST24H',
    sortBy: 'DURATION',
    sortAsc: true,
    groupBy: 'DURATION',
    groupAsc: true,
    isRescanRunning: false,
    showArchived: false,
    hideSmall: true,

    init: function (dateRange, sortBy, sortAsc, groupBy, groupAsc, isRescanRunning, showArchived, hideSmall, blankPage, agentPool) {
      this.dateRange = dateRange;
      this.sortBy = sortBy;
      this.sortAsc = sortAsc;
      this.groupBy = groupBy;
      this.groupAsc = groupAsc;
      this.isRescanRunning = isRescanRunning;
      this.showArchived = showArchived;
      this.hideSmall = hideSmall;
      this.agentPool = agentPool;

      var self = this;

      $('#dateRange24').on("click", _.bind(this.changeRange, this));
      $('#dateRangeWeek').on("click", _.bind(this.changeRange, this));
      $('#dateRangeMonth').on("click", _.bind(this.changeRange, this));
      $('#groupedCB').on("click", _.bind(this.regroup, this));
      $('#showArchived').on("click", _.bind(this.rehide_archived, this));
      $('#agentPoolId').on("change", _.bind(this.changePool, this));

      if (blankPage) {
        this.do_request_delayed(this.make_params(this.dateRange, sortBy, sortAsc, groupBy, groupAsc), 0);
      }
    },

    wait_for_rescan_finish: function(timeout, refreshableElement) {
      this.do_request_delayed(this.make_params(this.dateRange, this.sortBy, this.sortAsc, this.groupBy, this.groupAsc, false, true), timeout, refreshableElement);
    },

    refresh_now: function(refreshableElement) {
      this.do_request_delayed(this.make_params(this.dateRange, this.sortBy, this.sortAsc, this.groupBy, this.groupAsc), 0, refreshableElement);
    },

    do_request: function (params, element) {
      this.do_request_delayed(params, 0, element);
    },

    do_request_delayed: function (params, timeout, refreshableElement) {
      if (typeof refreshableElement === 'undefined') {
        refreshableElement = $('#diskUsageContainer');
      }
      BS.CollapsableBlocks.unregisterBlocks("diskusage");
      $('.ajax_update_progress').html('<i class="icon-refresh icon-spin ring-loader-inline"></i> Refreshing...');
      setTimeout(function () {
        refreshableElement.get(0).refresh(null, params + '&allData=true');
      }, timeout !== 'undefined' && timeout > 0 ? timeout : 0);
    },

    rehide_archived: function () {
      this.do_request(this.make_params(this.dateRange,this.sortBy, this.sortAsc, this.groupBy, this.groupAsc, false, this.isRescanRunning) +
                      "&hideArchived=" + this.showArchived);
    },

    rehide_small: function () {
      this.do_request(this.make_params(this.dateRange, this.sortBy, this.sortAsc, this.groupBy, this.groupAsc, false, this.isRescanRunning) +
                      "&hideSmall=" + !this.hideSmall);
    },

    make_params: function (dateRange, sortBy, sortAsc, group, groupedAsc, runFullRescan, awaiting, filterByAgent) {
      var params = "dateRangeType=" + dateRange;

      params += "&sortBy=" + sortBy + "&sortAsc=" + sortAsc;

      if (typeof group !== 'undefined' && group != null) {
        params += "&groupBy=" + group;
      }

      if (typeof groupedAsc !== 'undefined') {
        params += "&groupedAsc=" + groupedAsc;
      }

      if (runFullRescan) {
        params += "&refresh=true";
      }

      if (typeof awaiting !== 'undefined' && awaiting) {
        params += "&awaiting=true";
      }

      if (typeof filterByAgent !== 'undefined' && filterByAgent != null && filterByAgent != '') {
        params += "&agentPoolId=" + filterByAgent;
      }
      return params;
    },

    refresh: function (dateRange, sortBy, sortAsc, group, groupedAsc, runFullRescan, awaiting, agentPoolId, element) {
      this.do_request(this.make_params(dateRange, sortBy, sortAsc, group, groupedAsc, runFullRescan, awaiting, agentPoolId), element);
    },

    resort: function (e) {
      var element = e.target;

      function getDefaultAsc(elementCN) {
        if (elementCN.indexOf('sorted') == -1) { // not sorted yet - checking default
          return elementCN.indexOf('descDefault') == -1;
        } else {
          return elementCN.indexOf('sortedDesc') >= 0;
        }
      }

      var sortBy = element.id;
      if (!sortBy) {
        element = element.firstChild;
        sortBy = element.id;
      }

      var elementCN = element.className;

      var sortAsc = getDefaultAsc(elementCN);
      var groupBy;
      if (elementCN.indexOf('grouped') > -1) { // changing direction of group column
        this.refresh(this.dateRange, element.id, sortAsc, element.id, sortAsc);
      } else if (element.parentNode.className.indexOf('groupable') > -1) { // change groupBy
        groupBy = element.id;
        this.refresh(this.dateRange, groupBy, sortAsc, groupBy, sortAsc);
      } else { // changing sorted group
        var groupColumn = $('span.grouped');
        var groupAsc = null;
        groupBy = null;

        if (groupColumn && groupColumn[0]) {
          groupBy = groupColumn[0].id;
          groupAsc = groupColumn[0].className.indexOf('sorted') != -1 && groupColumn[0].className.indexOf('sortedDesc') == -1;
        }

        if (groupBy != null) { // changing sorted column (non-group column) in grouped mode
          this.refresh(this.dateRange,groupBy, groupAsc, groupBy, groupAsc);
        } else { // changing sorted column in non-grouped mode
          this.refresh(this.dateRange, sortBy, sortAsc, 'null', this.groupAsc);
        }
      }
    },

    regroup: function (e) {
      var element = e.target;

      var group = element.id;

      if (!group) {
        element = element.firstChild;
        group = element.id;
      }

      var groupBy = element.checked ? "DURATION" : "null";
      this.refresh(this.dateRange, 'null', this.sortAsc, groupBy);
    },


    changeRange: function (e) {
      var element = e.target;
      var rb = element.id;
      var dateRange = element.checked ? element.value : "null";
      this.refresh(dateRange, 'null', this.sortAsc, this.groupBy);
    },


    changePool: function (e) {
      var element = e.target;
      this.refresh(this.dateRange, 'null', this.sortAsc, this.groupBy, this.groupAsc, undefined, undefined, $j(element).val());
    },

    initSortableHolder: function (name) {
      var sortableHolder = $(BS.Util.escapeId(name));
      if (!sortableHolder.hasClass("groupable")) {
        if (this.sortBy == name) {
          sortableHolder.addClass(this.sortAsc ? " sortedAsc" : " sortedDesc");
        }
        sortableHolder.parent().on("click", _.bind(this.resort, this));
      }
    },

    initGroupableHolder: function (name) {
      var groupedColumn = $(BS.Util.escapeId(name));
      if (groupedColumn.length > 0) {
        if (this.groupBy == name) {
          groupedColumn.addClass("grouped");
          if (!groupedColumn.hasClass("sorted")) {
            groupedColumn.addClass(this.groupAsc ? " sortedAsc" : " sortedDesc");
          }
        }
      }
    },

    showPopup: function (element, id) {
      this.BuildsStatsPopup.showPopupNearElement(element, {
        parameters: 'buildType=' + id
      });
    },

    hidePopup: function () {
      this.BuildsStatsPopup.hidePopup(500, false);
    },

    submitStartFullScan: function (lastTime) {
      var message = "Full scan can require significant time. You can avoid it as disk usage data will be updated incrementally. "
          + (lastTime != null ? "\nLast time full scan took " + lastTime + ". " : "") + "\nAre you sure you want to start full scan now?";

      BS.confirm(message, function () {
        this.refresh(this.dateRange, this.sortBy, this.sortAsc, this.groupBy, this.groupAsc, true, false, $j("#updatingProgress"));
      }.bind(this));

      return false;
    }
  };

})(jQuery);
