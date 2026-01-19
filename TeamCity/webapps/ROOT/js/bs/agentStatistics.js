BS.AgentsStatistics = {
  buildTypeToProject: {},
  _sep: '<br/>',

  init_filter: function() {
    $j('#agentsStatsFilter').on('submit', function () {
      BS.AgentStatisticsFilter.submitFilter();
      return false;
    });
    $j('#groupByPools').on('click', function () {
      BS.AgentStatisticsFilter.submitFilter();
    });

    $j('#sortOrder').on('change', function () {
      BS.AgentStatisticsFilter.submitFilter();
    });
  },

  init: function () {

    var idleHandler = this.showTooltipIdle.bind(this);
    var oneHandler = this.showAjax.bind(this);
    var groupHandler = this.showTooltipGroup.bind(this);
    var mouseoutHandler = this.hidePopup.bind(this);

    $j('.agentLines').on('mouseover mouseout', 'div', function (e) {
      var el = $j(this);

      var buildTypeId = el.data('build-type-id'),
          buildId = el.data('build-id'),
          buildsCount = el.data('builds-count'),
          segStartTime = el.data('seg-start-time'),
          segFinishTime = el.data('seg-finish-time'),
          segDuration = el.data('seg-duration'),
          segBuildNumber = el.data('build-number'),
          segBuildStatus = el.data('build-status'),
          running = el.data('build-running'),
          runningSince = el.data('build-running-since');

      if (e.type == 'mouseover') {
        switch (el.data('kind')) {
          case 'idle':
            idleHandler(e, segStartTime, segFinishTime, segDuration);
            break;
          case 'one':
            oneHandler(buildTypeId, buildId, e, segStartTime, segFinishTime, segDuration, segBuildNumber, segBuildStatus,
                       running, runningSince);
            break;
          case 'group':
            groupHandler(buildsCount, e, segStartTime, segFinishTime, segDuration, running, runningSince);
        }
      } else {
        mouseoutHandler();
      }
    });
  },

  _showTooltip: function (event, message) {
    this.ajaxPopup.showText(event, message);
  },

  _timeMessage: function (start, finish, duration) {
    return 'Duration on agent: ' + this._bold(duration) + this._sep +
           '(' + start + ' - ' + finish + ')' + this._sep;
  },

  _projMessage: function (bt) {
    return this._url("/project.html?tab=projectOverview&projectId=" + this.buildTypeToProject[bt][1], this.buildTypeToProject[bt][2]) + " / "
               + this._url("/viewType.html?buildTypeId=" + bt, this.buildTypeToProject[bt][0]) + this._sep;
  },

  _bold: function (str) {
    return "<strong>" + str + "</strong>";
  },

  showTooltipIdle: function (event, start, finish, duration) {
    this._showTooltip(event, 'Idle' + this._sep + this._timeMessage(start, finish, duration));
  },

  showTooltipGroup: function (length, event, start, finish, duration, running, runningSince) {
    var runningInfo = "";
    if (running) {
      runningInfo = "Last build is still running since " + runningSince;
    }
    this._showTooltip(event, length + ' builds' + this._sep + 'Total ' + this._timeMessage(start, finish, duration) + runningInfo);
  },

  _url: function (target, label) {
    return "<a href='" + window['base_uri'] + target + "'>" + label + "</a>";
  },

  showAjax: function (bt, id, event, start, finish, duration, segBuildNumber, segBuildStatus, running, runningSince) {
    if (bt) {
      if (id > 0) {
        this.ajaxPopup.showBuild(event, id, bt);
      } else {
        var info;
        if (running) {
          info = this._projMessage(bt) +
                 "Build: " + "#" + segBuildNumber + this._sep +
                 '<i>Running since ' + runningSince + ' (' + this._bold(duration) + ')</i>'
        } else {
          info = this._projMessage(bt) +
                 "Build: " + "#" + segBuildNumber + " " + segBuildStatus + this._sep +
                 this._timeMessage(start, finish, duration) +
                 '<i>Build is already cleaned up from history</i>';
        }

        this._showTooltip(event, info);
      }
    } else {
      this._showTooltip(event, 'Build is inaccessible' + this._sep + this._timeMessage(start, finish, duration));
    }
  },

  hidePopup: function () {
    this.ajaxPopup.hidePopup(500);
  },

  createFindAgentNameFunction: function (baseUrl) {
    return function (request, response) {
      var term = request.term;
      var url = baseUrl + '?term=' + encodeURIComponent(term);
      $j.getJSON(url, function(data) {
        response(data);
      });
    }
  },

  resetFilter: function () {
    // For some mysterious reason it doesn't work properly in Chrome without a timeout...
    setTimeout(function () {
      $j("#agentName").val("");
    }, 50);
  },

  decorateDateInputs: function () {
    var opts = {
      dateFormat: "dd M yy",
      showButtonPanel: true
    };

    $j("#dateFrom").datepicker(opts);
    $j("#dateTo").datepicker(opts);
  }
};

BS.AgentsStatistics.ajaxPopup = new (Class.create(BS.Popup, {
  baseOptions: {
    method: 'get',
    afterShowFunc: function () {
    },
    innerText: undefined,
    forceReload: true
  },

  key: function (buildId, buildType) {
    return buildType + '@' + buildId;
  },

  showBuild: function (event, buildId, buildTypeId) {
    var key = this.key(buildId, buildTypeId);
    this.showPopup(event, OO.extend(this.baseOptions, {
      url: window['base_uri'] + "/buildpopup.html?id=" + buildId + "&bt=" + buildTypeId
    }));
  },
  showText: function (event, text) {
    this.options.url = undefined;
    this.options.innerHTML = text;
    this.showPopup(event, OO.extend(this.baseOptions, {
      innerHTML: text
    }));
  }
}))("buildpopup");


