BS.ReportTabsForm = {
  deleteTab: function(tabType, tabId, projectExternalId) {
    if (!confirm("Are you sure you want to remove this report tab?")) return;
    var url = window['base_uri'] + "/admin/action.html?deleteReportTab=" + tabId;
    url += "&projectId=" + projectExternalId;
    url += "&tabType=" + tabType;
    BS.ajaxRequest(url, {
      onSuccess: function() {
        BS.ReportTabsForm.refreshTabsList();
      }
    });
  },

  refreshTabsList: function() {
    $('reportTabsList').refresh();
  }
};


BS.BuildReportTabDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  getContainer: function() {
    return $('editBuildReportTabDialog');
  },

  formElement: function() {
    return $('editBuildReportTab');
  },

  show: function(tabId, title, startPage) {
    var form = this.formElement();
    Form.reset(form);
    if (tabId) {
      // edit mode
      this.tabId = tabId;
      form.tabTitle.value = title;
      form.tabStartPage.value = startPage;
    } else {
      this.tabId = undefined;
      form.tabStartPage.value = "index.html";
      form.tabTitle.value = '';
    }
    this.clearErrors();
    this.bindCtrlEnterHandler(this.save.bind(this));
    this.showCentered();
    form.tabTitle.focus();
  },

  save: function() {
    BS.Util.show('saving_buildReportTab');
    var form = this.formElement();
    Form.disable(form);
    var params = BS.Util.serializeForm(form);

    if (this.tabId) {
      params = params + "&tabId=" + this.tabId + "&create=false";
    } else {
      params = params + "&create=true";
    }

    var that = this;
    BS.ajaxRequest(form.action, {
      parameters: params,
      onComplete: function (transport) {
        BS.Util.hide('saving_buildReportTab');
        Form.enable(that.formElement());
        that.clearErrors();
        var errors = BS.XMLResponse.processErrors(transport.responseXML, {
          onInvalidTitleError: function(elem) {
            that.highlightTitleError(elem.firstChild.nodeValue);
          },
          onDuplicateTabTitleError: function(elem) {
            that.highlightTitleError(elem.firstChild.nodeValue);
          }
        });
        if (!errors) {
          that.close();
          BS.ReportTabsForm.refreshTabsList();
        }
      }
    });
    return false;
  },

  highlightTitleError: function(message) {
    $("error_buildTabTitle").innerHTML = message;
    this.highlightErrorField(this.formElement().tabTitle);
  }

}));

