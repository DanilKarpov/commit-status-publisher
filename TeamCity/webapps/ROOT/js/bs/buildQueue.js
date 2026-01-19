if (!BS.Queue) {
  BS.Queue = OO.extend(BS.QueueLikeSorter, {
    containerId: 'buildQueueTable',

    getActionUrl: function() {
      return window['base_uri'] + "/queue.html";
    },

    getActionParameters: function(node, selector) {
      return "queueOrder=" + this.computeOrder(node, "queue_", selector);
    },

    afterOrderSaving: function() {
      var container = $('buildQueueContainer');
      container.refresh();
    },

    scheduleUpdate: function (node, selector, callback) {
      this.updateMoveTopIcons();
      if (this._timoutHandle) {
        clearTimeout(this._timoutHandle);
      }

      var handler = function () {
        this.saveOrder(node, selector);
        callback && callback();
      }.bind(this);

      this._timoutHandle = setTimeout(handler, 1000);
    }

  });
}

BS.Queue = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, _.extend(BS.Queue, {
  getContainer: function() {
    return $('removeFromQueueDialog');
  },

  formElement: function() {
    return $('removeFromQueue');
  },

  // assumes the builds are already cancelled/removed and removes queued builds from the table
  // refreshes container if number of removed builds is large or "Show more" button is shown
  removeQueuedBuilds: function(itemIds, oncomplete) {
    var finalOncomplete = function() {
      if (oncomplete) {
        oncomplete();
      }
      BS.unblockRefresh('itemCheckboxSelected');
    };

    if (itemIds.length > 20 || $j('#showMoreQueuedBuilds').length) {
      this.refreshQueuedBuilds(finalOncomplete);
      return;
    }

    this.hideActionsToolbar();

    for (var i=0; i<itemIds.length; i++) {
      this.removeQueuedBuild(itemIds[i]);
    }

    finalOncomplete();
  },

  refreshQueuedBuilds: function(oncomplete) {
    this.hideActionsToolbar();

    if ($j('#buildQueueContainer')[0]) {
      $j('#buildQueueContainer')[0].refresh(null, "", oncomplete);
    }
  },

  removeQueuedBuild: function(itemId) {
    var rowId = "queue_" + itemId;
    if (!$(rowId)) return;

    var parent = $(rowId).parentNode;
    parent.removeChild($(rowId));

    // remove table if it is empty
    var rows = $j('#buildQueueTable tbody tr');
    if (rows.length==0){
      $j('#buildQueueTable').remove();
      var notes = $j('#notes');
      if (notes!=undefined) {
        notes.html('<p>Build queue is empty.</p>');
      }
      return;
    }

    this.updateMoveTopIcons();
    this.refreshEstimates();
  },

  initActionsToolbar: function() {
    BS.AdminActions.showOrHideActions('#buildQueueTable input', '#queue-actions-docked');
  },

  hideActionsToolbar: function() {
    $j('#queue-actions-docked').hide();
  },

  refreshEstimates: function() {
    BS.Queue.requestNewQueueEstimates();
  },

  updateQueueEstimatesFromData: function() {
    for(var key in BS.QueueEstimates._estimates) {
      var estimate = BS.QueueEstimates.getEstimate(key);
      var element = $('estimate' + key + ":text");
      if (element) {
        element.innerHTML = estimate != null ? estimate.getEstimate() : 'N/A';
      }
    }
  },

  requestNewQueueEstimates: function() {
    var deferred = $j.Deferred();
    BS.ajaxRequest("queue.html?estimatesRequest=1", {
      onSuccess: function(transport, object) {
        transport.responseText.evalScripts();
        BS.Queue.updateQueueEstimatesFromData();
        deferred.resolve();
      },
      onFailure: function() {
        deferred.reject();
      },
      method: "get"
    });
    return deferred;
  },

  initEstimatesAutoupdate: function() {
    BS.periodicalExecutor(
      BS.Queue.requestNewQueueEstimates,
      BS.internalProperty('teamcity.ui.buildQueueEstimates.pollInterval') * 1000
    ).start();
  },

  showBranchColumn: function() {
    if (this._branchShown) return;
    $j("#buildQueueTable th.branch").addClass("hasBranch").html("Branch");
    this._branchShown = true;
  },

  showTagsColumn: function() {
    if (this._tagsShown) return;
    $j("#buildQueueTable th.queuedBuildTags").addClass("hasTags").html("Tags");
    this._tagsShown = true;
  },

  initSorting: function() {
    $j('table.buildQueueTable tbody').sortable({
      items: 'tr.draggable',
      change: function () {
        BS.blockRefreshPermanently();
      },
      update: function (event, ui) {
        BS.Queue.scheduleUpdate(ui.item, ".draggable", BS.unblockRefresh);
      },
      start: function (event, ui) {
        var that = this;

        if (typeof this.td_widths === 'undefined') {
          this.td_widths = [];
          $j('table.buildQueueTable tr.metrix th').each(function (i) {
            that.td_widths[i] = $j(this).width() + 'px';
          });
        }

        ui.item.find('td').each(function (i) {
          $j(this).css('width', that.td_widths[i]);
        });
      }
    });
  },

  selectBuilds: function (selector) {
    $j(selector + ' input').trigger('click');
  },

  loadMore: function (additionalBuildsNum) {
    BS.Util.show($j('#showMoreQueuedBuildsProgress'));
    BS.ajaxRequest("queue.html", {
      parameters: "loadMoreBuilds=" + additionalBuildsNum,
      onSuccess: function() {
        BS.Queue.refreshQueuedBuilds();
      }
    });
  }
})));

