
BS.TestDetails = {
  toggleDetails: function(element, urlToLoad) {
    var parentTr = $(element).up("tr");
    var tdCount = parentTr.select("> td").size();

    var detailsTrId = this._detailsTrId(parentTr);
    if ($(detailsTrId)) {
      // Process case when details block is already available:
      if (!this.hideDetailsRow(parentTr)) {
        // Show available block
        $(detailsTrId).show();
        this.updateTestRow(parentTr, true);
      }
      return;
    }

    this.updateTestRow(parentTr, true);
    var content = this.getProgressBarHTML();
    var detailsTr = new Template("<tr id='#{rowId}' class='testDetailsRow'><td colspan='#{colspan}' class='data'>#{content}</td></tr>").evaluate(
        {
          colspan: tdCount,
          rowId: detailsTrId,
          content: content
        }
    );

    parentTr.insert({after: detailsTr});
    BS.ajaxUpdater($(detailsTrId).down("td.data"), window['base_uri'] + urlToLoad, {
      evalScripts: true
    });
  },

  getProgressBarHTML: function () {
    return '<div class="testLoading">' + BS.loadingIcon + ' Loading test details, please wait...' + '</div>'
  },

  _detailsTrId: function(parentTr) {
    return "testDetails_" + $(parentTr).identify();
  },

  hideDetailsRow: function(parentTr) {
    var detailsTrId = this._detailsTrId(parentTr);

    if (BS.Util.visible(detailsTrId)) {
      $(detailsTrId).hide();
      this.updateTestRow(parentTr, false);
      return true;
    }
    return false;
  },

  updateTestRow: function(tr, detailsOn) {
    tr = $(tr);
    if (detailsOn) {
      BS.Log.debug("expanding stacktrace " + tr.id);
      tr.addClassName("testDetailsShown");

      // Add a listener which runs while stacktrace is expanded
      // When stacktrace becomes non-visible on the page, it is collapsed to enable page refresh, (for BS.canReload() function)
      tr.store('on_hide_listener', setInterval(function() {
        var detailsTrId = this._detailsTrId(tr);
        if ($j(BS.Util.escapeId(detailsTrId) + ":hidden").length > 0) {
          this.hideDetailsRow(tr);
          this.updateTestRow(tr, false);
        }
      }.bind(this), 200));

      BS.BuildResults.stacktraceShown();
    } else {
      var listener = tr.retrieve('on_hide_listener');
      if (listener) {
        BS.Log.debug("collapsing stacktrace " + tr.id);

        tr.removeClassName("testDetailsShown");
        BS.BuildResults.stacktraceHidden();

        clearInterval(listener);
        tr.store('on_hide_listener', null);
      }
    }
  },

  closeDetails: function(element) {
    var detailsTr = $(element).up("tr");
    detailsTr.hide();
    var testRow = $(detailsTr.previousSibling);
    this.updateTestRow(testRow, false);
    BS.Highlight(testRow.down("td"), {duration: 2});
  },

  loadTestInformationForBuild: function (buildId, testId, projectId, testNameId, divContainer) {

    var that = this;

    divContainer.innerHTML = this.getProgressBarHTML();

    var url = "change/testDetails.html?buildId=" + buildId + "&testId=" + testId + "&projectId=" + projectId + "&testNameId=" + testNameId;
    BS.ajaxUpdater(divContainer, url, {
      evalScripts: true,
      onComplete: function () {
        that.bindFFIBlockListeners(divContainer);
      }
    });

  },

  loadFFIInformationForBuild: function (buildId, testId, ffiTable) {
    var that = this;
    var divTestInfoHolder = ffiTable.up('.testBlockGeneral');
    BS.ajaxUpdater(ffiTable, "firstFailedInfo.html?buildId=" + buildId + "&testId=" + testId, {
      evalScripts: true,
      onComplete: function () {
        that.bindFFIBlockListeners(divTestInfoHolder);
      }
    });
  },

  bindFFIBlockListeners: function (divTestInfoHolder) {
    var that = this;
    divTestInfoHolder.select("tr").each(function (tr) {
      if (tr.getAttribute('data-testId')) {

        tr.addClassName("clickable");
        tr.title = "Click to see stacktrace from this build";

        tr.on("click", "td", function () {
          that.changeCurrentRow(divTestInfoHolder, tr);
        });
      }
    });
  },

  changeCurrentRow: function(divContainer, tr_selected) {
    var buildId = tr_selected.getAttribute('data-buildId');
    var testId = tr_selected.getAttribute('data-testId');
    var traceBlock = divContainer.down('.fullStacktrace');
    traceBlock.style.height = traceBlock.getDimensions().height + 'px';
    traceBlock.update();

    this.changeCurrentRowStyle(divContainer, tr_selected);
    this.changeTextForNumberOfRuns(tr_selected);

    BS.BuildResults.expandStacktrace(traceBlock, buildId, testId, function() {
      traceBlock.style.height = 'auto';
    });

    var metaBlock = divContainer.down('.testMetadata');
    var testNameId = tr_selected.getAttribute('data-testNameId');
    var buildTypeId = tr_selected.getAttribute('data-buildTypeId');

    BS.TestMetadata.renderMetadata(metaBlock, buildTypeId, buildId, testId, testNameId);
  },

  changeCurrentRowStyle: function(table, tr_selected) {
    table.select('tr').each(function(tr) {
      tr.removeClassName('selectedBuild');
    });
    tr_selected.addClassName('selectedBuild');
    var radioselector = tr_selected.down('td.selector input');
    if (radioselector) {
      //don't init new click event
      radioselector.checked = true;
    }
  },

  changeTextForNumberOfRuns: function(tr_selected) {
    var invocationCount = tr_selected.getAttribute('data-invocationCount');
    var failedInvocationCount = tr_selected.getAttribute('data-failedInvocationCount');

    var node = tr_selected.up(".testBlock").down(".testRunsNote");
    // The test was run 100 times in the build, 29 failures

    var text = "";
    if (invocationCount > 1) {
      text += "The test was run <b>" + invocationCount + "</b> times in the build";
      if (failedInvocationCount > 0) {
        text += ", <b>" + failedInvocationCount + "</b> failures";
      }
    }
    if (invocationCount != 0) {
      node.update(text);
    }
  },

  toggleBuildDetails: function(element, event) {
    if (event) {
      element = Event.element(event);
      if (element.tagName == 'A') return;
    }

    $(element).up('.testBlock').select('.rightBlock').invoke('toggle');
  },

  // We don't want this function to run on each AJAX refresh call, and we don't want to expand stacktrace
  // on each refresh for a running build.
  expandTestInfoOnce:  _.once(function () {
    var expandParentGroupDeep = function(element) {
      var parent_group = element.closest(".testList,.subgroups");
      if (!parent_group) return;

      var parent_group_header = parent_group.previous("div.group-name");
      if (parent_group_header && parent_group_header._simple_block) {
        if (!parent_group_header._simple_block.isExpanded()) {
          parent_group_header._simple_block.changeState('', true, true);
        }
        expandParentGroupDeep(parent_group_header.parentNode);
      }
    };

    var index = document.location.href.indexOf('#testNameId');
    if (index > 0) {
      var id = document.location.href.substring(index + 11);

      var elementId = 'testNameId' + id;
      var element = $(document.querySelector("#failedTestsDl #" + elementId)); // First look under failed tests of this build
      if (!element) {
        element = $(elementId);
        BS.Log.info("Did not find stacktrace for testNameId " + elementId + " in this build's failed tests, looking in dependencies");
      }

      if (element) {

        expandParentGroupDeep(element);

        // Expand parent block with header if needed
        var block = element.up('.collapsibleBlock');
        var collapsedHeader = block ? block.previous('.blockHeader.collapsed') : null;
        if (collapsedHeader) {
          $j(collapsedHeader).click();
        }

        $j(element.down('a.testWithDetails')).click();
        BS.Log.info("Stacktrace for testNameId " + elementId + " is expanded");
        element.scrollIntoView();
      }
      else {
        var attentionComment = $j("div.attentionComment").get(0);
        if (attentionComment) {
          var fullLink = document.location.href.replace("maxFailed", "maxFailedOld");
          fullLink = fullLink.replace("#testNameId", "&maxFailed=-1#testNameId");
          attentionComment.update("Cannot find the test failure, <a href='" + fullLink + "'>try loading this page</a> with all failed tests shown");
        }
      }


    }
  })
};


