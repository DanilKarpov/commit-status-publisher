BS.ChangePageData = {};

BS.ChangePageFilter = {
  _projects: {},
  _projectExternalId2InternalId: {},

  useFilter: true,
  projectId: '',
  projectExternalId: '',
  changesOwnerId: '',

  setProjectId: function(externalProjectId) {
    this.projectExternalId = externalProjectId;
    document.location.hash = "#" + externalProjectId;
  },

  fixProject: function() {
    this.projectId = this._projectExternalId2InternalId[this.projectExternalId];
    if (this.projectExternalId && !this.projectId) {
      this.projectId = '';
      this.setProjectId('');
      var that = this;
      setTimeout(function() {
        that.refresh();
      }, 10);
    }
  },

  refresh: function() {
    BS.Hider.hideAll();

    BS.AsyncRunner.cancelAll();

    BS.changeTree.dispose();
    BS.ChangePage.clearCurrentContent();

    BS.ChangePage.showFirstChanges();
  },

  urlParams: function() {
    return this._urlParams(this.projectExternalId) + "&changesOwnerId=" + this.changesOwnerId;
  },

  _urlParams: function(projectExternalId) {
    return (projectExternalId && projectExternalId.length > 0 ? "&projectId=" + projectExternalId : "");
  },

  /** project_data: id, externalId, name, usageCount */
  addProject: function(project_data) {
    if (!this._projects[project_data.id]) {
      this._projects[project_data.id] = project_data;
      this._projectExternalId2InternalId[project_data.externalId] = project_data.id;
      this._sorted_projects = null;
    }
  },

  resetProjects: function() {
    this._sorted_projects = null;
    this._projects = {};
  },

  updateFilterView: function() {

    var that = this;

    this.fixProject();

    if (!this._sorted_projects) {

      this._sorted_projects = $H(this._projects).values().sort(function(a,b) {
        return a.name.localeCompare(b.name);
      });

      if (this._sorted_projects.length > 1) {

        if (!this.projectSelect) {
          this.projectSelect = $j("<select id='projectSelect' tabindex='1'/>");
          $j("#projectsFilter").append("<label for='projectSelect'>Project:</label>");
          $j("#projectsFilter").append(this.projectSelect);

          this.projectSelect.change(function() {
            var selectedOption = $j(this).find("option:selected");
            var projectId = selectedOption.attr("data-project-id");
            var projectExternalId = selectedOption.attr("id").substr('prj_node_'.length);

            that.setProjectId(projectExternalId);
            that.setTitle(that._projects[projectId]);

            that.refresh();
          });
        }
        this.projectSelect.html("");

        this.addProjectOption(this.projectSelect, {id: '', externalId: '', name: "<All projects>", usageCount: 10000});
        for(var i = 0; i < this._sorted_projects.length; i ++) {
          this.addProjectOption(this.projectSelect, this._sorted_projects[i]);
        }

        BS.jQueryDropdown(this.projectSelect).ufd("changeOptions");
      }
      else {
        if (this.projectSelect) {
          this.projectSelect.remove();
          this.projectSelect = null;
        }
        $j("#projectsFilter").html("");
      }
    }
    this.updateHiddenConfigurationsMessage();
  },

  updateHiddenConfigurationsMessage: function() {
    $('filterBuildConfigurations').checked = this.useFilter;
  },

  addProjectOption: function(select, prj) {
    if (prj.name) {
      var selected = this.projectId == prj.id;
      select.append("<option id='prj_node_" + prj.externalId + "' data-project-id='" + prj.id + "'" + (selected ? " selected" : "") + ">" + prj.name.escapeHTML() + "</option>");

      if (selected) {
        this.setTitle(prj);
      }
    }
  },


  createFindUserFunction: function (elementId, baseUrl) {
    return function (request, responseCallback) {
      var term = request.term;

      var url = baseUrl + '/userAutocompletion.html?term=' + encodeURIComponent(term);
      $j.getJSON(url, function (data) {
        responseCallback(data);
      });
    }
  },


  setTitle: function(project_data) {
    if (project_data && project_data.id != '') {
      BS.Util.setTitle("Changes > " + project_data.name);
    }
    else {
      BS.Util.setTitle("Changes");
    }
  }

};

