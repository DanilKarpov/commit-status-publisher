BS.SaveProjectListener = OO.extend(BS.ErrorsAwareListener, {
  onEmptyProjectNameError: function(elem) {
    $("errorName").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
    this.getForm().highlightErrorField($("name"));
  },

  onInvalidProjectNameError: function(elem) {
    $("errorName").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
    this.getForm().highlightErrorField($("name"));
  },

  onProjectRenameFailedError: function(elem) {
    $("errorName").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
    this.getForm().highlightErrorField($("name"));
  },

  onInvalidProjectIdError: function(elem) {
    $("errorExternalId").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
    this.getForm().highlightErrorField($("externalId"));
  },

  onDuplicateProjectIdError: function(elem) {
    $("errorExternalId").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
    this.getForm().highlightErrorField($("externalId"));
  },

  onCyclicDependencyError: function(elem) {
    $("errorExternalId").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
    this.getForm().highlightErrorField($("externalId"));
  },

  onCyclicSnapshotDependencyError: function(elem) {
    $("errorDefaultTemplateId").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
    this.getForm().highlightErrorField($("defaultTemplateId"));
  },

  onInvalidParentProjectError: function(elem) {
    $("errorParent").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
    this.getForm().highlightErrorField($("parentId"));
  },

  onMissingDefaultTemplateError: function(elem) {
    $("errorDefaultTemplateId").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
    this.getForm().highlightErrorField($("defaultTemplateId"));
  },

  onSaveProjectErrorError: function(elem) {
    $("errorName").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
  },

  onProjectNotFoundError: function() {
    BS.reload(true);
  },

  onCompleteSave: function(form, responseXML, err) {
    BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
    if (!err) {
      var externalIdInput = $j("#externalId"),
          originalId = externalIdInput.attr("originalId"),
          newId = externalIdInput.val();
      if (newId != originalId) {
        var currentUrl = window.location.href;
        window.location.href = currentUrl.replace("projectId=" + originalId, "projectId=" + newId)
                                         .replace("projectId%253D" + originalId, "projectId%253D" + newId);
      } else {
        BS.reload(true);
      }
    }
  }
});

BS.CreateProjectForm = OO.extend(BS.AbstractWebForm, {
  submitCreateProject: function() {
    var that = this;

    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.SaveProjectListener, {
      getForm: function() {
        return that;
      },

      onCompleteSave: function(form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
        if (!err) {
          BS.XMLResponse.processRedirect(responseXML);
        }
      }
    }));

    return false;
  }
});


BS.EditProjectForm = OO.extend(BS.AbstractWebForm, {
  originalDefaultTemplateId: "",
  originalEnforcedTemplateId: "",

  formElement: function() {
    return $('editProjectForm');
  },

  setupEventHandlers: function() {
    var that = this;

    this.setUpdateStateHandlers({
      updateState: function() {
        that.saveInSession();
      },
      saveState: function() {
        that.submitProject();
      }
    });
  },

  saveInSession: function() {
    var that = this;
    $("submitProject").value = 'storeInSession';

    BS.FormSaver.save(this, this.formElement().action, BS.StoreInSessionListener);
  },

  submitProject: function() {
    var that = this;
    $("submitProject").value = 'store';
    if (!this.warningMessageIfRequired()) {
      return false;
    }
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.SaveProjectListener, {
      getForm: function() {
        return that;
      }
    }));
            return false;
  },

  warningMessageIfRequired: function() {
    var warningMsg = "";
    if (this.isDefaultTemplateChanged() && $("affectedByDefaultTemplate")) {
      warningMsg = "Changing the default template will affect "
        + $("affectedByDefaultTemplate").value;
    }
    if (this.isEnforcedTemplateChanged() && $("affectedByEnforcedTemplate")) {
      if (warningMsg.length > 0) {
        warningMsg += " and changing "
      } else {
        warningMsg = "Changing "
      }
      warningMsg += "the enforced settings template will affect " + $("affectedByEnforcedTemplate").value;
    }
    if (warningMsg.length > 0) {
      warningMsg += " build configurations. ";
      if (this.isDefaultTemplateChanged() && this.originalDefaultTemplateId != "" || this.isEnforcedTemplateChanged() && this.originalEnforcedTemplateId != "") {
        warningMsg += "Settings from detaching templates won't be inlined to build configurations.";
      }
      if (!confirm(warningMsg)) {
        return false;
      }
    }
    return true;
  },

  initDefaultTemplateId: function() {
    if ($("defaultTemplateId")) {
      this.originalDefaultTemplateId = $("defaultTemplateId").value;
    }
  },

  isDefaultTemplateChanged: function() {
    if (!$("defaultTemplateId")) return false;
    return this.originalDefaultTemplateId != $("defaultTemplateId").value;
  },

  initEnforcedTemplateId: function() {
    if ($("enforcedTemplateId")) {
      this.originalEnforcedTemplateId = $("enforcedTemplateId").value;
    }
  },

  isEnforcedTemplateChanged: function() {
    if (!$("enforcedTemplateId")) return false;
    return this.originalEnforcedTemplateId != $("enforcedTemplateId").value;
  }

});