/**
 * @typedef {Object} RenderingContext
 * @property {number} buildId
 * @property {number} testRunId
 * @property {String} testNameId
 * @property {string} buildTypeId
 * @property {Object} metadata
 * @property {Object} metadata_types
 */

/**
 * @typedef {Object} MetadataRenderer
 * @property {Function} canRender (name, metadataMap)
 * @property {Function} renderName (name, RenderingContext) - returns a safe String with metadata name
 * @property {Function} renderValue (name, RenderingContext) - returns a Promise with the rendered result, String
 */

BS.TestMetadata = {

  /**
   * @type Array<MetadataRenderer>
   */
  _renderers: [],

  _metadataPromisesCache: {},

  /**
   * @param {MetadataRenderer} renderer
   */
  addRenderer: function(renderer) {
    this._renderers.unshift(renderer);
  },

  renderMetadata: function(containerId, buildTypeExtId, buildId, testRunId, testNameId) {

    if (containerId.id) {
      containerId = containerId.id; // Case when an element is passed instead of ID
    }

    var that = this;
    this.loadMetadata(buildId, testRunId).then(function (metadataInfo) {

      var metadataMap = metadataInfo.meta_values;
      var metadataTypes = metadataInfo.meta_types;

      var sortedKeys = Object.keys(metadataMap).sort();
      if (!sortedKeys.length) {
        return;
      }

      BS.Log.debug("Render test metadata", containerId, buildTypeExtId, buildId, testRunId, metadataMap);

      var renderingContext = {
        buildId: buildId,
        testRunId: testRunId,
        testNameId: testNameId,
        buildTypeId: buildTypeExtId,
        metadata: metadataMap,
        metadata_types: metadataTypes
      };

      var name2renderer = that._fillRenderers(metadataMap, renderingContext);

      BS.Util.runWithElement(containerId, function (isElementPresent) {
        if (isElementPresent) {
          var container = document.getElementById(containerId);

          container.innerHTML =
            "<table class='testMetadata__table'><caption class='testMetadata__title'>Test metadata</caption></table>";
          var targetContainer = container.querySelector(".testMetadata__table");

          var sequencePromise = Promise.resolve();
          sortedKeys.forEach(function (name) {
            sequencePromise = sequencePromise.then(function() {
              var renderer = name2renderer[name];

              return renderer.renderValue(name, renderingContext).then(function (metadataValue) {
                var line = "<tr class='testMetadata__row'>" +
                  "<td class='testMetadata__name'>" + renderer.renderName(name, renderingContext) + "</td>" +
                  "<td class='testMetadata__value'>" + metadataValue + "</td>" +
                  "</tr>";

                $j(targetContainer).append(line);
              });

            })
          });

          // Make title more interesting - append number of metadata items
          // Doing this only for the really shown records
          sequencePromise.then(function() {
            container.querySelector('.testMetadata__title').innerHTML += " (" + container.querySelectorAll(".testMetadata__row").length + ")"
          })
        }
      });

    });
  },

  _fillRenderers: function(metadataMap, context) {
    var name2renderer = {};

    for(var name in metadataMap) {
      this._renderers.forEach(function(renderer) {
        if (!name2renderer[name] && metadataMap.hasOwnProperty(name) && renderer.canRender(name, context)) {
          name2renderer[name] = renderer;
        }
      });
    }
    return name2renderer;
  },

  /**
   * @return Promise which resolves into metadata object {meta_values: name2value, meta_types: name2type}, promise is cached
   */
  loadMetadata: function (buildId, testRunId) {
    var name = '' + buildId + "_" + testRunId;
    if (!this._metadataPromisesCache[name]) {
      this._metadataPromisesCache[name] = this._loadMetadata(buildId, testRunId);
    }
    return this._metadataPromisesCache[name];
  },

  /**
   * @return Promise which resolves into metadata map.
   * @private
   */
  _loadMetadata: function (buildId, testRunId) {
/*
    return Promise.resolve({
      "testKey": "test value",
      "a number": 333,
      "Screenshot": "teamcity.image:Screen Shot 2018-10-18 at 15.38.58.png",
      "Google": "teamcity.link: https://google.com",
      "Build Settings": "teamcity.artifact: .teamcity/settings/buildSettings.xml"
    });
*/

    var url = window['base_uri'] + "/app/rest/ui/testOccurrences/id:" + testRunId + ",build:(id:" + buildId + "),expandInvocations:true?fields=metadata";
    return new Promise(function(resolve, reject) {
      BS.ajaxRequest(url, {
        method: "GET",
        requestHeaders: {"Accept" : "application/json"},
        onSuccess: function (response) {
          var result = {};
          var types = {};
          var array = response.responseJSON.metadata.typedValues || [];
          array.forEach(function(entry) {
            result[entry.name] = entry.value;
            types[entry.name] = entry.type || 'text';
          });

          resolve({meta_values: result, meta_types: types});
        },
        onComplete: reject
      });
    });
    
  },

  /**
   * @param {RenderingContext} renderingContext
   * @param {String} name
   * @return {string} URL of the metadata value in build artifacts
   */
  artifact_url: function(renderingContext, name) {
    return window['base_uri'] + "/repository/download/" + renderingContext.buildTypeId + "/" + renderingContext.buildId + ":id/"
      + encodeURI(renderingContext.metadata[name] || "").replaceAll('#', '%23');
  },

  /**
   * @param {RenderingContext} renderingContext
   * @param {String} name
   * @return {string} Filename of the metadata value in build artifacts
   */
  artifact_file: function(renderingContext, name) {
    var path = BS.Util.escape(renderingContext.metadata[name]);
    var idx = path.lastIndexOf('/');
    return idx > 0 ? path.substring(idx + 1) : path;
  },

  /**
   * Safely render metadata name if it is not autogenerated, else return empty string
   * @param name
   * @return {String}
   */
  renderName: function(name) {
    return name && !name.startsWith('teamcity.auto.name:') ? BS.Util.escape(name) : '';
  },

  /**
   * @param {RenderingContext} renderingContext
   * @param {String} [name]
   * @return {string} Filename of the metadata value in build artifacts
   */
  renderNameWithPath: function(renderingContext, name) {
    var result = this.renderName(name);

    var filename = BS.Util.escape(renderingContext.metadata[name]);
    var idx = filename.lastIndexOf('/');
    filename = idx > 0 ? filename.substring(idx + 1) : filename;

    if (filename) {
      if (result.length > 0) {
        return result + " [" + filename + "]";
      }
      return filename;
    }
    return "";
  },

  showGraph: function(anchor, testNameId, buildId, metadataName, buildTypeId) {
    if (!this._popup) {
      this._popup = new BS.Popup(
        'testMetadataGraph', {
          delay: 0,
          hideDelay: -1,
          url: window.base_uri + '/buildGraph.html?jsp=buildLog/testMetadata.jsp',
          shift: {
            x: -150,
            y: 20
          },
          backgroundColor: 'white',
          loadingText: 'Loading chart...'
        });
    }
    else if (this._popup.isShown()) {
      this._popup.hidePopup();
      return;
    }

    metadataName = BS.Util.escape(metadataName);
    this._popup.showPopupNearElement(anchor, {
      parameters: 'testNameId=' + testNameId + '&buildId=' + buildId + '&metadataKey=' + encodeURIComponent(metadataName) + '&buildTypeId=' + buildTypeId
    });

  },


  installHandlerForTestLists: function(jContainer) {

    var hasMetadata = function(buildId, testId) {
      return BS.TestMetadata.loadMetadata(buildId, testId).then(function (value) {
        return Object.keys(value.meta_values).length > 0 ? Promise.resolve() : Promise.reject();
      });
    };

    var loadMetadataInfo = function(handle) {
      BS.AsyncRunner.runAsync(function(asyncContext) {

        var el = $j(handle);
        var testId = el.attr('data-testId');
        var buildId = el.attr('data-buildId');
        if (testId) {
          hasMetadata(buildId, testId).then(function () {
            handle.title =  "Click to view test metadata";
            handle.classList.add('metadataHandle--present');
            asyncContext.done()
          }, function () {
            asyncContext.done();
          });
        }
        else {
          asyncContext.done();
        }
      }, 1);
    };


    if ($j(jContainer) && $j(jContainer).length > 0) {
      var handles = $j(jContainer)[0].querySelectorAll(".metadataHandle");
      for(var i = 0; i < handles.length; i ++) {
        loadMetadataInfo(handles[i]);
      }
    }

    $j(jContainer).on('click', '.metadataHandle', function (e) {
      var el = $j(e.currentTarget);
      var testId = el.attr('data-testId');
      var testNameId = el.attr('data-testNameId');
      var buildId = el.attr('data-buildId');
      var buildTypeExtId = el.attr('data-buildTypeId');

      hasMetadata(buildId, testId).then(function () {

        var containerId = 'testMetadata_' + buildId + "_" + testId;

        var popup = new BS.Popup(
          containerId + "_popup", {
            delay: 0,
            hideDelay: -1,
            textProvider: function() {
              return "<div class='testMetadataPopup' id='" + containerId + "'></div>";
            },
            afterShowFunc: function() {
              BS.TestMetadata.renderMetadata(containerId, buildTypeExtId, buildId, testId, testNameId);
            },
            shift: {
              x: -5,
              y: 18
            },
            backgroundColor: 'white'
          });

        popup.showPopupNearElement(e.target);

      });

    })
  }

};




