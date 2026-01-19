
var _user_agent = navigator.userAgent.toLowerCase();

var HANDLERS_DELAY = 500;

BS.BuildChains = {
  _chainRefreshTid: null,
  _scrollPos: null,
  _allChainsRefreshTid: null,

  scheduleAllChainsRefresh: function(delay) {
    if (this._allChainsRefreshTid) {
      window.clearTimeout(this._allChainsRefreshTid);
    }

    this._allChainsRefreshTid = window.setTimeout(function() {
      BS.reload(false, function() {
        var activeGraphId = $j('div.layeredGraph').attr('id');
        if (activeGraphId != null && BS.BuildChains._refreshBlocked(activeGraphId.replace(/graph_/, ''))) {
          BS.BuildChains.scheduleAllChainsRefresh(delay); // reschedule
          return;
        }

        var div = $j('#allChains')[0];
        if (div) {
          var expandedChainId = $j('.buildChainBlock .blockHeader.expanded').nextAll('.buildChainGraph').data('chain-id');
          if (!expandedChainId) expandedChainId = "";
          BS.BuildChains.stopListening();
          div.refresh(null, "&currentlyExpandedId=" + expandedChainId);
        } else {
          BS.reload(true);
        }
      });
    }, delay);
  },

  scheduleChainRefresh: function (chainId) {
    if (this._chainRefreshTid != null) {
      window.clearTimeout(this._chainRefreshTid);
    }

    this._chainRefreshTid = window.setTimeout(function () {
      if (BS.BuildChains._refreshBlocked(chainId)) {
        BS.BuildChains.scheduleChainRefresh(chainId);
        return;
      }

      var elem = $j('#chainRefresh_' + chainId)[0];
      var collapsed = $j('#chainRefresh_' + chainId + ' .blockHeader').hasClass('collapsed');
      if (elem && elem.refresh) {
        BS.BuildChains.stopListening();
        elem.refresh("", "&collapsed=" + collapsed, BS.BuildChains._afterUpdateFunction(elem, chainId));
      }
    }, 300);
  },

  refreshChain: function (chainId, updateScrollPosition) {
    var elem = $j('#chainRefresh_' + chainId)[0];
    var collapsed = $j('#chainRefresh_' + chainId + ' .blockHeader').hasClass('collapsed');
    if (elem && elem.refresh) {
      elem.refresh("", "&collapsed=" + collapsed, function() {
        BS.BuildChains._afterUpdateFunction(elem, chainId);
        if (!updateScrollPosition) return;

        $j(window).scrollLeft(0);
      });
    }
  },

  _refreshBlocked: function (chainId) {
    var graphObjId = 'graph_' + chainId;
    return !BS.canReload() ||
           ($(graphObjId) && $(graphObjId).graphObject && $(graphObjId).graphObject.hasSelectedNodes()) ||
           $j('#' + graphObjId + " .nodeInfo.highlight")[0]; // disable refresh if some nodes are selected or highlighted
  },

  _afterUpdateFunction: function (elem, id) {
    return function () {
      if ($j(elem).is(':empty')) {
        // this can happen on queued build dependencies tab:
        // when build starts, queued build controller stops calling extensions and we get empty content here
        if (document.location.href.indexOf('viewQueued') != -1) {
          BS.reload(true);
        } else {
          BS.BuildChains.scheduleAllChainsRefresh(0);
        }

        return;
      }

      BS.Log.info("Refreshed: " + id);
    }
  },

  toggleChainBlock: function (eventTarget, blockId) {
    var blockSel = '#' + blockId;
    var collapsed = $j(eventTarget).hasClass('collapsed');

    $j('.buildChainBlock .expanded').each(function () {
      BS.BuildChains._hideChain($j(this).nextAll('.buildChainGraph')[0]);
    });

    if (collapsed) {
      BS.BuildChains._showChain($j(blockSel)[0]);
    } else {
      BS.BuildChains._hideChain($j(blockSel)[0]);
    }
  },

  _showChain: function (container) {
    if (!container) return;

    $j(container).prevAll('.blockHeader').addClass('expanded');
    $j(container).prevAll('.blockHeader').removeClass('collapsed');

    $j(container).show();
    if ($j(container).is(':empty')) {
      $j(container).html('<span><i class="icon-refresh icon-spin ring-loader-inline progressRing progressRingDefault" style="float:none"></i> Loading...</span>');
    }

    var url = $j(container).data('url');
    BS.ajaxUpdater(container, url, {method: 'get', evalScripts: true});

    BS.LocationHash.setHashParameter('expand', container.id);
  },

  _hideChain: function (container, restoreWidth) {
    if (!container) return;

    $j(container).prevAll('.blockHeader').addClass('collapsed');
    $j(container).prevAll('.blockHeader').removeClass('expanded');

    $j(container).hide();

    // need to cleanup tabs, otherwise we can get clash by ids when next chain is expanded
    $j(container).find('.chainChanges').html('');
    $j(container).find('.chainProblems').html('');

    BS.stopObservingInContainers(container);

    BS.LocationHash.setHashParameter('expand', '');

    // reset scroller hack
    $j(window).scrollLeft(0);
    $j('body').css({'margin-left': 0, 'margin-right': 0});
    BS.LocationHash.setHashParameter('hpos', null);
    BS.LocationHash.setHashParameter('vpos', null);
  },

  ungroupProject: function(chainId, projectId, currentlyUngrouped) {
    var val = currentlyUngrouped;
    if (val == null) val = "";
    if (val.length > 0) val += ",";
    val += projectId;

    BS.User.setProperty("buildChains.ungroupedProjectIds", val, {
      afterComplete: function() {
        BS.BuildChains.refreshChain(chainId, true);
      }
    });
  },

  ungroupCompositeBuildType: function(chainId, buildTypeId, currentlyUngrouped) {
    var val = currentlyUngrouped;
    if (val == null) val = "";
    if (val.length > 0) val += ",";
    val += buildTypeId;

    BS.User.setProperty("buildChains.ungroupedCompositeBuildTypeIds", val, {
      afterComplete: function() {
        BS.BuildChains.refreshChain(chainId, true);
      }
    });
  },

  groupProject: function(chainId, projectId, currentlyUngrouped) {
    var val = currentlyUngrouped.split(",");
    var idx = val.indexOf(projectId);
    if (idx > -1) {
      val.splice(idx, 1);
    }

    BS.User.setProperty("buildChains.ungroupedProjectIds", val.join(","), {
      afterComplete: function() {
        BS.BuildChains.refreshChain(chainId, true);
      }
    });
  },

  groupCompositeBuildType: function(chainId, buildTypeId, currentlyUngrouped) {
    var val = currentlyUngrouped.split(",");
    var idx = val.indexOf(buildTypeId);
    if (idx > -1) {
      val.splice(idx, 1);
    }

    BS.User.setProperty("buildChains.ungroupedCompositeBuildTypeIds", val.join(","), {
      afterComplete: function() {
        BS.BuildChains.refreshChain(chainId, true);
      }
    });
  },

  checkContainersOverflow: function() {
    var sandbox = ReactUI.getSandbox();
    sandbox.measure(function() {
      return Array.from(document.querySelectorAll('.layeredGraphContainer'))
        .map(function(container) {
          return {
            container: container,
            hasOverflow: container.scrollWidth > window.innerWidth
          }
        });
    }).then(function(entries) {
      entries.forEach(function(entry) {
        entry.container.classList[entry.hasOverflow ? 'add' : 'remove']('layeredGraphContainer_pannable');
      })
    });
  },

  scrollHandler: _.debounce(function(e) {
    var hpos = document.documentElement.scrollLeft;
    var vpos = document.documentElement.scrollTop;

    BS.LocationHash.setHashParameter('hpos', hpos);
    BS.LocationHash.setHashParameter('vpos', vpos);
  }, HANDLERS_DELAY),

  resizeHandler: _.debounce(function(e) {
    document.documentElement.scrollLeft = 0;
    BS.BuildChains.checkContainersOverflow();
  }, HANDLERS_DELAY),

  blockScrollHandler: _.debounce(function(e) {
    var blockHpos = e.target.scrollLeft;

    BS.LocationHash.setHashParameter('blockHpos', blockHpos);
  }, HANDLERS_DELAY),

  mouseDownHandler: function(e) {
    var container = e.target.closest('.layeredGraphContainer');
    if (container == null || !container.classList.contains('layeredGraphContainer_pannable')) {
      return;
    }

    function getPointFromEvent(e) {
      return {x: e.clientX, y: e.clientY};
    }

    var origin = getPointFromEvent(e);
    var position = origin;
    var sandbox = ReactUI.getSandbox(container);
    var mutationScheduled = false;
    
    sandbox.mutate(function() {
      container.classList.add('layeredGraphContainer_panning');
    });

    function mouseMoveHandler(e) {
      e.preventDefault();
      position = getPointFromEvent(e);

      if (mutationScheduled) {
        return;
      }

      mutationScheduled = true;
      sandbox.mutate(function() {
        var dx = position.x - origin.x;
        // var dy = position.y - origin.y;
        if (Math.abs(dx) >= 1) {
          document.documentElement.scrollLeft -= dx;
        }
        // if (Math.abs(dy) >= 1) {
        //   document.documentElement.scrollTop -= dy;
        // }
        origin = position;
        mutationScheduled = false;
      })
    }

    function mouseUpHandler(e) {
      mouseMoveHandler(e);
      window.removeEventListener('mousemove', mouseMoveHandler);
      window.removeEventListener('mouseup', mouseUpHandler);
      sandbox.mutate(function() {
        container.classList.remove('layeredGraphContainer_panning');
      });
    }

    window.addEventListener('mousemove', mouseMoveHandler);
    window.addEventListener('mouseup', mouseUpHandler);
  },

  startListening: function() {
    window.addEventListener('mousedown', BS.BuildChains.mouseDownHandler);
    window.addEventListener('scroll', BS.BuildChains.scrollHandler);
    window.addEventListener('resize', BS.BuildChains.resizeHandler);
  },

  stopListening: function() {
    window.removeEventListener('mousedown', BS.BuildChains.mouseDownHandler);
    window.removeEventListener('scroll', BS.BuildChains.scrollHandler);
    window.removeEventListener('resize', BS.BuildChains.resizeHandler);
  }
};