BS.VcsSettingsForm = OO.extend(BS.PluginPropertiesForm, {
  formElement: function() {
    return $('vcsSettingsForm');
  },

  setupEventHandlers: function() {
    var that = this;

    // Update state handlers should not be stacked: clear the handlers before attaching (TW-30212).
    this.removeUpdateStateHandlers();
    this.doSetUpdateStateHandlers({
      updateState: function() {
        that.saveInSession();
      },

      saveState: function() {
        that.submitVcsSettings(false);
      }
    });

    this.updateCheckingIntervalState();
  },


  updateCheckingIntervalState: function() {

    var customInterval = $('mod-check-interval-specified').checked;

    // Enabled/disable field for setting interval value
    $('modificationCheckInterval').disabled = !customInterval;

    // Show/hide warning that interval is smaller than enforce minimum:
    var warning = $('checkingIntervalWarning');
    if (!warning) {
      // The default interval is not enforced
      return;
    }
    var defaultValue = parseInt(warning.querySelector(".checkingIntervalWarning__default").innerHTML);
    var vcsRootValue = parseInt($('modificationCheckInterval').value);
    if (customInterval && vcsRootValue < defaultValue) {
      warning.show();
    }
    else {
      warning.hide();
    }
  },

  saveInSession: function() {
    $("submitVcsRoot").value = 'storeInSession';

    BS.PasswordFormSaver.save(this, this.formElement().action, BS.StoreInSessionListener, false);
  },

  setSelectedVcs: function(vcsName) {
    if (vcsName == '') return;

    BS.ajaxRequest(this.formElement().action, {
      parameters: "&vcsName=" + vcsName + "&vcsRootId=" + $('vcsRootId').value + "&editingScope=" + $('editingScope').value,
      onComplete: function() {
        $('vcsRootProperties').refresh('chooseVcsTypeProgress');
      }
    });
  },
  /*
  * TODO: `callback` - Temporary solution to handle the case when the user clicks on the "Add connection" button
  * Task: TW-93452 Improve VCS selection on the create Pipeline page, and provide a convenient way to add extra VCS connections.
  */
  submitVcsSettings: function(newSettings, targetSettingsId, callback) {
    var vcsNameSelector = this.formElement().vcsName;
    if (vcsNameSelector.options[vcsNameSelector.selectedIndex].value == '') {
      alert("Please choose a type of the VCS root.");
      vcsNameSelector.focus();
      return false;
    }

    var that = this;
    $("submitVcsRoot").value = 'store';

    var saveOption = this.formElement().saveOption;
    if (saveOption && saveOption.length > 0) {
      var saveOptionChecked = false;
      for (var i=0; i<saveOption.length; i++) {
        if (saveOption[i].checked) {
          saveOptionChecked = true;
          break;
        }
      }

      if (!saveOptionChecked) {
        alert("Please choose corresponding option for applying changes in this VCS root.");
        window.scrollTo(0, document.body.scrollHeight);
        return false;
      }
    }

    this.removeUpdateStateHandlers();
    this.clearErrors();

    BS.PasswordFormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onCompleteSave: function(form, responseXML, err) {
        var wereErrors = BS.XMLResponse.processErrors(responseXML, {
          onProjectNotFoundError: function(elem) {
            alert(elem.firstChild.nodeValue);
            BS.XMLResponse.processRedirect(responseXML);
          },
          onDuplicateVcsRootsFoundError: function(elem) {
            var submitAnywayCallback = function() {
              $('skipDuplicatesCheck').value = true;
              BS.VcsSettingsForm.submitVcsSettings(true);
            };
            var useVcsRootCallback = !targetSettingsId ? null : function(vcsRootId) {
              BS.VcsRootsUtil.attachVcsRoot(targetSettingsId, vcsRootId);
            };

            BS.DuplicateVcsRootsDialog.showDialog(elem.firstChild.nodeValue, useVcsRootCallback, submitAnywayCallback);
          },
          onDuplicateVcsRootNameError: function(elem) {
            this.onInvalidVcsRootNameError(elem);
          },
          onDuplicateVcsRootIdError: function(elem) {
            this.onInvalidVcsRootIdError(elem);
          },
          onInvalidVcsRootNameError: function(elem) {
            $('errorVcsRootName').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
            that.highlightErrorField($('vcsRootName'));
          },
          onInvalidVcsRootIdError: function(elem) {
            $('errorExternalId').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
            that.highlightErrorField($('externalId'));
          },
          onInvalidModificationCheckIntervalError: function(elem) {
            $('invalidModificationCheckInterval').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
            that.highlightErrorField($('modificationCheckInterval'));
          },
          onInvalidBranchSpecError: function(elem) {
            $('error_teamcity:branchSpec').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
          },
          onVcsRootsSaveFailureError: function(elem) {
            alert(elem.firstChild.nodeValue);
          }
        }, that.propertiesErrorsHandler);

        if (wereErrors) {
          form.enable();
          BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
          if (!newSettings) {
            that.setupEventHandlers();
          }

          BS.MultilineProperties.updateVisible();
        } else {
          /*
          * TODO: `callback` - Temporary solution to handle the case when the user clicks on the "Add connection" button
          * Task: TW-93452 Improve VCS selection on the create Pipeline page, and provide a convenient way to add extra VCS connections.
          */
          if (callback) {
            callback();
          } else {
            BS.XMLResponse.processRedirect(responseXML);
          }
        }
      }
    }));

    return false;
  },

  submitTestConnection: function(newSettings, readOnlyMode) {
    var that = this;
    $("submitVcsRoot").value = 'testConnection';

    this.removeUpdateStateHandlers();
    this.clearErrors();

    BS.PasswordFormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onFailedTestConnectionError: function(elem) {
        var text = "";
        if (elem.firstChild) {
          text = elem.firstChild.nodeValue;
        }

        BS.TestConnectionDialog.show(false, text, $('testConnectionButton'));
      },

      onCompleteSave: function(form, responseXML, err) {
        var wereErrors = BS.XMLResponse.processErrors(responseXML, {}, that.propertiesErrorsHandler);
        if (!wereErrors) {
          var additionalInfo = "";
          var testConnectionResultNodes = responseXML.documentElement.getElementsByTagName("testConnectionResult");
          if (testConnectionResultNodes && testConnectionResultNodes.length > 0) {
            var testConnectionResult = testConnectionResultNodes.item(0);
            if (testConnectionResult.firstChild) {
              additionalInfo = testConnectionResult.firstChild.nodeValue;
            }
          }

          BS.TestConnectionDialog.show(true, additionalInfo, $('testConnectionButton'));
        }

        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, false);
        if (!readOnlyMode) form.enable();
        if (!newSettings && !readOnlyMode) {
          that.setupEventHandlers();
        }

        BS.MultilineProperties.updateVisible();
      }
    }));

    return false;
  }
});

