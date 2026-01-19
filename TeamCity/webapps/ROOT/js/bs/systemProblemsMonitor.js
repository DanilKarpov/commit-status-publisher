//
// See class GetSystemProblemsAction
//

BS.SystemProblems = {
  problemIds: {}, //buildTypeId -> array of problem ids, each problem id corresponds to element on the page

  _problemType: null,
  _options: {},
  _lastFailures: {},
  _timer: null,

  startUpdates: function(problemType) {
    this._problemType = problemType;
    this.updateNow(true);
  },

  setOptions: function(options) {
    this._options = options;
  },

  updateNow: function(scheduleNextUpdate) {
    var that = this;
    var options = this._options;
    var problemType = this._problemType;
    var perBranch = this._options.perBranch;

    var branches = BS.Branch.getAllBranches();
    var params = $j.extend({}, branches);
    params["getSystemProblems"] = "true";
    if (problemType) { params["problemType"] = problemType; }
    if (perBranch) { params["allProblems"] = true; }
    if (options.btId) { params["btId"] = options.btId; }
    if (options.projectId) { params["projectId"] = options.projectId; } // external project id
    if (options.overview) { params["overview"] = true; }

    BS.ajaxRequest(window['base_uri'] + "/ajax.html", {
      parameters: params,
      method: "GET",
      evalScripts: false,
      onSuccess: function(transport) {
        try {
          var root = BS.Util.documentRoot(transport);
          if (!root) return;
          var buildNodes = root.childNodes;
          var currentFailures = {};
          var bt2errCount = {};
          var i, node, buildTypeId, id;

          BS.SystemProblems.cleanRemovedProblems();

          if (perBranch) {
            that._handleProblemsPerBranch(buildNodes, options.btId);
            return;
          }

          for (i = 0; i < buildNodes.length; i++) {
            node = buildNodes[i];
            buildTypeId = node.getAttribute("id");
            currentFailures[buildTypeId] = node.getAttribute("text");
            bt2errCount[buildTypeId] = parseInt(node.getAttribute("problemCount"));
            if (!currentFailures[buildTypeId]) currentFailures[buildTypeId] = "Configuration problems found";
          }

          for (id in that._lastFailures) {
            if (currentFailures[id] === undefined) {
              BS.SystemProblems.hideProblems(id);
            }
          }

          that._lastFailures = currentFailures;
          for (id in that._lastFailures) {
            if (currentFailures[id] !== undefined) {
              BS.SystemProblems.showProblems(id, currentFailures[id], bt2errCount[id]);
            }
          }

          if (scheduleNextUpdate) {
            if (that._timer) {
              clearTimeout(that._timer);
            }

            that._timer = setTimeout(function() {
              that.updateNow(true);
            }, BS.internalProperty('teamcity.ui.systemProblems.pollInterval') * 1000);
          }
        } catch (e) {
          BS.Log.warn(e);
        }
      }
    });
  },

  cleanRemovedProblems: function() {
    var buildTypeId, problems, i, newProblems;
    for (buildTypeId in BS.SystemProblems.problemIds) {
      problems = BS.SystemProblems.problemIds[buildTypeId];
      newProblems = [];
      if (problems) {
        for (i = 0; i < problems.length; i++) {
          if ($('buildType:' + problems[i] + ':systemProblems')) {
            newProblems.push(problems[i]);
          }
        }
        if (newProblems.length < problems.length) {
          BS.SystemProblems.problemIds[buildTypeId] = newProblems;
        }
      }
    }
  },

  hideProblems: function(buildTypeId) {
    var elems = BS.SystemProblems.getProblemElements(buildTypeId),
        i;
    for (i = 0; i < elems.length; i++) {
      BS.Util.hide(elems[i].problemElement);
      elems[i].problemElement.parentElement.classList.remove('runningBuildsDiv_warning');
    }

    if (BS.ProblemsSummary) {
      BS.ProblemsSummary.requestBuildTypeUpdate(buildTypeId);
    }
  },

  showProblems: function(buildTypeId, errorText, errorCount) {
    var elems = BS.SystemProblems.getProblemElements(buildTypeId),
        i;
    for (i = 0; i < elems.length; i++) {
      BS.SystemProblems.updateErrText(elems[i].problemTextElement, errorText, errorCount);
      BS.Util.show(elems[i].problemElement);
      elems[i].problemElement.parentElement.classList.add('runningBuildsDiv_warning');
    }

    if (BS.ProblemsSummary) {
      BS.ProblemsSummary.hideSummaryFor(buildTypeId);
    }
  },

  getProblemElements: function(buildTypeId) {
    var problems = this.problemIds[buildTypeId];
    if (problems) {
      return jQuery.map(problems, function(problemId) {
        return {problemElement:     $('buildType:' + problemId + ':systemProblems'),
                problemTextElement: $('buildType:' + problemId + ":systemProblemsText")};
      });
    } else {
      return [];
    }
  },

  registerProblemId: function(buildTypeId, problemId) {
    var existing = this.problemIds[buildTypeId];
    if (existing) {
      existing.push(problemId);
    } else {
      this.problemIds[buildTypeId] = [problemId];
    }
  },

  updateErrText: function(element, errorText, errorCount) {
    if (!element) return;

    errorText = errorText.escapeHTML();
    var maxLen = parseInt(element.getAttribute('data-maxWidth'));
    element.title = errorText.length > maxLen ? errorText : "";
    if (errorText.length > maxLen) {
      errorText = errorText.substr(0, maxLen) + "&hellip;";
    }

    if (errorCount > 1) {
      errorText +=  " (and " + (errorCount - 1) + " more)";
    }
    element.update(errorText);
  },

  _handleProblemsPerBranch: function(buildNodes, buildTypeId) {
    if (!buildNodes || !buildNodes.length) {
      return;
    }

    this.hideProblems(buildTypeId);

    var branchProblemMap = [];
    for (var i = 0; i < buildNodes.length; i++) {
      var node = buildNodes[i];
      var btId = node.getAttribute("id");
      if (buildTypeId != btId) {
        continue;
      }

      var text = node.getAttribute("text") || "Configuration problems found";
      var branch = node.getAttribute("additional");

      branchProblemMap[branch] = text;
    }

    var that = this;
    $j(".systemProblemsBarContainer[data-build-type='" + buildTypeId + "']").each(function() {
      var dataBranch = this.getAttribute('data-branch');
      var text = branchProblemMap[dataBranch];
      if (text) {
        BS.Util.show(this);
        that.updateErrText($j(this).children(".systemProblemsBarText")[0], text, 0);
      }
    });
  }
};

BS.SystemProblemsPopup = new BS.Popup("systemProblemDetails", {
  url: window['base_uri'] + "/systemProblems.html",
  method: "get",
  delay: 0,
  hideDelay: -1
});

BS.SystemProblemsPopup.showDetails = function(buildTypeId, problemType, problemSource, nearestElement) {
  if (this.isShown()) {
    this.hidePopup();
    return;
  }

  var params = "buildTypeId=" + buildTypeId;
  if (problemType != null && problemType != '')
    params += "&problemType=" + encodeURIComponent(problemType);
  if (problemSource != null && problemSource != '')
    params += "&problemSource=" + encodeURIComponent(problemSource);

  var branch = this.getUserBranch(nearestElement);
  if (branch != null) {
    params += "&userBranch=" + encodeURIComponent(branch);
  }

  this.options.parameters = params;
  this.options.shift = {
    x: 0,
    y: nearestElement.parentNode.offsetHeight + 8
  };

  this.showPopupNearElement(nearestElement.parentNode);
};

BS.SystemProblemsPopup.getUserBranch =  function(element) {
  var container = $j(element).closest(".systemProblemsBarContainer");
  if (!container) return null;
  var userBranch = container.attr("data-branch");
  if (!userBranch) return null;
  return userBranch;
};