BS.QueueFilter = {
  filter: function(agentPoolKey) {
    BS.QueueFilter._prepare();
    BS.QueueFilter._updateProperty(agentPoolKey, BS.QueueFilter._getValue($("queuePool")), {
      afterComplete: function() {
        BS.QueueFilter._refreshContainer();
      }
    });
    BS.Queue.hideActionsToolbar();
  },

  resetFilter: function(agentPoolKey) {
    $('queuePool').selectedIndex = 0;
    $j('#queuePool').ufd("changeOptions");
    BS.QueueFilter._prepare();
    BS.User.deleteProperty(agentPoolKey, {
      afterComplete: function () {
        BS.QueueFilter._refreshContainer();
      }
    });
  },

  _refreshContainer: function() {
    $("buildQueueContainer").refresh(null, '', function() {
      BS.Util.hide("queueFilterProgress");
      BS.Util.reenableInput($("queuePool"));
      if (BS.QueueFilter._getValue($("queuePool")) != 'ALL') {
        $j('#queueFilterBar .resetFilter').show();
      } else {
        $j('#queueFilterBar .resetFilter').hide();
      }
    });
  },

  _prepare: function() {
    BS.Util.show("queueFilterProgress");
    BS.Util.disableInputTemp($("queuePool"));
  },

  _getValue: function(selector) {
    return selector.options[selector.selectedIndex].value;
  },

  _updateProperty: function(key, value, options) {
    if (value == "ALL") {
      BS.User.deleteProperty(key, options);
    }
    else {
      BS.User.setProperty(key, value, options);
    }
  }
};

BS.QueueEstimates = {};
BS.QueueEstimates._estimates = {};
BS.QueueEstimates.getEstimate = function(queueItemId) {
  var est = this._estimates[queueItemId];
  if(est == null)
    return null;

  return OO.extend(est, {
    
    getEstimate: function() {
      if (this.secondsToStart === 'never' || !this.secondsToStart) {
        return '???';
      }
      if (this.secondsToStart <= 0 || this.isDelayed) {
        return 'Delayed';
      }

      var result = BS.Util.formatSeconds(this.secondsToStart);
      if (this.secondsToStart >= 60 && this.isDelayed || (this.secondsToStart > 0 && this.secondsToFinish == null)) {
        result = 'More than ' + result;
      }
      return result;
    },


    getDescription: function() {
      var title = '';
      if (this.secondsToStart == null) {
        if (!this.waitReason) {
          title = "Cannot estimate this build<br/>";
        }
      }
      else if (this.secondsToStart > 0) {
        var duration = this.durationAsString;
        if (duration == "???") {
          duration = "";
        }
        else {
          duration = " (" + duration + ")";
        }
        title = "Estimated start/finish: " + this.timeFrame + duration + "<br/>";

        if (this._agentLink != '') {
          title += "Planned agent: " + this._agentLink + "<br/>";
        }
      }
      else if (this.secondsToStart == 0 && !this.waitReason) {
        title = "The build should start shortly.<br/>";
      }

      if(this.isDelayed) {
        var buildLink = this._buildLink;
        var agentLink = this._agentLink;
        if(buildLink != '' && agentLink != '') {
          title += "Delayed by "+ buildLink + " on "+ agentLink + "<br/>";
        }
        title += "Expected build duration: " + this.durationAsString +"<br/>";
      }

      if (this.waitReason) {
        title += '<em>' + this.waitReason + '</em>';
      }
      return title;
    }
  });
};

$j(document).ready(function() {
  var mouseOverHandler = function(e) {
    var itemId = this.getAttribute('data-itemId');
    var estimate = BS.QueueEstimates.getEstimate(itemId);
    var description = estimate != null ? estimate.getDescription() : 'N/A';
    BS.Tooltip.showMessageAtCursor(e, {shift:{x:2, y:2}}, description);
  };

  var mouseOutHandler = function() {
    BS.Tooltip.hidePopup();
  };

  var selectBuildHandler = function() {
    var selectedBuilds = BS.Util.getSelectedValues('buildQueueForm', 'removeItem');

    if (selectedBuilds.length > 0) {
      BS.blockRefreshPermanently('itemCheckboxSelected');
    } else {
      BS.unblockRefresh('itemCheckboxSelected');
    }
  };

  // TW-19878
  var fixDragHandler = function() {
    var draggedRow = $j(this).closest('.queueRowDragged');

    if (draggedRow.length > 0) {
      draggedRow.removeClass('queueRowDragged');
      return false;
    }

    return true;
  };

  var remainingSelector = '#buildQueueContainer td.remaining span.remaining, #queuedBuildsPopup td.remaining span.remaining, table.modificationBuilds td.remaining span.remaining';
  var removeItemSelector = '#buildQueueContainer #removeItem, #buildQueueContainer #removeAll, #queuedBuildsPopup #removeItem, table.modificationBuilds #removeItem';
  var buildQueueLinks = '#buildQueueContainer #queueTableRows a, #queuedBuildsPopup #queueTableRows a';

  $j(document)
      .on('mouseover', remainingSelector, mouseOverHandler)
      .on('mouseout', remainingSelector, mouseOutHandler)
      .on('click', removeItemSelector, selectBuildHandler)
      .on('click', buildQueueLinks, fixDragHandler);
});