/**
 *  Generic renderer for any metadata, used as a last resort
 */
BS.TestMetadata.addRenderer({

  /**
   * @param {String} name
   * @param {RenderingContext} renderingContext
   * @return boolean
   */
  canRender: function(name, renderingContext) {
    return true;
  },

  /**
   * @param {String} name
   * @param {RenderingContext} renderingContext
   * @return {string} HTML
   */
  renderName: function(name, renderingContext) {
    return BS.TestMetadata.renderName(name);
  },

  /**
   * @param {String} name
   * @param {RenderingContext} renderingContext
   * @return {Promise<String>} HTML
   */
  renderValue: function(name, renderingContext) {
    var value = renderingContext.metadata[name];

    // See TestMetadata.NUMERIC_TYPES
    const isNumericType = (type) => ["number", "ms", "percent", "bytes"].indexOf(type) >= 0;

    var result;
    if (isNumericType(renderingContext.metadata_types[name])) {
      result = "<span class='testMetadataNumber'>" + value + "</span>";

      var escapedName = BS.Util.escape(name.replace(/('|&#39)/g, '"'));
      var call = "BS.TestMetadata.showGraph(this, '" + renderingContext.testNameId + "', " + renderingContext.buildId + ", '" + escapedName + "', '" + renderingContext.buildTypeId +"')";
      result += '<a href="#" onclick="' + call + ';return false;" title="View metric graph" ><i class="tc-icon icon16 tc-icon_graph"></i></a>';
    }
    else {
      result = BS.Util.escape(value);
    }

    return Promise.resolve(result);
  }
});


/**
 *  ARTIFACT Links renderer
 *
 *  Reporting:
 *    ##teamcity[testMetadata testName='foo.CodeTestNG.should_fail' name='my XML file' type='artifact' value='teamcity-info.xml']
 */
BS.TestMetadata.addRenderer({

  /**
   * @param {String} name
   * @param {RenderingContext} renderingContext
   * @return boolean
   */
  canRender: function(name, renderingContext) {
    return renderingContext.metadata_types[name] == 'artifact';
  },

  /**
   * @param {String} name
   * @param {RenderingContext} renderingContext
   * @return {string} HTML
   */
  renderName: function(name, renderingContext) {
    var artifactUrl = BS.TestMetadata.artifact_url(renderingContext, name);
    var text = BS.TestMetadata.renderNameWithPath(renderingContext, name);

    return "<a href='" + artifactUrl + "' target='_blank' rel='noreferrer'>" +  text + "</a>";
  },

  /**
   * @param {String} name
   * @param {RenderingContext} renderingContext
   * @return {Promise<String>} HTML
   */
  renderValue: function(name, renderingContext) {
    return Promise.resolve("");
  }
});

/**
 *  Simple link renderer
 *
 *  Reporting:
 *    ##teamcity[testMetadata testName='foo.Test.testName' name='Google' type='link' value='http://www.google.com']
 */
BS.TestMetadata.addRenderer({
  /**
   * @param {String} name
   * @param {RenderingContext} renderingContext
   * @return boolean
   */
  canRender: function(name, renderingContext) {
    return renderingContext.metadata_types[name] == 'link';
  },

  /**
   * @param {String} name
   * @param {RenderingContext} renderingContext
   * @return {string} HTML
   */
  renderName: function(name, renderingContext) {
    var path = BS.Util.escape(renderingContext.metadata[name]);
    if (!path.startsWith("http") && !path.startsWith("ftp")) {
      path = "https://" + path;
    }
    return "<a href='" + path + "' target='_blank' rel='noreferrer'>" +  BS.Util.escape(name) + "</a>";
  },

  /**
   * @param {String} name
   * @param {RenderingContext} renderingContext
   * @return {Promise<String>} HTML
   */
  renderValue: function(name, renderingContext) {
    return Promise.resolve("");
  }
});

/**
 *  ARTIFACT Images renderer
 *
 *  Reporting:
 *    ##teamcity[testMetadata testName='foo.Test.testName' type='image' value='Screen Shot 2018-10-18 at 15.38.58.png']
 */
BS.TestMetadata.addRenderer({
  /**
   * @param {String} name
   * @param {RenderingContext} renderingContext
   * @return boolean
   */
  canRender: function(name, renderingContext) {
    return renderingContext.metadata_types[name] == 'image';
  },


  /**
   * @param {String} name
   * @param {RenderingContext} renderingContext
   * @return {string} HTML
   */
  renderName: function(name, renderingContext) {
    return BS.TestMetadata.renderNameWithPath(renderingContext, name);
  },

  /**
   * @param {String} name
   * @param {RenderingContext} renderingContext
   * @return {Promise<String>} HTML
   */
  renderValue: function(name, renderingContext) {
    var imgUrl = BS.TestMetadata.artifact_url(renderingContext, name);

    var result = "<a href='" + imgUrl + "' target='_blank' rel='noreferrer'>" +
      "<img src='" + imgUrl + "' alt='' class='testMetadataImage'></a>";

    return Promise.resolve(result);
  }
});

/**
 *  ARTIFACT Videos renderer
 *
 *  Reporting:
 *    ##teamcity[testMetadata testName='foo.Test.testName' type='video' value='file.mp4']
 */
BS.TestMetadata.addRenderer({
  /**
   * @param {String} name
   * @param {RenderingContext} renderingContext
   * @return boolean
   */
  canRender: function(name, renderingContext) {
    return renderingContext.metadata_types[name] == 'video';
  },


  /**
   * @param {String} name
   * @param {RenderingContext} renderingContext
   * @return {string} HTML
   */
  renderName: function(name, renderingContext) {
    return BS.TestMetadata.renderNameWithPath(renderingContext, name);
  },

  /**
   * @param {String} name
   * @param {RenderingContext} renderingContext
   * @return {Promise<String>} HTML
   */
  renderValue: function(name, renderingContext) {
    var videoUrl = BS.TestMetadata.artifact_url(renderingContext, name);

    var result = "<a href='" + videoUrl + "' target='_blank' rel='noreferrer'>" +
                 "<video src='" + videoUrl + "' preload='metadata' controls class='testMetadataVideo'></a>";

    return Promise.resolve(result);
  }
});

