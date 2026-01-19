BS.Projects = {
  _projectUpdateUrl: '/overview.html',
  _newProjectsPaneId: "new-projects",
  _newProjectsPopupId: "newProjectsPopupContent",

  updateProjectView: function(projectId, projectExternalId, firstProjectInList, force, moreParams) {
    BS.reload(!!force, function() {
      BS.Projects._updateProjectView("p_" + projectId, projectExternalId, firstProjectInList, moreParams);
    });
  },

  _updateProjectView: function(elementId, projectExternalId, firstProjectInList, moreParams) {
    moreParams = moreParams || {};
    BS.Branch.addBranchToParams(moreParams, projectExternalId);
    var params = $H(_.extend(moreParams, {
      projectId: projectExternalId,
      firstProjectInList: !!firstProjectInList,
      refreshProject: '1' // used by ProjectController to determine that partial content is requested
    }));

    // The ajax update URL for the project page should be 'project.html' (not 'overview.html') otherwise it is possible that project
    // will not be found on the overview, and thus empty response will come.
    var url = window['base_uri'] + BS.Projects._projectUpdateUrl;
    BS.ajaxUpdater(elementId, url, {
      method: 'get',
      parameters: params.toQueryString(),
      evalScripts: true,
      insertion: function(container, response) {
        var $response = $j(response);
        !$j(container).is(':visible') && $response.hide();
        BS.stopObservingInContainers(container);
        $j(container).replaceWith($response);
        BS.enableDisabled($response);
        BS.SystemProblems.updateNow();
      }
    });
  },

  hideProject: function(projectId) {
    BS.ajaxRequest("ajax.html?hideProject=" + projectId, {
      onSuccess: function() {
        var projectEl = $('p_' + projectId);
        new Effect.Fade(projectEl, {
          afterFinish: function() {
            projectEl.remove();

            var divs = $('buildTypes').getElementsByTagName('DIV');
            for (var i =0; i < divs.length; i++) {
              if (divs[i].className == 'projectHeader') return;
            }

            new Effect.Highlight("configVisibleProjects");
          }
        });
      }
    });
    return false;
  },

  addNewProject: function(projectId) {
    this.markProject(projectId, true);
    return this.addOrHideProject("addProject", projectId, "new_" + projectId, true);
  },

  hideNewProject: function(projectId) {
    this.markProject(projectId, false);
    return this.addOrHideProject("hideProject", projectId, "new_" + projectId, false);
  },

  addAllProjects: function(projectIds) {
    projectIds = this.filterMarked(projectIds, false);
    return this.addOrHideProject("addProject", projectIds, this._newProjectsPaneId, true)
  },

  hideAllProjects: function(projectIds) {
    projectIds = this.filterMarked(projectIds, true);
    return this.addOrHideProject("hideProject", projectIds, this._newProjectsPaneId, false);
  },

  markProject: function(projectId, value) {
    if (!this._marked) {
      this._marked = [];
    }
    this._marked.push([projectId, value]);
  },

  filterMarked: function(projectIds, valueToFilter) {
    if (this._marked) {
      for (var i = 0; i < this._marked.length; ++i) {
        var current = this._marked[i];
        if (current[1] == valueToFilter) {
          projectIds = projectIds.replace(current[0] + ",", "");
        }
      }
    }
    return projectIds;
  },

  addOrHideProject: function(action, arg, fadeElement, refresh) {
    var $fadeElement = $j("#" + fadeElement);
    if ($fadeElement.attr("disabled")) {
      return false;
    }

    $fadeElement.attr("disabled", "disabled");
    BS.ajaxRequest("ajax.html", {
      parameters: action + "=" + arg,
      onSuccess: function() {
        if (refresh) {
          if ($("overviewMain")) {
            $("overviewMain").refresh();
          } else {
            BS.reload(true);
            return;
          }
        }
        var visibleNumber = jQuery("#new-projects-list .entry").filter("[disabled!=\"disabled\"]").length;

        if (fadeElement == BS.Projects._newProjectsPaneId || visibleNumber <= 0) {
          new Effect.Fade(BS.Projects._newProjectsPaneId, {
            afterFinish: function () {
              new Effect.Highlight("configVisibleProjects");
            }
          });
          $(BS.Projects._newProjectsPopupId) && new Effect.Fade(BS.Projects._newProjectsPopupId);
        } else {
          new Effect.Fade(fadeElement);
          $j('#new-projects-count').text(visibleNumber);
        }

      }
    });
    return false;
  },

  installShowHideLink: function(projectVisible, projectId) {
    var link = $j("<a/>").attr({
      href: "#",
      "class": "btn btn_mini pinLink",
      title: projectVisible ? "Project is shown on the overview page. Click to hide" : "Click to show project on the overview page"
    }).click(function() {
        return BS.TogglePopup.toggleOverview(this, projectId, {
          loadingTop: 2,
          loadingLeft: -16,
          updateParent: false
        });
    });

    $j("<i/>").attr({
      "class": "icon icon16 icon16_watched" + (projectVisible ? "" : " icon16_watched_no")
    }).appendTo(link);

    link.prependTo('#topWrapper .quickLinks');
    link.wrap('<div class="toolbarItem"/>');
  }
};

jQuery(function($) {
  BS.lazyLoadProject = function(projectId, projectExternalId, isFirst) {
    var blockId = "btbovr_" + projectId,
        block = $(BS.Util.escapeId(blockId));

    if ($.trim(block.html())) return; // do nothing, some content is already displayed in this project

    if (block.is(":visible")) {
      block.html("<span style='margin: 0.5em;'>" + BS.loadingIcon + "&nbsp;Loading...</span>");

      BS.Projects.updateProjectView(projectId, projectExternalId, isFirst, true, {
        force_show_build_types: true,
        child_project: true
      });
    }
  }
});