BS.ChangePage = {
  firstRecord: null,
  lastRecord: null,

  lastDay : null,
  haveMoreChanges : true,

  lastUpdatableRecord : null, // For full AJAX update operation

  showFirstChanges: function() {
    $("showMoreChanges").hide();
    var progress = new BS.ChangePage.Progress("Loading change list... ");

    this._runChangeListAjax(false, {
      method: 'get',
      parameters: "firstChanges=true&" + BS.ChangePageFilter.urlParams(),
      onComplete: function() {
        progress.stop();
      },

      onSuccess: function(response) {
        if (!response.request.getStatus()) return; // case of abort()

        $("updatableChangesContainer").update();
        this._showRows(response.responseText, false);
        this._updateMoreLink();
        this._updateNoChangesMessage();

        BS.ChangePageFilter.updateHiddenConfigurationsMessage();

        this.restoreTreeSelection();
      }.bind(this)
    });
  },

  _runChangeListAjax: function(isUpdate, options) {
    if (this.currentChangesRequest) {
      if (this.currentChangesRequest.firstLoad) {
        return;
      }

      this.currentChangesRequest.abort();
    }

    var origOnComplete = options.onComplete || Prototype.emptyFunction;
    var that = this;

    var started = new Date().getTime();
    options.onComplete = function() {
      origOnComplete.apply(null, arguments);
      that.currentChangesRequest = null;
      BS.Log.debug("End changes.html AJAX call: " + (new Date().getTime() - started) + " msecs");
    };

    BS.Log.debug("Start changes.html AJAX call");
    var req = BS.ajaxRequest('changes.html', options);

    this.currentChangesRequest = {
      firstLoad: !isUpdate,
      abort: function() {
        BS.Log.debug("ABORT changes.html AJAX call");
        try {
          req.transport.abort();
        }
        catch(e) {
          BS.Log.warn(e);
        }
        options.onComplete({});
      }
    }
  },

  restoreTreeSelection: function() {
    var sel = BS.Cookie.get("changesTreeSel");
    if ($(sel)) {
      BS.changeSel.setSelection(sel);
    }
    else {
      BS.changeSel.setSelection(BS.changeTree.getFirstNode());
    }
  },

  showMoreChanges: function() {
    if (this.noChangesLoaded()) {
      this.showFirstChanges();
    } else {
      if (this.loadingMore) return;

      this.loadingMore = true;
      $('showMoreChangesProgress').show();

      var lastRec = BS.ChangePage.lastRecord;

      this._runChangeListAjax(false, {
        method: 'get',
        parameters: "moreChanges=true" + this._appendModificationAndFilter(lastRec) + "&lastDay=" + BS.ChangePage.lastDay,
        onSuccess: function(response) {
          if (!response.request.getStatus()) return; // case of abort()

          this._showRows(response.responseText, true);
          new Effect.ScrollTo($('showMoreChangesProgress'));
          $('showMoreChangesProgress').hide();
          this._updateMoreLink();
          this._updateNoChangesMessage();
        }.bind(this),
        onComplete: function() {
          this.loadingMore = false;
        }.bind(this)
      });
    }
  },

  _appendModificationAndFilter: function(record) {
    return "&lastModificationId=" + record.modId +
           "&personal=" + record.personal +
           "&" + BS.ChangePageFilter.urlParams()
        ;
  },

  updateChanges: function() {
    if (this.noChangesLoaded()) {
      this.showFirstChanges();
    } else {

      // Process case of multiple updateChanges requests in parallel:
      if (this.updateInProgress) {
        clearTimeout(this._updateTimeout);

        this._updateTimeout = setTimeout(function() {
          BS.ChangePage.updateChanges();
        }, 5000);

        return;
      }


      this.updateInProgress = true;

      var params;
      if (BS.ChangePage.lastUpdatableRecord) {
        params = "updateChanges=true" + this._appendModificationAndFilter(BS.ChangePage.lastUpdatableRecord);
      } else {
        params = "updateChanges=true" + this._appendModificationAndFilter(BS.ChangePage.firstRecord) + "&exclusive=true";
      }

      this._runChangeListAjax(true, {
        method: 'get',
        parameters: params,
        onSuccess: function(response) {
          if (!response.request.getStatus()) return; // case of abort()

          var toInsert = document.createDocumentFragment();
          var oldRecordProcessed = false;
          BS.ChangePage.processChangeRows(response.responseText, function(newDiv, index) {
            var rowId = newDiv.id;
            var row = BS.ChangePageData[rowId];
            if (row) {
              BS.ChangePage.lastUpdatableRecord = row.lastRowRecord;
              var oldDiv = $(rowId);
              oldRecordProcessed = oldRecordProcessed || oldDiv;

              var newRow = !oldRecordProcessed; // New items can appear only at the beginning of the list, TW-45005,
                                                // but sometimes returned rows contain older duplicating modification at the end of the list
              if (newRow) {
                BS.Log.info("New change row: " + rowId);
                toInsert.appendChild(newDiv);

                // Remove existing content with same ID as inserted:
                BS.ChangePage.for_each_related_record(rowId.substr('jc_'.length), function(record) {

                  // Remove existing change node TR and details TR:
                  var ct_node_id = 'ct_node_' + record.modId + "_" + record.personal;
                  var existingToRemove = $(ct_node_id);
                  if (existingToRemove) {
                    BS.Log.info("Removing existing change row " + ct_node_id);
                    var detailsTr = $("details_" + ct_node_id);
                    BS.stopObservingInContainers([existingToRemove, detailsTr]);
                    existingToRemove.remove();
                    detailsTr.remove();
                  }

                  // Remove surrounding table as well, if needed
                  existingToRemove = $('jc_' + record.modId + "_" + record.personal);
                  if (existingToRemove) {
                    BS.Log.info("Removing existing joining table " + 'jc_' + record.modId + "_" + record.personal);

                    BS.stopObservingInContainers(existingToRemove);
                    existingToRemove.remove();
                  }
                });

              }
            }
          });

          // don't use insert() here! It evaluates Javascript, but we did this already:
          var container = $("updatableChangesContainer");
          container.insertBefore(toInsert, container.firstChild);

          BS.ChangePage.updateTreeAfterUpdate();
          BS.changeTree.updateTopNodesOrder();

          if (BS.changeTree.hasNonPersonalChanges()){
            $('noRegularChanges').hide();
          }
        },

        onComplete: function() {
          this.updateInProgress = false;
        }.bind(this)
      });
    }
  },

  showUsingFilter: function() {
    this._changeFilterState(true);
  },

  showAll: function() {
    this._changeFilterState(false);
  },

  _changeFilterState: function(useFilter) {
    BS.ChangePageFilter.useFilter = useFilter;
    BS.User.setBooleanProperty("myChanges_withoutFilter", !useFilter, {
      afterComplete: function() {
        BS.ChangePageFilter.refresh();
      }
    });
  },

  noChangesLoaded: function() {
    return !this.firstRecord;
  },

  _showRows: function(htmlData, appendData) {

    var updatable = document.createDocumentFragment();
    var more = document.createDocumentFragment();

    this.processChangeRows(htmlData, function(divElement) {
      var rowId = divElement.id;
      var row = BS.ChangePageData[rowId];
      if (row) {
        if (row.updatable) {
          updatable.appendChild(divElement);
          this.lastUpdatableRecord = row.lastRowRecord;
        } else {
          more.appendChild(divElement);
        }
      }
    });

    var updatableContainer = $("updatableChangesContainer");
    var moreContainer = $("moreChangesContainer");

    // don't use insert() here! It evaluates Javascript, but we did this already:
    if (!appendData) {
      this.clearCurrentContent();
    }
    updatableContainer.appendChild(updatable);
    moreContainer.appendChild(more);

    this.updateTreeAfterUpdate();
  },

  clearCurrentContent: function() {
    // First, dispose the tree, after that, clean content
    _.each(["updatableChangesContainer", "moreChangesContainer"], function(container) {
      container = $(container);
      BS.stopObservingInContainers(container);
      container.update();
      container.on('click', BS.changeSel.clickHandler.bindAsEventListener(BS.changeSel));
    });
  },

  processChangeRows: function(htmlData, rowProcessor) {
    var tempDiv = new Element("div");
    tempDiv.innerHTML = htmlData;
    var scripts = tempDiv.getElementsByTagName('script');
    window.tempDiv = tempDiv;
    Array.prototype.forEach.call(scripts, function(script) {
      // eslint-disable-next-line no-eval
      eval(script.textContent);
    });
    window.tempDiv = null;
    tempDiv.childElements().forEach(rowProcessor, this);
  },

  updateTreeAfterUpdate: function() {
    BS.changeTree.synchronizeViewAndModel();
    BS.changeTree.preloadBlocks();
  },

  _updateMoreLink: function() {
    if (this.haveMoreChanges) {
      $("showMoreChanges").show();
    } else {
      $("showMoreChanges").hide();
    }
  },

  _updateNoChangesMessage: function() {
    if (BS.changeTree.hasNonPersonalChanges()) {
      $('noRegularChanges').hide();
    }
    else {
      $('thisUserChanges').hide();
      $('anotherUserChanges').hide();
      $('noneChangesAvailable').hide();

      var viewOwnChanges = BS.ChangePageFilter.currentUserId == BS.ChangePageFilter.changesOwnerId || !BS.ChangePageFilter.changesOwnerId;
      if (BS.ChangePageFilter.currentUserId < 0 && viewOwnChanges) {
        $('noneChangesAvailable').show();
      }
      else if (viewOwnChanges) {
        $('thisUserChanges').show();
      }
      else {
        $('anotherUserChanges').show();
      }
      $('noRegularChanges').show();

      $j(".noRegularChanges__hasPersonal")[BS.changeTree.hasPersonalChanges() ? 'show' : 'hide']();
    }
  },

  carpetElement: function(record) {
    return $("carpet_" + record.modId + "_" + record.personal);
  },

  /** Run 'action' for each line in changes page which has same build set as 'record'
   * @param record_key key of the first change which joins all other changes with the same build set. Has form {modificationId}_{isPersonal}
   * @param action action to run, function will get record object as parameter, like {modId: 3, personal: false}
   * */
  for_each_related_record: function(record_key, action) {
    var data = BS.ChangePageData['jc_' + record_key];
    if (!data) return;
    var related_records = data.records_with_same_builds;
    for(var i = 0; i < related_records.length; i++) {
      action.call(this, related_records[i]);
    }
  },

  _f: null
};