BS.DuplicateVcsRootsDialog = OO.extend(BS.AbstractModalDialog, {
  getContainer: function() {
    return $('duplicateVcsRootsDialog');
  },

  showDialog: function(rootIds, useButtonCallback, submitAnywayCallbak) {
    this._useSelectedVcsRoot = function(vcsRootId) {
      this.close();
      if (useButtonCallback) {
        useButtonCallback(vcsRootId);
      }
    };

    this._submitAnyway = function() {
      this.close();
      if (submitAnywayCallbak) {
        submitAnywayCallbak();
      }
    };

    BS.ajaxUpdater($('duplicateVcsRootsContainer'), window['base_uri'] + "/admin/duplicateVcsRoots.html", {
      parameters: "rootIds=" + rootIds +
                  '&showUseButton=' + (useButtonCallback != null) +
                  "&cameFromUrl=" + encodeURIComponent(document.location.pathname + '?' + document.location.search),
      evalScripts: true
    });
    this.showCentered();
  },

  _submitAnyway: function() {
  },

  _useSelectedVcsRoot: function(vcsRootId) {
  }
});

BS.EditProjectTab = {
  initReorderModalDialogs: function(projectExtId) {
    function initReorderDialog(id, actionName, sortableId) {
      var $dialog = $j("#" + id);
      if ($dialog.length > 0) {
        var $sortableList = $dialog.find(sortableId);

        var form = BS.createReorderDialog(id, $sortableList, function (order) {
          form.setDisabled(true);
          BS.ajaxRequest(window["base_uri"] + "/admin/editProject.html", {
            parameters: {
              action: actionName,
              order: order,
              projectId: projectExtId
            },
            method: "POST",
            onComplete: function () {
              form.setDisabled(false);
              form.close();
              BS.reload();
            }
          });
        });
        $dialog.bind("closeDialog", function() {
          form.resetState();
        });
        $dialog.find(".resetOrder").bind("click", function() {
          form.resetState();
          BS.ajaxRequest(window["base_uri"] + "/admin/editProject.html", {
            parameters: {
              action: actionName,
              order: "", // empty order means alphabetical order
              projectId: projectExtId
            },
            method: "POST",
            onComplete: function () {
              form.close();
              BS.reload();
            }
          });
        });
        return form;
      } else {
        return false;
      }
    }

    var reorderBuildTypesDialog = initReorderDialog("reorderBuildTypesDialog", "setBuildtypesOrder", "#sortableList");
    if (reorderBuildTypesDialog) {
      $j("#sp_span_prjActionsContent ul").append("<li><a href='#' id='reorderBuildTypesButton'>Reorder build configurations...</a></li>");
      $j("#reorderBuildTypesButton").bind("click", function () {
        reorderBuildTypesDialog.showCentered();
      });
      $j("#editBuildTypesOrder").on("click", function() {
        reorderBuildTypesDialog.showCentered();
      });
    }
    var reorderProjectsDialog = initReorderDialog("reorderProjectsDialog", "setSubprojectsOrder", "#sortableList");
    if (reorderProjectsDialog) {
      $j("#sp_span_prjActionsContent ul").append("<li><a href='#' id='reorderProjectsButton'>Reorder projects...</a></li>");
      $j("#reorderProjectsButton").bind("click", function () {
        reorderProjectsDialog.showCentered();
      });
      $j("#editProjectsOrder").on("click", function() {
        reorderProjectsDialog.showCentered();
      });
    }
  }
};
