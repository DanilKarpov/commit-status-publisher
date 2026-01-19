/*
 * Copyright 2000-2024 JetBrains s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Facility for build branches.

BS.Branch = {
  WILDCARD_NAME: "__all_branches__",  // BranchUtil.WILDCARD_BRANCH
  DEFAULT_NAME: "<default>",         // BranchUtil.DEFAULT_BRANCH_NAME and Branch.DEFAULT_BRANCH_NAME
  UNSPECIFIED_NAME: "<unspecified>",          // BranchUtil.DEFAULT_BRANCH_NAME and Branch.DEFAULT_BRANCH_NAME
  STORAGE_PREFIX: "jb.teamcity.branch.", // Prefix for sessionStorage keys

  baseUrl: null,                      // The URL where branch links should lead to (by default, build type overview page).
  _branches: {},                      // Holds the branches per project (on a current page).

  filterHistoryByBranch: null,        //will be set during branch selector processing
  branchParamPrefix: 'branch_',       // we encode branch in URL in the following format: branch_<externalProjectId>=<branchName>

  _allBranchesTabNames : [
    "buildTypeStatusDiv",
    "buildTypeChains",
    "buildTypeHistoryList",
    "buildTypeChangeLog",
    "buildTypeIssueLog",
    "projectBuildChains",
    "testDetails",
    "projectChangeLog",
    "buildTypeStatistics",
    "stats"
  ],

  _activeBranchesTabNames: [
    "projectOverview",
    "buildTypeBranches",
    "pendingChangesDiv"
  ],

  _wildcardName: function(options, noEscaping){
    var wildcardName = options.wildcardDisplayName;
    var tab = options.tab;
    if (!wildcardName) {
      wildcardName = this._allBranchesTabNames.indexOf(tab) > -1  ?
                     "&lt;All branches&gt;" :
                     "&lt;Active branches&gt;";
    }
    return !noEscaping ? wildcardName : wildcardName.replace('&lt;','<').replace('&gt;','>');
  },

  saveBranch: function(projectExternalId, selectedBranch) {
    var branch = this.getNonWildCardBranch(selectedBranch);
    var key = this.STORAGE_PREFIX + projectExternalId;
    branch != null
      ? sessionStorage.setItem(key, branch)
      : sessionStorage.removeItem(key);
    this.registerProjectBranch(projectExternalId, selectedBranch);
  },

  _addChangeHandler: function(options, selectedBranch) {
    var projectInternalId = options.projectInternalId;
    var projectExternalId = options.projectExternalId;
    this.saveBranch(projectExternalId, selectedBranch);

    var search = BS.Branch._getSearch(window.location.search, selectedBranch, projectExternalId);
    if (!BS.Branch.getBranchGroupId(selectedBranch)) {
      search = search.replace(/tab=buildTypeBranches/g, "tab=buildTypeStatusDiv");    // See TW-22583.
    }

    var that = this;

    if (options.save) {  // overview page
      BS.User.setProperty("ui.overview.branch." + projectInternalId, selectedBranch, {
        afterComplete: function() {
          that.registerProjectBranch(projectExternalId, selectedBranch);
          BS.Projects.updateProjectView(projectInternalId, projectExternalId, options.isFirst, true);
        }
      });
    } else if (options.replace) {
      var parser = document.createElement('a');
      parser.href = window.location.href;
      parser.search = search;
      window.location.replace(parser.href);
    } else {
      window.location.search = search;
    }
  },

  isDefault: function(branch, defaultBranchVcsName) {
    return branch == this.DEFAULT_NAME || branch == defaultBranchVcsName
  },

  _discoverName: function(branch, defaultBranchVcsName){
    if (branch == this.WILDCARD_NAME){
      return "<All branches>";
    }
    if (this.isDefault(branch, defaultBranchVcsName)) {
      return "<Default branch>";
    }
    return branch;
  },

  stringifyBranch: function(selected) {
    if (!selected) {
      return this.WILDCARD_NAME;
    }
    if (selected.groupFlag) {
      return '__' + selected.internalName + '__';
    }
    if (selected.default) {
      return this.DEFAULT_NAME;
    }
    if (selected.unspecified) {
      return this.UNSPECIFIED_NAME;
    }
    return selected.name;
  },

  parseBranch: function(userBranch, defaultBranchVcsName) {
    if (!userBranch || userBranch === this.WILDCARD_NAME) {
      return null
    }

    var name = this._discoverName(userBranch, defaultBranchVcsName);
    var groupId = this.getBranchGroupId(userBranch);
    var isGroup = groupId != null;

    return {
      name: isGroup ? '<Branch group>' : name,
      internalName: isGroup ? groupId : name,
      default: this.isDefault(userBranch, defaultBranchVcsName),
      groupFlag: isGroup
    }
  },

  renderReactDropdown: function(userBranch, id, handleLoad, options, minimalistic) {
    ReactUI.renderBranchSelect(id, {
      className: 'branch-search',
      old: true,
      minimalistic: minimalistic,
      projectOrBuildTypeNode: options.buildTypeExternalId != null
                              ? {nodeType: 'bt', id: options.buildTypeExternalId}
                              : {nodeType: 'project', id: options.projectExternalId},
      buildTypeInternalId: options.buildTypeInternalId,
      projectInternalId: options.projectInternalId,
      activeOnly: this._allBranchesTabNames.indexOf(options.tab) == -1,
      includeSnapshots: options.includeSnapshots,
      includeSubprojects: options.includeSubprojects,
      selected: this.parseBranch(userBranch),
      onSelect: function(selected, replace) {
        options.replace = replace;
        BS.Branch._addChangeHandler(options, BS.Branch.stringifyBranch(selected));
      },
      onLoad: handleLoad
    });
  },

  installRestDropdownToBreadcrumb: function(userBranch, options) {
    if (!document.getElementById('restPageTitle')) {
      return;
    }

    function handleLoad(data) {
      if (data.shouldBeVisible){
        $j(wrapper).css('display', 'inline-block');
      }
      BS.Branch.filterHistoryByBranch = data.shouldBeVisible;
      BS.Branch.defaultBranchVcsName = data.defaultBranchVcsName;
      document.dispatchEvent(new CustomEvent("tc.branchSelectorIsReady", {
        bubbles: true,
        detail: {
          hasBranches: data.shouldBeVisible,
          defaultBranchVcsName: data.defaultBranchVcsName
        }
      }));
    }

    var tabsContainer = $j("#tabsContainer3");
    var branchInBreadcrumbsSelector = $j("#restPageTitle .branch-search");

    if (branchInBreadcrumbsSelector.length > 0) {
      return;
    }

    var tab = options.tab;

    this.registerProjectBranch(options.projectExternalId, userBranch);

    var self = this;

    window.setTimeout(function(){
      self.injectBranchParamToLinks(tabsContainer, options.projectExternalId);
    }, 150);

    if (tab != undefined && this._allBranchesTabNames.indexOf(tab) == -1  && this._activeBranchesTabNames.indexOf(tab) == -1){
      return; // we don't need branch selector on this tab
    }

    var name = this._wildcardName(options, true);
    var initialName = userBranch;
    if (userBranch == this.WILDCARD_NAME){
      userBranch = name;
    }

    var visibility = (userBranch !== undefined && userBranch != name && userBranch !=  this.DEFAULT_NAME) ? 'inline-block' : 'none';

    var id = 'branchSelect_' + options.projectExternalId || options.buildTypeExternalId;

    var wrapper = $j("<div class='branchSearchWrapper' style='display:" + visibility + ";'><div id='" + id + "'></div></div></div>").insertAfter('#restPageTitle .selected');

    this.renderReactDropdown(
      initialName,
      id,
      handleLoad,
      options,
      true
    );
  },

  renderBuildList: function(userBranch, isAllBranches, renderFn){
    if (isAllBranches || userBranch == undefined || userBranch == 'undefined' || userBranch.trim().length == 0) {
      renderFn();
      return;
    }

    if (BS.Branch.filterHistoryByBranch != null) {
      renderFn(BS.Branch.parseBranch(userBranch, BS.Branch.defaultBranchVcsName));
    } else {
      document.addEventListener('tc.branchSelectorIsReady', function (e) {
        var hasBranches = e.detail.hasBranches;
        var defaultBranchVcsName = e.detail.defaultBranchVcsName;
        renderFn(hasBranches ? BS.Branch.parseBranch(userBranch, defaultBranchVcsName) : null);
      }, false);
    }
  },

  registerProjectBranch: function(projectExtId, userBranch) {
    var key = this.STORAGE_PREFIX + projectExtId;
    if (userBranch === this.WILDCARD_NAME) {
      this._branches[projectExtId] = null;
      sessionStorage.removeItem(key);
    } else if (userBranch != null) {
      this._branches[projectExtId] = userBranch;
      sessionStorage.setItem(key, userBranch);
    }
  },

  createHandleLoad: function(paneId) {
    return function(data) {
      var pane = $j(paneId);
      if (data.shouldBeVisible) {
        pane.css('display', 'inline-block');
      }
    }
  },

  installRestDropDownToProjectPane: function(paneId, userBranch, options) {
    var pane = $j(paneId);
    var handleLoad = this.createHandleLoad(paneId);

    options.save = true;

    var name = this._wildcardName(options, true);
    var initialName = userBranch;
    if (userBranch == this.WILDCARD_NAME){
      userBranch = name;
    } else {
      this.registerProjectBranch(options.projectExternalId, userBranch);
    }

    var innerId = paneId + '_inner';
    pane.append('<div id="' + innerId + '"></div>');
    pane.click(function(e) {
      e.stopPropagation();
    });
    this.renderReactDropdown(
      initialName,
      innerId,
      handleLoad,
      options
    );
  },

  _isBranchesTab: function(search) {
    var params = new URLSearchParams(search || location.search);
    return params.get('tab') === 'buildTypeBranches';
  },

  /**
   * <p>Adds the branch parameter to all anchor elements referencing a project
   * or a build configuration, depending on currently selected branch. If no
   * branch is selected, {@link WILDCARD_NAME} value is used.</p>
   *
   * <p>If you need an anchor element within the <code>container</code> to
   * be skipped by this method, add <code>js_ignore-branch</code> class to such
   * an anchor.</p>
   *
   * @param {jQuery} container
   * @param {String} projectExternalId
   * @external jQuery
   */
  injectBranchParamToLinks: function(container, projectExternalId) {
    var /**String*/ branch = this.getBranch(projectExternalId);
    if (branch == null) {
      return;
    }
    var isCustomBranchGroup = branch != this.WILDCARD_NAME && BS.Branch.getBranchGroupId(branch);
    // TW-63088
    if (!isCustomBranchGroup && BS.Branch._isBranchesTab()) {
      return
    }

    var /**BS.Branch*/ that = this;
    container.find("a:not(.js_ignore-branch)").each(function() {
      var /**HTMLAnchorElement*/ link = this;
      var /**String*/ href = link.getAttribute("href");

      if (!href || href.startsWith("#") || href.startsWith("javascript:")) {
        return;
      }

      // One more exception. See TW-22583.
      if (!isCustomBranchGroup && BS.Branch._isBranchesTab(link.search)) {
        // TW-63088
        link.addEventListener('click', function(e) {
          if (e.button === 0 && !e.altKey && !e.ctrlKey && !e.metaKey && !e.shiftKey) {
            BS.Branch.saveBranch(projectExternalId, null);
          }
        });
        return;
      }

      /*-
       * Inject branch parameter into links in breadcrumb.
       */
      if (href.indexOf("viewType.html") >= 0 || href.indexOf("project.html") >= 0 || href.indexOf("viewLog.html") >= 0 || href.indexOf("viewQueued.html") >= 0) {
        link.search = that._getSearch(link.search, branch, projectExternalId);
      }
    });
  },

  getLink: function(buildTypeExternalId, projectExternalId, branch) {
    var url = this.baseUrl;
    if (!url) {
      url = window["base_uri"] + "/viewType.html?buildTypeId=" + buildTypeExternalId;
    }
    return this._getUrl(url, branch, projectExternalId);
  },

  setLink: function(link, buildTypeExternalId, projectExternalId, branch) {
    if (link.getAttribute('href') == "#") {
      link.setAttribute("href", this.getLink(buildTypeExternalId, projectExternalId, branch));
    }
  },

  _getSearch: function(search, branch, projectExternalId) {
    var query = search.toQueryParams();
    for (var param in query) {
      if (param.indexOf(this.branchParamPrefix) != -1) { // remove all other branch_ parameters
        delete query[param];
      }
    }
    query[this.branchParamPrefix + projectExternalId] = branch;  // No need to escape. toQueryString() will do that.
    return Object.toQueryString(query);
  },

  _getUrl: function(url, branch, projectExternalId) {
    var parser = document.createElement('a');
    parser.href = url;
    parser.search = this._getSearch(parser.search, branch, projectExternalId);
    return parser.href
  },

  getNonWildCardBranch: function(branch) {
    return branch !== this.WILDCARD_NAME ? branch : null;
  },

  getBranch: function(projectExternalId, noStorage) {
    var branch = this._branches[projectExternalId]
      || window.location.search.toQueryParams()[this.branchParamPrefix + projectExternalId]
      || !noStorage && sessionStorage.getItem(this.STORAGE_PREFIX + projectExternalId)
      || null;
    return this.getNonWildCardBranch(branch);
  },

  addBranchToParams: function(params, projectExternalId) {
    var branch = this.getBranch(projectExternalId, true);
    if (branch) {
      params[this.branchParamPrefix + projectExternalId] = branch;
    }
  },

  addAllBranchesFromStorage: function(storage, params) {
    Object.keys(storage).filter(function (key) {
      return key.indexOf(BS.Branch.STORAGE_PREFIX ) === 0;
    }).forEach(function (key) {
      var projectExternalId = key.slice(BS.Branch.STORAGE_PREFIX.length);
      params[BS.Branch.branchParamPrefix + projectExternalId] = storage.getItem(key);
    }.bind(this));
  },

  getAllBranches: function() {
    var params = {};
    try {
      this.addAllBranchesFromStorage(sessionStorage, params);
    } catch (e) {
      //Ignore errors
    }
    Object.keys(this._branches).forEach(function(key) {
      params[BS.Branch.branchParamPrefix + key] = BS.Branch._branches[key] || BS.Branch.WILDCARD_NAME;
    });
    return params;
  },

  isCustomBranch: function(branch) {
    return branch && !(branch == this.WILDCARD_NAME || branch == this.DEFAULT_NAME || BS.Branch.getBranchGroupId(branch) != null);
  },

  getBranchGroupId: function(userBranch) {
    if (
      userBranch
      && userBranch !== BS.Branch.WILDCARD_NAME
      && userBranch.startsWith("__")
      && userBranch.endsWith("__")
    ) {
      return userBranch.substring(2, userBranch.length - 2);
    }
    return null;
  }
};