BS.ProjectReportTabDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {

  getContainer: function() {
    return $('editProjectReportTabDialog');
  },

  formElement: function() {
    return $('editProjectReportTab');
  },

  show: function(tabId, title, startPage, buildTypeId, revisionName, revisionValue, branchFilter, showArchived) {
    BS.ProjectReportTabDialog.BuildFinder.shouldAttach();
    this.clearErrors();
    var form = this.formElement();
    var revisionRules = $('revisionRules');
    Form.reset(form);
    if (tabId) {
      // edit mode
      this.tabId = tabId;
      form.tabTitle.value = title;
      form.tabStartPage.value = startPage;
      if (revisionRules) {
        this.selectOption($('buildTypeId'), buildTypeId);
        this.selectOption(revisionRules, revisionName);
        var buildNumberRule = revisionRules.selectedIndex == 3;
        var buildTagRule = revisionRules.selectedIndex == 4;
        if (buildNumberRule) {
          $('buildNumberPattern').value = revisionValue.unescapeHTML();
        }
        if (buildTagRule) {
          $('buildTag').value = revisionValue.unescapeHTML();
        }
        $('buildBranchFilter').value = branchFilter;
      }
    } else {
      // create mode
      this.selectOption($('buildTypeId'), $j('#buildTypeId option:enabled:first').val());
      form.tabStartPage.value = "index.html";
      form.tabTitle.value = '';
      this.tabId = undefined;
      this.selectOption(revisionRules, 'lastSuccessful');
    }
    this.bindCtrlEnterHandler(this.save.bind(this));
    this.showCentered();
    form.tabTitle.focus();
    this._afterInit(tabId, showArchived);
  },

  _afterInit: function(editMode, showArchived) {
    var form = BS.ProjectReportTabDialog.formElement();
    Form.disable(form);
    BS.Util.show('saving_projectReportTab');
    setTimeout(function() {
      BS.ProjectReportTabDialog.updateBuildTypeTagsList();
      BS.ProjectReportTabDialog.manageArchivedBuildTypes(editMode && showArchived);
      Form.enable(form);
      BS.Util.hide('saving_projectReportTab');
      BS.ProjectReportTabDialog.updateFieldVisibility();
      BS.ProjectReportTabDialog.BuildFinder.attachOnFirstShow();
    }, 20);
  },

  save: function() {
    BS.Util.show('saving_projectReportTab');
    var form = this.formElement();
    Form.disable(form);

    var params = BS.Util.serializeForm(form);

    var revisionRules = $('revisionRules');
    if (revisionRules) {
      params += "&revisionRule=" + revisionRules.options[revisionRules.selectedIndex].value;
    }

    if (this.tabId) {
      params = params + "&tabId=" + this.tabId + "&create=false";
    }
    else {
      params = params + "&create=true";
    }

    var that = this;
    BS.ajaxRequest(form.action, {
      parameters: params,

      onComplete: function (transport) {
        BS.Util.hide('saving_projectReportTab');
        Form.enable(that.formElement());
        that.clearErrors();
        var errors = BS.XMLResponse.processErrors(transport.responseXML, {
          onInvalidTitleError: function(elem) {
            that.highlightTitleError(elem.firstChild.nodeValue);
          },
          onInvalidBuildTypeIdError: function (elem) {
            that.highlightBuildTypeError(elem.firstChild.nodeValue);
          },
          onDuplicateTabTitleError: function(elem) {
            that.highlightTitleError(elem.firstChild.nodeValue);
          },
          onEmptyBuildNumberPatternError: function(elem) {
            that.highlightBuildNumberPattern(elem.firstChild.nodeValue);
          },
          onEmptyBuildTagError: function(elem) {
            that.highlightEmptyBuildTagError(elem.firstChild.nodeValue);
          }
        });
        BS.VisibilityHandlers.updateVisibility('editReportTab');

        if (!errors) {
          that.close();
          BS.ReportTabsForm.refreshTabsList();
        }
      }
    });

    return false;
  },

  highlightTitleError: function(message) {
    $("error_projectTabTitle").innerHTML = message;
    this.highlightErrorField(this.formElement().tabTitle);
  },

  highlightBuildNumberPattern: function(message) {
    $("error_buildNumberPattern").innerHTML = message;
    this.highlightErrorField(this.formElement().buildNumberPattern);
  },

  highlightEmptyBuildTagError: function(message) {
    $("error_buildTag").innerHTML = message;
    this.highlightErrorField(this.formElement().buildTag);
  },

  highlightBuildTypeError: function(message) {
    $("error_buildTypeId").innerHTML = message;
    this.highlightErrorField(this.formElement().buildTypeId);
  },

  selectOption: function(element, v) {
    for (var i = 0; i < element.options.length; i++) {
      if (element.options[i].value == v) {
        element.selectedIndex = i;
        break;
      }
    }
    BS.jQueryDropdown(element).ufd("changeOptions");
  },

  hasAnyBuilds: function() {
    var form = this.formElement();
    return form.buildTypeId && form.buildTypeId.options.length > 0;
  },

  updateBuildTypeTagsList: function() {
    var tagListHtml = "";
    var form = this.formElement();

    if (!this.hasAnyBuilds()) {
      BS.Util.hide('buildTagList');
      return;
    }

    var selectedBuildTypeId = form.buildTypeId.options[form.buildTypeId.selectedIndex].value;
    var url = window['base_uri'] + "/editArtifactDepsHelper.html";

    BS.ajaxRequest(url, {
      parameters: {
        listTags : '',
        buildTypeId : selectedBuildTypeId
      },
      onComplete: function(transport) {
        var responseXML = transport.responseXML;
        var tagData = responseXML.firstChild.firstChild;

        function renderTagLink(label, escapedLabel) {
          return "<a href=\"#\" class=\"unselectedTag\" onclick=\"BS.ProjectReportTabDialog.setBuildTagValue('" +
            escapedLabel + "'); return false\">" + label.escapeHTML() + "</a> ";
        }

        if (tagData) {
          while (tagData) {
            tagListHtml = tagListHtml + renderTagLink(tagData.getAttribute("original"),
                                                      tagData.getAttribute("escaped"));
            tagData = tagData.nextSibling;
          }
          $('buildTagListSpan').innerHTML = tagListHtml;
          BS.Util.show('buildTagList')
        } else {
          BS.Util.hide('buildTagList');
        }
      }
    });
  },

  setBuildTagValue: function(tagValue) {
    var textField = $('buildTag');
    if (!textField.disabled) {
      textField.value = tagValue;
    }
  },

  updateFieldVisibility: function() {
    var form = this.formElement();
    if (!form.revisionRules) {
      return;
    }

    var buildNumberSelected = form.revisionRules.selectedIndex == 3;
    var buildTagSelected = form.revisionRules.selectedIndex == 4;

    if (buildNumberSelected) {
      $j('#buildNumberField').show();
      $j('#buildTagField').hide();
    } else if (buildTagSelected) {
      $j('#buildNumberField').hide();
      $j('#buildTagField').show();
      this.updateBuildTypeTagsList();
    } else {
      $j('#buildNumberField').hide();
      $j('#buildTagField').hide();
    }
    BS.VisibilityHandlers.updateVisibility('buildNumberField');
    BS.VisibilityHandlers.updateVisibility('buildTagField');

    var selectedId = $('buildTypeId').options[$('buildTypeId').selectedIndex].value;

    var showBranchField = function(branches) {
      var hasNonDefaultBranch = branches.length > 1;
      if (!hasNonDefaultBranch) {
        for (var i=0; i<branches.length; i++) {
          if (!branches[i].is_default) {
            hasNonDefaultBranch = true;
            break;
          }
        }
      }

      if (hasNonDefaultBranch && $('buildBranchFilter').value.length == 0) {
        $('buildBranchFilter').value = '+:<default>'; // set default branch as default value
      }

      if (hasNonDefaultBranch) {
        // if selected build configuration has more than one branch, show branch field
        $j('#buildBranchField').show();
        BS.BranchesPopup.attachBuildTypeHandler(selectedId, 'buildBranchFilter', 'branchFilter', 'ALL_BRANCHES');
      } else {
        $j('#buildBranchField').hide();
      }

      BS.VisibilityHandlers.updateVisibility('buildBranchField');
    };

    BS.AdminActions.listBranches(selectedId, showBranchField);

    BS.AvailableParams.setElementCompletionObjId(form.tabStartPage, "settingsId=buildType:" + BS.ProjectReportTabDialog.BuildFinder.findOutBuildTypeExternalId());
  },

  manageArchivedBuildTypes: function(flag) {
    if (flag) {
      $j('#archivedBuildTypes optGroup.subtle').appendTo('#buildTypeId');
    } else {
      $j('#buildTypeId optGroup.subtle').appendTo('#archivedBuildTypes');
    }
    BS.jQueryDropdown($j('#buildTypeId')).ufd("changeOptions");
  }

}));

// Reusing javascript for the same functionality on edit dependencies page.
BS.ProjectReportTabDialog.BuildFinder = OO.extend(BS.EditArtifactDependencies, {
  shouldAttach: function() {
    var that = this;
    that._shouldAttach = true;

    // A quick-fix. The controller is hardcoded to call "BS.EditArtifactDependencies.appendPath()" for tree children.
    BS.EditArtifactDependencies.appendPath = function(path) {
      that.setPath(path);
    };
  },

  attachOnFirstShow: function() {
    if (this._shouldAttach && !this._attached) {
      this.expandNestedArchives = true;
      this.attachPopups('longField', 'projectTabStartPage', 'editProjectReportTab', 'forReportTab=true');
      this._attached = true;
    }
  },

  findOutBuildTypeId: function() {
    return null;
  },

  findOutBuildTypeExternalId: function() {
    var select = $('buildTypeId');
    if (select.selectedIndex < 0) return '';
    return select.options[select.selectedIndex].value;
  }
});

