(function ($) {
  BS.DiskUsage = {
    sortBy: 'TOTAL_SIZE',
    sortAsc: true,
    groupBy: 'TOTAL_SIZE',
    groupAsc: true,
    isRescanRunning: false,
    showArchived: false,
    hideSmall: true,
    artifactStorageId: '<All>',

    init: function (sortBy, sortAsc, groupBy, groupAsc, isRescanRunning, showArchived, hideSmall, blankPage, artifactStorageId) {
      this.sortBy = sortBy;
      this.sortAsc = sortAsc;
      this.groupBy = groupBy;
      this.groupAsc = groupAsc;
      this.isRescanRunning = isRescanRunning;
      this.showArchived = showArchived;
      this.hideSmall = hideSmall;
      this.artifactStorageId = artifactStorageId;

      var self = this;

      $(document).on("mouseover", ".commentIconWrapper", function (event) {
        self.showPopup(this, jQuery(this).attr("popup-data"));
      });
      $(document).on("mouseout", ".commentIconWrapper", function (event) {
        self.hidePopup();
      });

      $('#groupedCB').on("click", _.bind(this.regroup, this));
      $('#showArchived').on("click", _.bind(this.rehide_archived, this));
      $('#hideSmall').on("click", _.bind(this.rehide_small, this));
      $('#artifactStorageId').on("change", function () {
        self.updateDisplayedStorageId(this.value)
      });

      if (blankPage) {
        this.do_request_delayed(this.make_params(sortBy, sortAsc, groupBy, groupAsc, artifactStorageId), 0);
      }
    },

    wait_for_rescan_finish: function(timeout, refreshableElement) {
      this.do_request_delayed("&awaiting=true", timeout, refreshableElement);
    },

    refresh_now: function(refreshableElement) {
      this.do_request_delayed(this.make_params(this.sortBy, this.sortAsc, this.groupBy, this.groupAsc, this.artifactStorageId), 0, refreshableElement);
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
      this.do_request(this.make_params(this.sortBy, this.sortAsc, this.groupBy, this.groupAsc, this.artifactStorageId, false, this.isRescanRunning) +
                      "&hideArchived=" + this.showArchived);
    },

    rehide_small: function () {
      this.do_request(this.make_params(this.sortBy, this.sortAsc, this.groupBy, this.groupAsc, this.artifactStorageId, false, this.isRescanRunning) +
                      "&hideSmall=" + !this.hideSmall);
    },

    make_params: function (sortBy, sortAsc, group, groupedAsc, storageId, awaiting) {
      var params = "sortBy=" + sortBy + "&sortAsc=" + sortAsc;

      if (typeof group !== 'undefined' && group != null) {
        params += "&groupBy=" + group;
      }

      if (typeof groupedAsc !== 'undefined') {
        params += "&groupedAsc=" + groupedAsc;
      }

      if (typeof awaiting !== 'undefined' && awaiting) {
        params += "&awaiting=true";
      }

      if (typeof storageId === 'undefined') {
        storageId = this.artifactStorageId;
      }

      params += "&storageId=" + storageId;

      return params;
    },

    refresh: function (sortBy, sortAsc, group, groupedAsc, artifactStorageId, awaiting, element) {
      this.do_request(this.make_params(sortBy, sortAsc, group, groupedAsc, artifactStorageId, awaiting), element);
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
        this.refresh(element.id, sortAsc, element.id, sortAsc);
      } else if (element.parentNode.className.indexOf('groupable') > -1) { // change groupBy
        groupBy = element.id;
        this.refresh(groupBy, sortAsc, groupBy, sortAsc);
      } else { // changing sorted group
        var groupColumn = $('span.grouped');
        var groupAsc = null;
        groupBy = null;

        if (groupColumn && groupColumn[0]) {
          groupBy = groupColumn[0].id;
          groupAsc = groupColumn[0].className.indexOf('sorted') != -1 && groupColumn[0].className.indexOf('sortedDesc') == -1;
        }

        if (groupBy != null) { // changing sorted column (non-group column) in grouped mode
          this.refresh(groupBy, groupAsc, groupBy, groupAsc);
        } else { // changing sorted column in non-grouped mode
          this.refresh(sortBy, sortAsc, 'null', this.groupAsc);
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

      var groupBy = element.checked ? "TOTAL_SIZE" : "null";
      this.refresh('null', this.sortAsc, groupBy);
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

      if (confirm(message)) {
        BS.ajaxRequest(window['base_uri'] + "/admin/action.html?rescanDiskUsage=true", {
          method: "post",
          onSuccess: () => {
            this.do_request("", $j("#updatingProgress"));
          }
        });
      }

      return false;
    },

    updateDisplayedStorageId: function (storageId) {
      this.artifactStorageId = storageId;
      this.refresh(this.sortBy, this.sortAsc, this.groupBy, this.groupAsc, storageId, false);
      return false;
    }
  };

  BS.DiskUsage.BuildsStatsPopup = new BS.Popup(
      'buildsStatsPopup', {
        delay: 500,
        hideDelay: 500,
        width: '500px',
        url: window['base_uri'] + '/admin/diskUsage/diskUsageBuildsStats.html',
        shift: {
          x: -520,
          y: 0
        },
        loadingText: 'Loading build data...'
      });

  BS.DiskUsage.BuildsStatsPopup.reload = function(/*String*/ buildTypeExtId) {
    var message = "Rescan can require significant time. You can avoid it as disk usage data will be updated incrementally. "
                  + "\nAre you sure you want to rescan this configuration now?";

    if (confirm(message)) {
      $j.ajax({
        url: window['base_uri'] + '/diskUsage.html',
        data: { buildTypeId: buildTypeExtId, action: 'reset' },
        method: "POST",
        dataType: "xml"
      }).done(function(data/*, textStatus, jqXHR*/) {
        var error = $j(data).find("error");
        if (error.length > 0) {
          alert(error.text());
        } else {
          BS.DiskUsage.refresh(BS.DiskUsage.sortBy, BS.DiskUsage.sortAsc, BS.DiskUsage.groupBy, BS.DiskUsage.groupAsc, BS.DiskUsage.artifactStorageId, false);
        }
      }).fail(function(/*jqXHR, textStatus, errorThrown*/) {
      });
    }

    return false;
  };
})(jQuery);