BS.RefreshIntervalHolder = {
  REFRESH_INTERVAL: 15 * 1000
},

/*---------------------------------------------------------------------------------------*/
/*-------------------- Here comes support for tree of changes -------------------------*/
/*---------------------------------------------------------------------------------------*/
BS.ChangeNode = Class.create(BS.TreeNode, {
  initialize: function($super, id, id_record, first_record, expanded) {
    this.record = id_record;
    this.first_record = first_record;

    this.content_cache = null;
    this.updater = null;

    if (expanded) {
      BS.ChangeNode._expanded_single_node = BS.ChangeNode._expanded_single_node || id;
      expanded = BS.ChangeNode._expanded_single_node === id;
    }

    $super(id, expanded);
  },

  destroy: function($super) {
    if (this.getContainer()) {
      BS.stopObservingInContainers(this.getContainer());
    }

    this._stop_ajax_update_of_expanded_block();
    this.content_cache = null;
    $super();
  },

  getDetailsContainer: function() {
    return this.getContainer();
  },

  getContainer: function() {
    return $("expandedViewContainer_" + this.key());
  },

  _setProgressIcon: function(show_progress_icon) {
    if (!this.progress_delay) {
      this.progress_delay = new BS.DelayedAction(function() {
        this._setSpinner();
      }.bind(this), function() {
        this._setHandle(this.isExpanded(), "Collapse (arrow left key)");
      }.bind(this));
    }

    if (show_progress_icon) {
      this.progress_delay.start();
    }
    else {
      this.progress_delay.stop();
    }
  },

  onExpandChange: function() {
    if (this.isExpanded()) {
      this._collapseOldExpanded();
    }
    this.updateView();
  },

  _collapseOldExpanded: function() {
    var oldExpanded = this.tree && this.tree.getNode(BS.ChangeNode._expanded_single_node);
    BS.ChangeNode._expanded_single_node = this.getId();

    if (oldExpanded && oldExpanded !== this) {
      oldExpanded.setExpanded(false);
    }
  },

  updateView: function() {
    if (!this.tree) return;
    if (!$(this.getId())) {
      this.destroy();
      return;
    }

    this._updateIconAndDetailsBlock();
    this.updateFullComment();

    if (this.isExpanded()) {
      this.expandBlock();
    }
    else {
      this.collapseBlock();
    }
  },

  _updateIconAndDetailsBlock: function() {
    var block = this.getDetailsContainer();

    if (this.isExpanded()) {
      $(this.getId()).addClassName("expandedBlock");
      this._setHandle(true, "Collapse (arrow left key)");
    }
    else {
      $(this.getId()).removeClassName("expandedBlock");
      this._setHandle(false, "Expand (arrow right key)");

      if (block) {
        block.hide();
      }
    }
  },

  _setSpinner: function() {
    var icon = this.getHandle();
    if (icon) {
      icon.style.backgroundImage = 'none';
      icon.addClassName('icon-refresh');
      icon.addClassName('icon-spin');
      icon.addClassName('ring-loader-inline');
      icon.parentNode.title = 'Loading...';
    }
  },

  _setHandle: function(isExpanded, title) {
    var icon = this.getHandle();

    if (icon) {
      icon.removeClassName('icon-refresh');
      icon.removeClassName('icon-spin');
      icon.removeClassName('ring-loader-inline');
      icon.style.backgroundImage = null;
      icon.parentNode.title = title;

      if (isExpanded) {
        icon.addClassName("handle_expanded").removeClassName("handle_collapsed");
      } else {
        icon.removeClassName("handle_expanded").addClassName("handle_collapsed");
      }
    }
  },

  getHandle: function() {
    var node = $(this.getId());
    return node ? node.down(".handle") : null;
  },

  showDetailsTab: function(tabCode, noToggle) {
    var tabId = tabCode + "_" + this.key();
    if (this.getSelectedTabId() == tabId) {
      if (!noToggle) {
        this.toggle();
      }
    }
    else {
      this.setExpanded(true);
      this.selectTab(tabId);
    }
  },

  gotoNextTab: function(shift) {
    if (!this.detailsTabs) return;
    this.detailsTabs.gotoTextTab(shift);
  },

  selectTab: function(tab) {
    BS.Util.runWithElement('changeTabs_' + this.key(), function() {
      if (!this.detailsTabs) return;
      if (this.detailsTabs.getTabs().length == 0) return;

      this.detailsTabs.setActiveTab(tab);
    }.bind(this), 6000);
  },

  getSelectedTabId: function() {
    if (!this.detailsTabs) return null;
    if (this.detailsTabs.getTabs().length == 0) return null;

    var activeTab = this.detailsTabs.getActiveTab();
    return activeTab ? activeTab.getId() : this.detailsTabs.getTabs()[0].getId();
  },

  expandBlock: function() {
    if (this.content_cache) {
      this._updateContentFromCache();
    }
    this._refreshChangeDetails(this._updatable());
  },

  collapseBlock: function() {
    this._stop_ajax_update_of_expanded_block();
  },

  _updateContentFromCache: function() {
    if (!BS.canReload() && !BS._temporaryBlocked) {
      // Update content only if page can be updated; i.e. no popup is shown and no expanded stacktrace is there
      BS.Log.debug("Skip update of expanded block");
      return;
    }
    var started = new Date().getTime();
    BS.Log.debug("Start update of expanded block");

    var data = this.content_cache;
    var container = this.getContainer();

    if (container) {
      var dataDiv = container.down('.expandedChange');
      var height = dataDiv ? dataDiv.offsetHeight : 0;

      BS.stopObservingInContainers(container);

      container.innerHTML = data;
      if (height) {
        // Before JS execution the size of the container is none, which affects browser scrolling;
        // fix the size according to the previous value, if it is was present
        container.down('.expandedChange').setStyle("box-sizing: border-box; min-height:" + height + "px");
      }
      this.updateTabs();

      var scripts = container.getElementsByTagName('script');
      Array.prototype.forEach.call(scripts, function(script) {
        // eslint-disable-next-line no-eval
        eval(script.textContent);
        // console.warn(script.textContent)
      });


      setTimeout(function() {
        container = this.getContainer();
        if (container && container.down('.expandedChange')) {
          container.down('.expandedChange').setStyle("min-height: auto");
        }

        if (this.isExpanded()) {
          this.getDetailsContainer().show();
        }

        BS.Log.debug("Done update of expanded block: " + (new Date().getTime() - started) + " msecs");
      }.bind(this), 20);

    }
    delete this.content_cache;
  },

  refreshChangeDetails: function() {

    if (!this.getContainer()) {
      this._stop_ajax_update_of_expanded_block();
      BS.Log.debug("Stop refreshing content for " + this.key());
      return $j.Deferred().resolve();
    }

    if (this._updatable() && this.isExpanded()) {
      return BS.reload(false, function() {
          this._refreshChangeDetails(true);
      }.bind(this));
    }

    return $j.Deferred().resolve();
  },

  _refreshChangeDetails: function(force) {

    var no_content_yet = this.getContainer().innerHTML.blank();

    if (no_content_yet) {
      this._setProgressIcon(true);
    }
    else {
      // Preview last loaded content
      if (this.isExpanded()) {
        this.getDetailsContainer().show();
      }
    }

    if (no_content_yet || force) {

      if (this._loadingDetails) {
        BS.Log.debug("Already loading UI for expanded block, skip");
        return;
      }
      this._loadingDetails = true;

      BS.Log.debug("Start changeExpandedView.html update");
      var started = new Date().getTime();

      this._loadChangeDetails().then(function() {
        this._start_ajax_update_of_expanded_block();

        this._loadingDetails = false;
        BS.Log.debug("End changeExpandedView.html AJAX call: " + (new Date().getTime() - started) + " msecs");
      }.bind(this), function (reason) {
        this._loadingDetails = false;
        BS.Log.debug("FAILED changeExpandedView.html AJAX call");
      }.bind(this));

    }
    else {
      this._start_ajax_update_of_expanded_block();
    }
  },

  _loadChangeDetails: function() {
    var record = this.record;
    var update = this.detailsTabs != null;
    var params = "modId=" + record.modId + "&personal=" + record.personal + "&" + BS.ChangePageFilter.urlParams();
    if (update) {
      params += "&update=true";
    }

    return new Promise(function (resolve, reject) {

      BS.ajaxRequest('changeExpandedView.html', {
        method: 'get',
        parameters: params,
        onFailure: reject,

        onSuccess: function(response) {

          this.content_cache = response.responseText;
          this._updateContentFromCache();
        }.bind(this),

        onComplete: function() {
          this._setProgressIcon(false);
          resolve();
        }.bind(this)
      });

    }.bind(this))
  },

  setTabs: function(tabs, currentTabId) {
    var curr = this.getSelectedTabId();
    var key = this.key();
    if (this.detailsTabs) {
      this.detailsTabs.dispose();
    }

    this.detailsTabs = tabs;
    if (!currentTabId) currentTabId = curr;

    BS.Util.runWithElement('changeTabs_' + key, function() {
      if (tabs.getTabs().length == 0) return;

      tabs.showIn('changeTabs_' + key);
      if (currentTabId) {
        tabs.setActiveTab(currentTabId);
      }
      else {
        tabs.setActiveTab(tabs.getTabs()[0].getId());
      }
    })
  },

  updateTabs: function() {
    var key = this.key();
    var tabs = this.detailsTabs;
    BS.Util.runWithElement('changeTabs_' + key, function() {
      if (!tabs || tabs.getTabs().length == 0) return;

      tabs.showIn('changeTabs_' + key);

      var activeTab = tabs.getActiveTab();
      if (activeTab) {
        tabs.setActiveTab(activeTab.getId());
      } else {
        tabs.setActiveTab(tabs.getTabs()[0].getId());
      }
    })
  },

  beforeLoadCarpet: function() {
    var carpetEl = BS.ChangePage.carpetElement(this.first_record);
    if ( carpetEl && !carpetEl.down(".statusDiagram") ) {
      carpetEl.update("<div class='statusDiagram statusDiagram__placeholder'>?</div>");
    }
  },

  loadCarpet: function(asyncContext) {

    if (this._shouldLoadCarpet()) {
      this._loadCarpetForRelatedNodes(asyncContext);
    }
    else {
      if (asyncContext) asyncContext.done();
    }
  },

  _shouldLoadCarpet: function() {
    var carpetElement = BS.ChangePage.carpetElement(this.record);
    if (!carpetElement) return false;
    return this.record.modId == this.first_record.modId;
  },

  /**
   * @param asyncContext an object of type BS.AsyncContext
   * */
  _loadCarpetForRelatedNodes: function(asyncContext) {

    var loadCarpetRequest = this.loadCarpetAndStatus(function(response) {
      if (asyncContext && asyncContext.isCanceled()) {
        BS.Log.info("Carpet loading canceled");
        return;
      }

      response.responseText.evalScripts();

    }.bind(this), asyncContext ? asyncContext.done.bind(asyncContext) : null);

    this._setAbortCancelCallback(asyncContext, loadCarpetRequest);
  },

  _updateCarpetAndStatusText: function(carpetData, hasProblem, problemText) {
    if (carpetData.length > 0) {

      //var node = BS.changeTree.getNode('ct_node_' + this.first_record.modId + "_" + this.first_record.personal);
      //node.updateCarpet(carpetData);

      BS.ChangePage.for_each_related_record(this.first_record.modId + "_" + this.first_record.personal, function(record) {
        var node = BS.changeTree.getNode('ct_node_' + record.modId + "_" + record.personal);
        if (node) {
          node.updateCarpet(carpetData);
          node.updateStatusText(hasProblem, problemText);
          node.updateBranches(carpetData);
        }
      });
    }
  },

  updateFullComment: function() {
    var node = $(this.getId());
    var text = node ? node.down("span.shortText") : null;
    if (text) {
      if (text.scrollHeight > (text.getHeight() * 2 + 1) ) {
        this.hideFullComment(node);
      }
      else {
        this.showFullComment(node);
      }
    }
  },

  showFullComment: function(node) {
    var shortText = node.down("span.shortText");
    var arrow = node.down('.textExpandArrow');
    arrow.hide();
    shortText.hide();
    $(shortText.nextSibling).show(); // show full comment node
    arrow.stopObserving();
  },

  hideFullComment: function(node) {
    var shortText = node.down("span.shortText");
    var arrow = node.down('.textExpandArrow');
    arrow.title = "Click to see full commit message";
    arrow.show();
    shortText.show();
    $(shortText.nextSibling).hide(); // hide full comment
    arrow.on("click", function() { this.showFullComment(node);}.bind(this) )
  },

  updateCarpet: function (carpetData) {
    //BS.Log.debug("Updating carpet for " + JSON.stringify(this.record) + " with " + JSON.stringify(carpetData));
    var carpetEl = BS.ChangePage.carpetElement(this.record);
    if (carpetEl) {
      BS.stopObservingInContainers([carpetEl]);

      var nodeId = 'ct_node_' + this.record.modId + '_' + this.record.personal;
      var showDetailsScript = "BS.changeTree.getNode('" + nodeId + "').showDetailsTab('builds', true);";

      BS.PieStatus.drawCarpetPieChart(showDetailsScript, carpetEl, carpetData);
    }
  },

  updateBranches: function(carpetData) {
    var node = $(this.getId());
    if (!node) return;

    var tdRevision = node.down("td.commitText");

    if (!ReactUI) {
      // Remove existing branches elements
      tdRevision.select(".branch").each(function (t) {
        t.remove();
      });
    }

    // Collect and sort new branches:
    var branches2Default = {};
    for(var i = 0; i < carpetData.length; i++) {
      var square = carpetData[i];
      var branch = square.branch;
      if (branch) {
        branches2Default[branch] = square.branchDefault;
      }
    }
    var branchNames = Object.keys(branches2Default).sort();
    //branchNames = ["default", "refs/head/some branch", "dddsr"];
    //branches2Default['default'] = true;

    // Insert new branch names

    if (ReactUI) {
      ReactUI.render(
        branchNames.map(function createBranchElement(branch) {
          return [
            ReactUI.createElement(ReactUI.BuildBranch, {
              key: branch,
              name: branch,
              main: branches2Default[branch],
              defaultTrim: true,
              noLink: true,
              withBorder: true
            }),
            ' '
          ];
        }),
        tdRevision.querySelector('.js_branches')
      );
    } else {
      var branchesText = "";

      for (i = 0; i < branchNames.length; i++) {
        branch = branchNames[i];
        var cssClass = branches2Default[branch] ? "default" : "hasBranch";
        branchesText += "<span class='branch " + cssClass + "'><span class='branchName'>" +
          BS.trimText(branch, 30).escapeHTML() + "</span></span> ";
      }

      tdRevision.down(".changeFailuresLink").insert({before: branchesText});
    }
  },

  loadCarpetAndStatus: function(onSuccess, onComplete) {
    var record = this.first_record;
    var params = "modId=" + record.modId + "&personal=" + record.personal + "&" + BS.ChangePageFilter.urlParams();
    if (!onComplete) onComplete = Prototype.emptyFunction;

    return BS.ajaxRequest('carpet.html', {
      method: 'get',
      parameters: params,
      onSuccess: onSuccess,
      onComplete: onComplete
    });
  },

  _setAbortCancelCallback: function(context, request) {
    if (context && request && request.transport && (typeof request.transport.abort == 'function' )) {
      context.setCancelCallback(function() {
        request.transport.abort();
      });
    }
  },

  _updatable: function() {
    return this.getContainer().descendantOf($("updatableChangesContainer"));
  },

  _start_ajax_update_of_expanded_block: function() {
    if (!this.updater) {
      this.updater = BS.periodicalExecutor(this.refreshChangeDetails.bind(this), BS.RefreshIntervalHolder.REFRESH_INTERVAL);
      this.updater.start();
    }
  },

  _stop_ajax_update_of_expanded_block: function() {
    if (this.updater) {
      this.updater.stop();
      this.updater = null;
    }
  },

  updateStatusText: function(hasProblem, problemText) {
    BS.Util.runWithElement(this.getId(), function() {
      var el = $(this.getId());
      if (!el) return;
      this.hasProblem = hasProblem;

      this._updateIconAndDetailsBlock();

      var commitTextNode = el.down("td.commitText");
      var problemSummaryNode = commitTextNode ? commitTextNode.down(".changeFailuresLink") : null;
      if (problemSummaryNode) {
        problemSummaryNode.update(problemText);
        if (problemText.blank()) {
          problemSummaryNode.hide();
        }
        else {
          problemSummaryNode.show();
        }
      }
    }.bind(this), 5000);
  },

  key: function() {
    if (!this._key) {
      this._key = this.record.modId + "_" + this.record.personal;
    }
    return this._key;
  },

  _f: null
});

