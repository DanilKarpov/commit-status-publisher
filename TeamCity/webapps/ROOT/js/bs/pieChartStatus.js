BS.PieStatus = {
  BAD_BUILD_TEMPLATE: new Template('<div class="badBuild">&mdash; <a href="#{buildLink}" target="_blank" rel="noreferrer">#{configName}</a></div>'),
  R: 9, // Chart radius

  drawPlaceholder: function(carpetEl) {
    if ( carpetEl && !carpetEl.down(".statusDiagram") ) {
      carpetEl.addClassName("carpetMain");
      var r = this.R;
      new Raphael(this._initDiagram(carpetEl), r*2, r*2).circle(r, r, r).attr({"stroke-width": 1, stroke: "#d0d0d0"})
    }
  },

  /**
   * @param carpetEl td element with the carpet
   * @return id of the element for the diagram
   */
  _initDiagram: function(carpetEl) {
    if (carpetEl) {
      carpetEl.update("<div class='statusDiagram'/>");
      return carpetEl.down(".statusDiagram").identify();
    }
  },

  drawCarpetPieChart: function (showDetailsScript, carpetEl, carpetData) {
    var id = this._initDiagram(carpetEl);

    var values = {
      pending: {count: 0, color: "#dbdbdb", title: "Pending builds"}, // Includes queued, not triggered
      successful_running: {count: 0, color: "#a5f2b2", title: "Running successfully"},
      cancelled: {count: 0, color: "var(--ring-disabled-color, #999)", title: "Canceled builds"},
      success: {count: 0, color: "#7acc8b", title: "Successful builds"},
      fail: {count: 0, color: "#ffadb3", title: "Failed builds without new problems"},
      fail_new: {count: 0, color: "#a90f1a", title: "Builds with new/critical problems"}
    };
    var sequence = ['fail_new', 'fail', 'success', 'cancelled', 'successful_running', 'pending'];

    var linksToBadBuilds = "";
    for (var i = 0; i < carpetData.length; i++) {
      var data = carpetData[i];
      switch (data.statusText) {
        case "pending":
          values["pending"].count++;
          break;
        case "successful_running":
          values["successful_running"].count++;
          break;
        case "cancelled":
          values["cancelled"].count++;
          break;
        case "successful":
          values["success"].count++;
          break;
        case "notCriticalProblem":
          values["fail"].count++;
          break;
        case "compilationError":
        case "newTestsFailed":
        case "criticalProblem":
          values["fail_new"].count++;
          linksToBadBuilds += this._badBuildRow(data);
          break;
      }
    }

    // Draw the pie chart
    var r = this.R;
    new Raphael(id, r*2, r*2).pieChart(r, r, r,
                                     _.map(sequence, function(val) { return values[val]['count']}),
                                     _.map(sequence, function(val) { return values[val]['color']}));

    // Init on mousehover popup:
    var popupContent = this._buildPiePopup(showDetailsScript, sequence, values, linksToBadBuilds);
    var that = this;
    $j("#" + id).on("click mouseenter", function(event) {
      BS.Tooltip.showMessage($(id), {
        shift: {x: 5, y: 20},
        delay: 200,
        className: 'pieChartPopupContainer',
        afterShowFunc: function(popup) {
          that.lastPieTooltip = popup;
        }
      }, popupContent);
    });
    $j("#" + id).on("mouseleave", function(event) {
      BS.Tooltip.hidePopup();
    })
  },

  hidePiePopup: function() {
    // We need this because we may have lost the last opened popup in BS.Tooltip.popup (it becomes null before popup is actually hidden).
    if (this.lastPieTooltip) {
      this.lastPieTooltip.hidePopup(0, true);
      this.lastPieTooltip = null;
    }
  },

  _buildPiePopup: function(showDetailsScript, sequence, values, linksToBadBuilds) {
    var popupContent = "<div class='pieChartPopup'><table class='pieChartHelp'>";
    _.each(sequence, function(val) {
      var data = values[val];
      if (data.count > 0) {
        var title = data.title;
        if (linksToBadBuilds != null && val == 'fail_new') {
          title += linksToBadBuilds;
        }
        popupContent += "<tr><td>" + title + "</td><td class='colored' style='background-color: " + data.color + "'>&nbsp;</td><td class='count'>" + data.count + "</td></tr>\n";
      }
    });
    popupContent += "</table>";

    popupContent += "<div><a href='#' onclick=\"" + showDetailsScript + "; BS.PieStatus.hidePiePopup(); return false;\">Show details &raquo;</a></div>";
    return popupContent + "</div>";
  },

  _badBuildRow: function(square) {
    return this.BAD_BUILD_TEMPLATE.evaluate({
                                        buildLink: square.firstBuildId ? ("viewLog.html?buildId=" + square.firstBuildId +
                                                                          "&tab=buildResultsDiv&buildTypeId=" + square.buildType.id) : "javascript://",
                                        configName: this._configName(square.buildType)
                                      });
  },

  _configName: function(btObject) {
    return btObject != null ? btObject.fullName.replace(/"/, "&quot;") : "Unknown build configuration";
  }
};

