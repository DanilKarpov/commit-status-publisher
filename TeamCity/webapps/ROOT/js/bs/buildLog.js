(function($) {
  BS.BuildLog = {
    $doc: $(document),

    // Incremental update (tree view)
    startUpdates: function(buildId, buildTypeId, initialCounter, isTree, pageName, additionalAttrs) {
      this.counter = initialCounter;
      this.isTree = isTree;
      var that = this;
      BS.Log.debug('start updater');
      var updater = new BS.PeriodicalUpdater(null, that.getUrl(buildId, buildTypeId, this.counter, pageName, additionalAttrs + that.getState()), {
        frequency: 2,
        evalScripts: true,
        onSuccess: function(transport) {
          BS._reloadIfReceivedHTML(transport);
          /* Add the response HTML piece, scroll to bottom if necessary. */
          var $response = $(transport.responseText);
          var updateData = $response.filter('.buildLogUpdater')[0].onclick();
          var treeUpdateDataNodes = $response.filter('.logTreeUpdater');
          var scrollAtBottom = that.isScrollAtBottom();

          BS.Log.debug('append response');

          that.counter = that.isTree ? updateData.updateCounter : that.counter + updateData.updateCounter;
          $('#buildLog').append($response.not('.buildLogUpdater, .logTreeUpdater'));
          that.updateState(updateData.updateState);

          if (scrollAtBottom) {
            that.scrollToBottom();
          }

          /* Check if build has finished. */
          if (updateData.finish) {
            updater.stop();
            that.$doc.off('scroll.buildLog keydown.buildLog');
            $('#buildLogProgress').remove();
          } else {
            var container = $j('#buildLogProgress .js_buildStatusIcon').get(0);
            ReactUI.renderAnimatingIcon(container, container.id + ':wrapper', {
              name: 'running_' + updateData.loaderIcon
            });
          }

          /* Apply state changes to tree */
          if (treeUpdateDataNodes.length) {
            var treeUpdateData = treeUpdateDataNodes[0].onclick();
            Object.keys(treeUpdateData).forEach(function (func) {
              treeUpdateData[func].forEach(function (args) {
                args.push($response);
                BS.BuildLogTree[func].apply(BS.BuildLogTree, args);
              });
            });
          }

          $response = null;

          // Set a new counter now.
          updater.url = that.getUrl(buildId, buildTypeId, that.counter, pageName, additionalAttrs + that.getState());
        }
      });

      this.$doc.on('scroll.buildLog', function() {
        that.isScrollPositionKnown = false;
      });

      this.$doc.on('keydown.buildLog', function(e) {
        // Up/Down/Left/Right/Home/End/PageUp/PageDown
        if (e.keyCode >= 33 && e.keyCode <= 40) {
          that.isScrollPositionKnown = false;
        }
      });
    },

    getState: function() {
      if (this.isTree) {
        var state = BS.BuildLogTree.getState();
        return state ? '&state=' + state : '';
      } else return '';
    },

    isScrollPositionKnown: false,
    isScrollAtBottom: function() {
      if (!this.isScrollPositionKnown) {
        this._isScrollAtBottom = BS.ScrollUtil.isScrollAtBottom(20);
        this.isScrollPositionKnown = true;
      }

      return this._isScrollAtBottom;
    },

    scrollToBottom: BS.nextFrame(function() {
      BS.ScrollUtil.scrollToBottom();
    }),

    getUrl: function(buildId, buildTypeId, counter, pageName, additionalAttrs) {
      return window['base_uri'] + '/buildLog/' + pageName + '?' +
             'buildId=' + buildId +
             '&buildTypeId=' + buildTypeId +
             '&counter=' + counter +
             (additionalAttrs ? '&' + additionalAttrs : '');
    },

    initLineWrap: function() {
      var wrapToggle = $('#wrapLines');

      wrapToggle.change(function() {
        var wrapEnabled = !!this.checked;
        $('#buildResults').toggleClass('buildResultsWrap', wrapEnabled);

        if (wrapEnabled) {
          BS.Cookie.set('buildResultsWrap', '1', 365);
        } else {
          BS.Cookie.remove('buildResultsWrap');
        }
      });

      if (BS.Cookie.get('buildResultsWrap') == '1') {
        wrapToggle.click();
      }
    },

    // Full refresh (tail view)
    refreshRunning: false,
    enableRefresh: function() {
      var that = this;

      if (that.refreshRunning) {
        return;
      }
      that.refreshRunning = true;

      this.$doc.ready(function() {
        BS.PeriodicalRefresh.start(5, function() {
          var scrollAtBottom = that.isScrollAtBottom();
          return $('#buildResults').get(0).refresh(null, "runningBuildRefresh=1", function() {
            if (scrollAtBottom) {
              that.scrollToBottom();
            }
          });
        });
      });
    },

    // Updates build log size in the header
    updateState: function(buildLogSize) {
      BS.BuildResults.updateStateIcon();
      $("#buildLogSizeEstimate").text(buildLogSize);
    }
  };

  $(document).ready(function() {
    BS.BuildLog.initLineWrap();
  });
})(jQuery);