BS.changeTree = new BS.Tree();
BS.changeSel = new BS.TreeSelection(BS.changeTree);

BS.treeNav = new BS.TreeKeyboardSupport(document, BS.changeSel);
BS.treeNav.switchToTabFromKeyboard = function(e, tab) {
  var selected = BS.changeSel.getSelection();
  if (!selected || e.ctrlKey || e.altKey || e.metaKey) return false;

  var node =  BS.changeTree.getNode(selected);
  if (!node) return false;

  node.showDetailsTab(tab);
  return true;
};
BS.treeNav.addKeyHandler(84, BS.treeNav.switchToTabFromKeyboard.bindAsEventListener(BS.treeNav, 'problems'));
BS.treeNav.addKeyHandler(66, BS.treeNav.switchToTabFromKeyboard.bindAsEventListener(BS.treeNav, 'builds'));
BS.treeNav.addKeyHandler(70, BS.treeNav.switchToTabFromKeyboard.bindAsEventListener(BS.treeNav, 'files'));

BS.changeTree.addListener({
                            onExpandChange: function() {
                              if (this.initializing) return;

                              if (this.expandTimeout) {
                                clearTimeout(this.expandTimeout);
                              }
                              this.expandTimeout = setTimeout(function() {
                                this.expandTimeout = null;
                                BS.User.setProperty("changesTreeState", this.collectExpandedNodes());
                              }.bind(this), 50);
                            },

                            onNodeAdded: function() {
                            },

                            onNodeDestroyed: function() {
                            },

                            onSelectionChange: function(newSelId, oldSelId) {
                              if (!$(oldSelId)) return;

                              var next = $(oldSelId).nextSiblings()[0];
                              if (next) {
                                next.removeClassName('selectedTreeNode');
                              }
                              var parentTable = $(oldSelId).up("table");
                              if (parentTable) {
                                parentTable.removeClassName("selectedGroup");
                              }

                              BS.Cookie.set("changesTreeSel", newSelId, 1.0/24);
                            },

                            onSelectionRepaint: function(newSelId) {
                              var next = $(newSelId).nextSiblings()[0];
                              if (next) {
                                next.addClassName('selectedTreeNode');
                              }

                              var parentTable = $(newSelId).up("table");
                              if (parentTable && $j(parentTable).find("> tbody > tr").size() > 2) {
                                parentTable.addClassName("selectedGroup");
                              }
                            },

                            f: null
                          });





