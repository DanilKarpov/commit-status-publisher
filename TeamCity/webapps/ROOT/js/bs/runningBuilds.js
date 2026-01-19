/**
 * Json received from the server is compressed - fields names are represented by one letter.
 * See RunBuildsStatusManager.
 */
BS.RunningBuilds = {

  subscribeOnBuild: function (buildId) {
    BS.SubscriptionManager.subscribe("rb/" + buildId, function(message) {
      if (!message) return;
      var buildNode = JSON.parse(message);
      if (!buildNode) return;

      var buildId = buildNode.id;
      var buildTypeId = buildNode.buildTypeId;

      BS.RunningBuilds.processNode(buildNode, buildId);

      if (BS.ProblemsSummary) {
        BS.ProblemsSummary.requestBuildTypeUpdate(buildTypeId);
      }
    })
  },

  unsubscribeFromBuild: function (buildId) {
    BS.SubscriptionManager.unsubscribe('rb/' + buildId);
  },

  processNode: function(node, buildId) {
    if (ReactUI) {
      ReactUI.receiveBuildWSData(node);
    }
    this.updateStatusIcon(node, buildId);
    this.updateDescription(node, buildId);
    this.updateDuration(node, buildId);
    if (!ReactUI) {
      this.updateProgress(node, buildId);
      this.updateArtifactsLink(node, buildId);
    }
  },

  findNestedDiv: function(element) {
    return $(element.getElementsByTagName("div")[0]);
  },

  isSuccessful: function (node) {
    return (node.status === "WARNING" || node.status === "SUCCESS");
  },

  updateStatusIcon: function(node, buildId) {
    var successful = BS.RunningBuilds.isSuccessful(node);
    var $container = $j('#build\\:' + buildId + '\\:img .js_buildStatusIcon');
    if ($container.length) {
      var container = $container.get(0);
      ReactUI.renderAnimatingIcon(container, container.id + ':wrapper', {
        name: $container.data('modifier') + 'running_' + (node.detachedFromAgent ? 'detached_' : '') + (successful ? 'green' : 'red')
      });
    }
  },

  updateDescription: function(node, buildId) {
    var txtNode = $('build:' + buildId + ":text");

    if (txtNode) {
      var textContent = node.statusText;
      textContent = textContent.escapeHTML();
      if (!txtNode.dataset.oneline) {
        textContent = textContent.replace(/[\.,\\\/:;@%^]/g, '$&<wbr>');
      }
      if (!txtNode.dataset.oneline && textContent.length > 100) {
        textContent = textContent.substring(0, 100) + "&hellip;";
      }
      txtNode.innerHTML = textContent;
    }
  },

  updateDuration: function(node, buildId) {
    var runningInfo = node['running-info'];
    if (!runningInfo) return;

    var elapsedTime = BS.RunningBuilds.formatDuration(runningInfo.elapsedSeconds);
    var durationNode = $('build:' + buildId + ":duration");

    if (durationNode) {
      durationNode.innerHTML = elapsedTime;
    }
  },

  updateProgress: function(node, buildId) {
    var runningInfo = node['running-info'];
    if (!runningInfo) return;

    var elapsedTime = runningInfo.elapsedSeconds;
    var totalEstimate = runningInfo.estimatedTotalSeconds;
    var remainingTime = runningInfo.leftSeconds;
    var overtimeSeconds;

    var showOvertimedIcon = false;
    var showOvertimedOnBar = false;
    var showTimeLeft = false;

    if (totalEstimate && remainingTime) {
      overtimeSeconds = elapsedTime - totalEstimate;
      if (overtimeSeconds < 0) {
        overtimeSeconds = 0;
      }
      showOvertimedIcon = overtimeSeconds > 60 && overtimeSeconds > elapsedTime * 0.01;
      showOvertimedOnBar = showOvertimedIcon && remainingTime < elapsedTime * 0.1;
      showTimeLeft = remainingTime > 60 || !showOvertimedOnBar;
    }

    this.doUpdateProgress(
      buildId,
      true,
      BS.RunningBuilds.formatDuration(elapsedTime),
      totalEstimate ? BS.RunningBuilds.formatDuration(totalEstimate) : "N/A",
      remainingTime ? BS.RunningBuilds.formatDuration(remainingTime) : "N/A",
      overtimeSeconds ? BS.RunningBuilds.formatDuration(overtimeSeconds) : "N/A",
      showOvertimedIcon,
      showOvertimedOnBar,
      showTimeLeft,
      this.isSuccessful(node),
      runningInfo.percentageComplete
    );
  },

  doUpdateProgress: function(buildId, updateNestedDiv, elapsedTime, totalEstimate, remainingTime, exceededDurationTime, showOvertimedIcon, showOvertimedOnBar, showTimeLeft, successful, completedPercent) {
    var holderNode = $('build:' + buildId);

    if (holderNode == null) return;

    var progressNode = holderNode.select(".progress")[0];
    var dateNode = holderNode.select(".start_date")[0];

    if (progressNode && dateNode) {

      var title = "Started: " + dateNode.innerHTML + "<br>" + elapsedTime + " passed";

      if (totalEstimate != 'N/A') {
        title += " of " + totalEstimate + " initially estimated";
      }

      var nestedDiv = this.findNestedDiv(progressNode);

      if (nestedDiv) {
        if ('N/A' == remainingTime) {
          if (updateNestedDiv) {
            nestedDiv.style.width = "100%";
          }
        }
        else {
          if (showOvertimedIcon) {
            BS.Util.show($('build:' + buildId + ':overtime_icon'));
          } else {
            BS.Util.hide($('build:' + buildId + ':overtime_icon'));
          }

          if (showTimeLeft) {
            title += "<br>" + (showOvertimedIcon ? "more than " : "") + remainingTime + " left";
          }

          if (showOvertimedIcon) {
            title += "<br>" + exceededDurationTime + " overtime";
          }

          if (updateNestedDiv) {
            if (showOvertimedOnBar) {
              nestedDiv = this.setTextInProgress(progressNode, "overtime: " + exceededDurationTime);
            } else {
              nestedDiv = this.setTextInProgress(progressNode, remainingTime + " left");
            }

            nestedDiv.removeClassName('progressInnerSuccessful');
            nestedDiv.removeClassName('progressInnerFailed');
            nestedDiv.addClassName(successful ? 'progressInnerSuccessful' : 'progressInnerFailed');
            nestedDiv.style.width = completedPercent + "%";
          }
        }
      }

      var agentLink = $('aLink:' + buildId);
      if (agentLink && agentLink.innerHTML != '') {
        title += "<br>Agent: " + agentLink.innerHTML;
      }

      var progressId = progressNode.id;
      progressNode._title = title;
      if (!progressNode._eventsBound) {
        holderNode.on("mouseenter", function() {
          BS.Tooltip.showMessage($(progressId), {shift:{x:10,y:20}}, $(progressId)._title);
        });
        holderNode.on("mouseleave", function() {
          BS.Tooltip.hidePopup();
        });
        progressNode._eventsBound = true;
      }
    }
  },

  setTextInProgress: function(progressNode, text) {
    var t = "&nbsp;&nbsp;" + text.replace(/ /g, "&nbsp;");
    progressNode.innerHTML = t + "<div class='progressInner'>" + t + "</div>";

    return this.findNestedDiv(progressNode); // refresh after HTML change
  },

  updateArtifactsLink: function(node, buildId) {
    var hasArtifacts = node.artifacts && node.artifacts.count && node.artifacts.count  > 0;
    if (hasArtifacts) {
      var artifactsLink = $('build:' + buildId + ':artifactsLink');
      var noArtifactsText = $('build:' + buildId + ':noArtifactsText');
      if (artifactsLink && noArtifactsText) {
        artifactsLink.style.display = 'inline';
        noArtifactsText.style.display = 'none';
      }
    }
  },

  formatDuration: function(durationInSeconds) {
    if (durationInSeconds === 0) {
      return '< 1s';
    }

    if (durationInSeconds < 60) {
      return durationInSeconds + 's';
    }

    var minutes;
    if (durationInSeconds < 3600) {
      minutes = Math.floor(durationInSeconds / 60);
      var seconds = durationInSeconds % 60;
      return minutes + 'm:' + (seconds > 9 ? seconds : '0' + seconds) + 's';
    }

    var hours = Math.floor(durationInSeconds / 3600);
    minutes = Math.floor((durationInSeconds % 3600) / 60);
    return hours + 'h:' + (minutes > 9 ? minutes : '0' + minutes) + 'm';
  }
};