BS.AgentStatisticsFilterBase = OO.extend(BS.AbstractWebForm, {
  submitFilter: function () {
    var that = this;
    BS.Util.show("agentStatisticsProgress");
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      makeError: function (name, elem) {
        $j('#error_' + name).text(elem.firstChild.nodeValue);
        that.highlightErrorField($(name));
      },

      onBeginSave: function (form) {
        BS.ErrorsAwareListener.onBeginSave(form);
      },

      onDateFromError: function (elem) {
        this.makeError("dateFrom", elem);
      },

      onDateToError: function (elem) {
        this.makeError("dateTo", elem);
      },

      onCompleteSave: function (form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
        that.onComplete(form, responseXML, err);
      }
    }));

    return false;
  }
});

BS.AgentStatisticsFilter = (OO.extend(BS.AgentStatisticsFilterBase, {
  formElement: function () {
    return $('agentsStatsFilter');
  },

  onComplete: function (form, responseXML, err) {
    if (!err) {
      form.setSaving(true);
      BS.reload(true);
    } else {
      BS.Util.hide("agentStatisticsProgress");
      form.enable();
    }
  }
}));

BS.AgentStatisticsTable = {};

BS.AgentStatisticsTable.ajaxPopup = OO.extend(
    new BS.Popup("statsBuildPopup"), {
      baseOptions: {
        method: 'post',
        url: undefined,
        innerText: undefined,
        shift: {x: -80, y: 25}
      },

      UI: {
        _dt: function (x, y) {
          return "<div class='dt'>" + x + ": <span class='dd'>" + y + "</span></div>";
        },

        _dl: function (x) {
          return "<dl>" + x + "</dl>";
        },

        _createBaseMessage: function (agentPrefix, agent, buildPrefix, build) {
          return this._dt(agentPrefix, agent) + this._dt(buildPrefix, build);
        },

        createNotUsedCell: function (agentPrefix, agent, buildPrefix, build, compatible) {
          return this._dl(this._createBaseMessage(agentPrefix, agent, buildPrefix, build))
                     + "<span class='note'>" + (compatible ? buildPrefix + " is compatible. " : "") + "No builds were run</span>";
        },

        createUsedCell: function (agentPrefix, agent, buildPrefix, build, duration, count) {
          return this._dl(this._createBaseMessage(agentPrefix, agent, buildPrefix, build)
                              + this._dt("Duration", duration)
                              + this._dt("Total builds", count));
        }
      },

      _agentPrefix: function (col) {
        return $('statsTypeCol_' + col).innerHTML;
      },

      _agent: function (col) {
        return $('statsCol_' + col).innerHTML;
      },

      _buildPrefix: function (row) {
        return $('statsTypeRow_' + row).innerHTML;
      },

      _build: function (row) {
        return $('statsRow_' + row).innerHTML;
      },

      showForUnusedNotCompatibleAgent: function (el, row, col) {
        this.showText(el, this.UI.createNotUsedCell(this._agentPrefix(col), this._agent(col), this._buildPrefix(row), this._build(row), false));
      },

      showForUnusedCompatibleAgent: function (el, row, col) {
        this.showText(el, this.UI.createNotUsedCell(this._agentPrefix(col), this._agent(col), this._buildPrefix(row), this._build(row), true));
      },

      showForUsedCell: function (el, row, col, count) {
        this.showText(el, this.UI.createUsedCell(this._agentPrefix(col), this._agent(col), this._buildPrefix(row), this._build(row), el.innerHTML, count));
      },

      _createOptions: function (el) {
        var element = $(el);
        return OO.extend(this.baseOptions, {
          afterHideFunc: function () {
            element.removeClassName("selected");
          }.bind(this),
          afterShowFunc: function () {
            element.addClassName("selected");
          }.bind(this)
        });
      },

      showText: function (el, text) {
        this.options.url = undefined;
        this.options.innerHTML = text;
        this.showPopupNearElement(el, OO.extend(this._createOptions(el), {
          url: undefined,
          innerHTML: text
        }));
      }
    }
);

BS.AgentStatisticsTable.initDelegates = function () {
  var popup = BS.AgentStatisticsTable.ajaxPopup;
  var table = $j('.agentStatisticsTable');

  var s = popup.showForUsedCell.bind(popup);
  var c = popup.showForUnusedCompatibleAgent.bind(popup);
  var u = popup.showForUnusedNotCompatibleAgent.bind(popup);
  var o = popup.hidePopup.bind(popup);

  table.on('mouseover', '.astS, .astC, .astO', function () {
    var params = $j(this).data('params');

    if (params) {
      params = params.split(':');
    }

    this.className.indexOf('astS') > -1 && params.length == 3 && s(this, params[0], params[1], params[2]);
    this.className.indexOf('astC') > -1 && params.length == 2 && c(this, params[0], params[1]);
    this.className.indexOf('astO') > -1 && params.length == 2 && u(this, params[0], params[1]);
  });

  table.on('mouseout', '.astS, .astC, .astO', function () {
    o();
  });
};

BS.AgentStatisticsTableFilter = (OO.extend(BS.AgentStatisticsFilterBase, {
  formElement: function () {
    return $('agentsStatsFilter');
  },

  onComplete: function (form, responseXML, err) {
    BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
    if (!err) {
      BS.reload(true);
    } else {
      form.enable();
    }
  }
}));