$j.extend(BS.changeTree, {

  updateCarpetAndStatusText: function(node_id, carpetData, hasProblem, problemText) {
    // Carpet data is an array of  objects, where firt element is build type json object, and the second element is status string:
    // [{buildType: {id: "bt3", name: "some name", fullName: "some full name"}, statusText: "successful", (optional)branch: "branch_name"}]

    var node = BS.changeTree.getNode(node_id);
    if (node) {
      node._updateCarpetAndStatusText(carpetData, hasProblem, problemText);
    }
  },

  refreshChangeDetails: function(node_id) {
    var node = BS.changeTree.getNode(node_id);
    if (node) {
      node._refreshChangeDetails(true);
    }
  },

  synchronizeViewAndModel: function() {
    BS.changeSel.repaintSelection();
    this.forEachNode(function(node) {
      node.updateView();
    });
    BS.changeSel.repaintSelection();
  },

  updateTopNodesOrder: function() {
    var seq = [];
    $$('.joinedChangeTable tr').each(function(tr) {
      if (tr.id.startsWith('ct_node_')) {
        seq.push(tr.id);
      }
    });
    this._root_sequence = seq;
  },

  refreshExpanded: function() {
    if (BS.ChangeNode._expanded_single_node) {
      var node = this.getNode(BS.ChangeNode._expanded_single_node);
      if (node) {
        node._refreshChangeDetails(true);
      }
    }
  },

  preloadBlocks: function() {
    var progress;
    if ($('loadingProgress') && BS.ChangePreloadBlocks.length > 0) {
      progress = new BS.ChangePage.Progress("Loading change details... ");
    }
    BS.AsyncRunner.setCallbackOnFinish(function() {
      if (this.isEmpty() && progress) {
        progress.stop();
      }
    });

    $A(BS.ChangePreloadBlocks).each(function(record) {
      var node = this.getNode(record);
      if (node) {
        node.beforeLoadCarpet();
        BS.AsyncRunner.runAsync(function(asyncContext) {
          node.loadCarpet(asyncContext);
        }, 1);
      }
    }, this);
  },

  hasNonPersonalChanges: function() {
    return this.getChildren().some(function(node_id) {
      var node = this.getNode(node_id);
      return node && !node.record.personal;
    }, this);
  },

  hasPersonalChanges: function() {
    return this.getChildren().some(function(node_id) {
      var node = this.getNode(node_id);
      return node && node.record.personal;
    }, this);
  }

});

BS.ChangePage.Progress = function(text) {
  text = jQuery.trim(text);

  BS.DelayedAction.call(this, function() {
    if ($("loadingProgress")) $("loadingProgress").update(BS.loadingIcon + ' ' + text);
  }, function() {
    if ($("loadingProgress")) $("loadingProgress").update("&nbsp;"); // nbsp to avoid layout jumping
  });
  this.start();
};
BS.ChangePage.Progress.prototype = new BS.DelayedAction();
