BS.Agent = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  formElement: function() {
    return $(this.actionCode);
  },

  getContainer: function() {
    return $(this.actionCode + 'Dialog');
  },

  savingIndicator: function () {
    return $('changeAuthorizeStatusProgress');
  },

  actionCode: 'changeAgentStatus',
  onText: "Enable",
  offText: "Disable",
  suffix: "",

  showChangeStatusDialog: function(enable, id, registered, actionCode, poolOptions, updateStatus) {
    this.updateStatus = updateStatus || function() {
      if (actionCode == 'changeAuthorizeStatus') {
        BS.reload(true);
      }
      else if ($('agentsList')) { // on agent list pages
        $('agentsList').refresh();
      }
      else {
        $('agentStatus:' + id).refresh();
      }
    };

    // action code may be changeAuthorizeStatus as well
    this.actionCode = actionCode;
    if (actionCode == 'changeAuthorizeStatus') {
      this.onText = 'Authorize';
      this.offText = 'Unauthorize';
      this.suffix = '';

      poolOptions = poolOptions || {};
      var agentPoolId = poolOptions.poolId,
          isCloud = poolOptions.cloud,
          chooserDiv = $('agent_pool_chooser_div');

      if (chooserDiv) {
        chooserDiv.style.display = (enable && !isCloud) ? 'block' : 'none';
        if (agentPoolId != undefined) {
          var elId = "#agent_pool_chooser_div option";
          $j(elId).each(function() {
            var self = $j(this);
            self.prop("selected", self.val() == agentPoolId);
          });
          $j(elId).trigger('change');
        }
      }
    }
    if (actionCode == 'changeAgentStatus') {
      this.onText = 'Enable';
      this.offText = 'Disable';
      this.suffix = '';
      if (poolOptions && poolOptions.cloud) {
        this.suffix = ' for maintenance';
      }
      $('should_restore_status').checked = false;
      $('status_restoring_delay').value = 15;
      $('status_restoring_delay').disabled = true;
      if (enable) {
        $('should_restore_status_label').innerHTML = "Disable agent" +  this.suffix +" automatically in";
      } else {
        $('should_restore_status_label').innerHTML = "Enable agent automatically in";
      }
    }

    this.formElement().elements[this.actionCode].value = id;
    this.formElement().enable.value = enable;


    BS.Util.hide('disconnectedDisabledWarning');
    BS.Util.hide('disconnectedEnabledWarning');

    $(this.actionCode + 'SubmitButton').value = enable ? this.onText : `${this.offText} ${this.suffix}`;
    $(this.actionCode + 'Title').innerHTML = enable ? this.onText : `${this.offText} ${this.suffix}`;

    // Special case for enable/disable messages, possibly TODO
    if ('changeAgentStatus' == this.actionCode) {
      if (enable) {
        if (!registered) {
          BS.Util.show('disconnectedDisabledWarning');
        }
      } else {
        if (!registered) {
          BS.Util.show('disconnectedEnabledWarning');
        }
      }
    }

    this.formElement().reason.value = this.formElement().reason.defaultValue;

    this.showAtFixed($(this.getContainer()));

    this.formElement().reason.focus();
    this.formElement().reason.select();

    this.bindCtrlEnterHandler(this.submitChangeStatus.bind(this));
  },

  submitChangeStatus: function() {
    var that = this;
    if (this.formElement().reason.value == this.formElement().reason.defaultValue) {
      this.formElement().reason.value = "";
    }

    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onLicenseNotGrantedError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },

      onNoSuchPoolError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },

      onPoolQuotaExceededError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },

      onCompleteSave: function(form, responseXML, err) {
        that.setSaving(false);
        that.enable();
        if (!err) {
          that.close();
          that.updateStatus();
        }
      }
    }));

    return false;
  },

  scheduleRefresh: function() {
    if (!this._scheduled) {
      this._scheduled = true;
      this.refreshIfPossible();
    }
  },

  refreshIfPossible: function() {
    if (BS.canReload()) {
      this._scheduled = false;
      $('agentsList').refresh();
    } else {
      setTimeout(function() {
        BS.Agent.refreshIfPossible();
      }, 1000);
    }
  }
}));

BS.RemoveAgent = OO.extend(BS.AbstractWebForm, {
  formElement: function() {
    return $("removeAgentForm");
  },

  remove: function(runsBuild) {
    if (!confirm((runsBuild ?
                  "This agent ran a build when it became disconnected.\n" +
                  "The build will be canceled on server if you choose to remove this agent.\n" +
                  "Are you sure you want to continue?" :
                  "Are you sure you want to remove this agent?"))) return false;

    var that = this;
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onAgentCannotBeRemovedError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },

      onCompleteSave: function(form, responseXML, err) {
        that.setSaving(false);
        that.enable();
        if (!err) {
          BS.XMLResponse.processRedirect(responseXML);
        }
      }
    }));

    return false;
  }
});

BS.AgentResetSources = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  formElement: function() {
    return $('resetSources');
  },

  getContainer: function() {
    return $('resetSourcesDialog');
  },

  savingIndicator: function() {
    return $('resetSourcesProgress');
  },

  showResetSourcesDialog: function() {
    this.showCentered();
    this.bindCtrlEnterHandler(this.submitResetSources.bind(this));
    $('cleanSourcesDialogContent').refresh('cleanSourcesProgress', 'showCleanSourcesDialog=1', function() {
      BS.AgentResetSources.recenterDialog();
    });
  },

  submitResetSources: function() {
    if (this.formElement().buildTypeId.selectedIndex == -1) {
      alert("Please choose a build configuration.");
      return false;
    }

    var that = this;
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onCompleteSave: function(form, responseXML, err) {
        that.setSaving(false);
        that.enable();
        if (!err) {
          that.close();
          BS.reload();
        }
      }
    }));

    return false;
  }
}));

BS.AgentRunPolicy = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  showAll: false,

  refreshAgentCompatibilityTable: function(afterComplete) {
    $('agentCompatibilityTableRefreshable').refresh(null, this.showAll ? "showAll=true" : "", afterComplete);
  },

  setupEventHandlers: function() {
    var that = this;
    this.setUpdateStateHandlers({
      updateState: function() {
        //do nothing
      },
      saveState: function() {
        that.save();
      }
    });
  },

  save: function() {
    var modifiedMessageForm = $('modifiedMessageForm');
    if (modifiedMessageForm) {
      modifiedMessageForm.disable();
    }
    this.disable();
    var btIds = this._getCheckedBuildTypeIds();
    var that = this;
    this._excludeBuildTypesFromAllowed($('agentTypeId').value, btIds, function() {
      BS.AgentRunPolicy.refreshAgentCompatibilityTable(function() {
        that.enable();
        that.setModified(false);
        BS.unblockRefresh();
      });
    });
  },

  selectProject: function(checked, projectId) {
    var checkboxes = $j('#content-' + projectId).find('[type="checkbox"]');
    checkboxes.each(function() {
      this.checked = checked;
      $j(this).parent().change();
    });
    this.setModifiedMaybe();
  },

  selectBuildType: function(compatible, active) {
    var suffix = active ? "" : "Inactive";
    var name = (compatible) ? "#toggleAllCompatible" + suffix : "#toggleAllIncompatible" + suffix;
    $j(name).prop("checked", false);
    this.setModifiedMaybe();
  },

  setModifiedMaybe: function() {
    var anythingChecked = this._getCheckedBuildTypeIds().length > 0;
    if (anythingChecked) {
      BS.blockRefreshPermanently();
    } else {
      BS.unblockRefresh();
    }
    this.setModified(anythingChecked);
  },

  setSaving: function(saving, callback, errorMessage) {
    if (saving) {
      BS.Util.hide('errors');
      BS.Util.hide('dataSaved');
      BS.Util.show('savingData');
    } else {
      var that = this;
      clearTimeout(this._tid1);
      clearTimeout(this._tid2);
      this._tid1 = window.setTimeout(function() {
        BS.Util.hide('savingData');
        if (errorMessage) {
          $("errors").innerHTML = errorMessage;
          BS.Util.show("errors");
          if (callback) {
            callback();
          }
        } else {
          BS.Util.show("dataSaved");
          if (callback) {
            callback();
          }
        }
      }, 500);
    }
  },

  onPolicyChange: function(agentTypeId, policyName) {
    var that = this;
    this.setSaving(true);
    BS.ajaxRequest(window['base_uri'] + "/agentDetails.html", {
      parameters: "policy=" + policyName + "&agentTypeId=" + agentTypeId,
      onComplete: function() {
        that.setSaving(false);
        BS.reload(true);
      }
    });
  },

  toggle: function (select, form, checkboxName) {
    if (select) {
      this.selectAll(form, checkboxName);
    } else {
      this.unselectAll(form, checkboxName);
    }
  },

  selectAll: function(form, checkboxName) {
    if (!this._isSaveInProgress()) {
      this._setChecked(form, checkboxName, true);
      this.setModifiedMaybe();
    }
  },

  unselectAll: function(form, checkboxName) {
    if (!this._isSaveInProgress()) {
      this._setChecked(form, checkboxName, false);
      this.setModifiedMaybe();
    }
  },

  _isSaveInProgress: function() {
    return this._formDisabled;
  },

  _getAllBuildTypeCheckboxes: function() {
    var checkboxes = [];
    $j("td.compatible, td.incompatible").each(function() {
      checkboxes = checkboxes.concat($j(this).find('input[type="checkbox"][name^="canRun"]').get());
    });

    return checkboxes;
  },

  _getCheckedBuildTypeIds: function() {
    var checkboxes = this._getAllBuildTypeCheckboxes();
    var btIds = [];
    for (var i = 0; i < checkboxes.length; i++) {
      if (checkboxes[i].checked) {
        btIds.push(checkboxes[i].value);
      }
    }
    return btIds;
  },

  _excludeBuildTypesFromAllowed: function(agentTypeId, buildTypeIds, callback) {
    var buildTypesParam = "";
    for (var i=0; i<buildTypeIds.length; i++) {
      buildTypesParam += "&buildTypeId=" + buildTypeIds[i];
    }
    this.setSaving(true);
    var that = this;
    BS.ajaxRequest(window['base_uri'] + "/agentDetails.html", {
      parameters: "agentTypeId=" + agentTypeId + buildTypesParam + "&excludeBuildTypesFromAllowed=true",
      onComplete: function() {
        that.setSaving(false, callback);
      }
    });
  },

  _setChecked: function(form, checkboxName, checked) {
    var i, checkbox;

    function set(checkbox) {
      checkbox = $j(checkbox);
      checkbox.prop('checked', checked);
      checkbox.parent().change();
    }

    var checkboxes = Form.getInputs(form, "checkbox", checkboxName);
    var projectCheckboxes = Form.getInputs(form, "checkbox", checkboxName == 'canRunCompatible' ? 'project-compatible' : 'project-incompatible');

    for (i=0; i<checkboxes.length; i++) set(checkboxes[i]);
    for (i=0; i<projectCheckboxes.length; i++) set(projectCheckboxes[i]);
  }
}));

BS.AgentSelectConfigurationsDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {

  getContainer: function() {
    return $('agentSelectConfigurationsDialog');
  },

  show: function() {
    var agentTypeId = this.formElement().agentTypeId.value;
    var that = this;
    if (BS.AgentRunPolicy.modified) {
      if (confirm("Discard your changes?")) {
        var runConfigurationForm = $('runConfigurationForm');
        BS.AgentRunPolicy.unselectAll(runConfigurationForm, 'toggleAllCompatible');
        BS.AgentRunPolicy.unselectAll(runConfigurationForm, 'toggleAllCompatibleInactive');
        BS.AgentRunPolicy.unselectAll(runConfigurationForm, 'toggleAllIncompatible');
        BS.AgentRunPolicy.unselectAll(runConfigurationForm, 'toggleAllIncompatibleInactive');
        BS.AgentRunPolicy.unselectAll(runConfigurationForm, 'canRunCompatible');
        BS.AgentRunPolicy.unselectAll(runConfigurationForm, 'canRunCompatibleInactive');
        BS.AgentRunPolicy.unselectAll(runConfigurationForm, 'canRunIncompatible');
        BS.AgentRunPolicy.unselectAll(runConfigurationForm, 'canRunIncompatibleInactive');
      } else {
        return false;
      }
    }
    $('agentSelectConfigurationsContainer').refresh(null, "mode=showFirst&agentTypeId=" + agentTypeId, function() {
      that.showCentered();
      that.focusOnSearchField();
      that.bindCtrlEnterHandler(that.submit.bind(that));
    });
    return false;
  },

  formElement: function() {
    return $('agentSelectConfigurations');
  },

  focusOnSearchField: function() {
    Form.focusFirstElement(this.formElement());
  },

  filterConfigurations: function() {
    var findProgress = $('findProgress');

    findProgress.show();
    var requestParameters = "mode=filter&agentTypeId=" + encodeURIComponent(this.formElement().agentTypeId.value) +
                            "&searchString=" + encodeURIComponent(this.formElement().searchString.value);
    $('configurationListRefreshable').refresh(null, requestParameters, function() {
      findProgress.hide();
    });
    return false;
  },

  showAllConfigurations: function() {
    var findProgress = $('findProgress');

    findProgress.show();

    var selectedConfigurations = "";
    var checkboxes = $j(BS.Util.escapeId(this.formElement().id)).find('input[type="checkbox"]');

    checkboxes.each(function() {
      if (this.checked) {
        selectedConfigurations += "&selectedConfigurations=" + this.value;
      }
    });

    var requestParameters = "mode=showAll&agentTypeId=" + encodeURIComponent(this.formElement().agentTypeId.value) + selectedConfigurations;
    $('configurationListRefreshable').refresh(null, requestParameters, function() {
      findProgress.hide();
    });
    return false;
  },

  selectBuildType: function(trId, checked) {
    $('selectAll').checked = false;
    this.changeRowColor(trId, checked);
  },

  changeRowColor: function(trId, checked) {
    var tr = $(trId);

    if (checked) {
      tr.removeClassName("unchecked");
      tr.addClassName("checked");
    } else {
      tr.removeClassName("checked");
      tr.addClassName("unchecked");
    }
  },

  submit: function() {
    var that = this;
    var addProgress = $('addProgress');

    addProgress.show();
    BS.AgentRunPolicy.setSaving(true);
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onAgentNotFoundError: function(xml) {
        BS.AgentRunPolicy.setSaving(false, null, xml.firstChild.nodeValue);
        addProgress.hide();
        that.enable();
        that.close();
      },

      onSuccessfulSave: function() {
        BS.AgentRunPolicy.setSaving(false);
        BS.AgentRunPolicy.refreshAgentCompatibilityTable();
        addProgress.hide();
        that.enable();
        that.close();
      }
    }));
    return false;
  },

  selectAll: function(select) {
    if (select) {
      BS.Util.selectAll(this.formElement(), "selectedConfigurations");
    } else {
      BS.Util.unselectAll(this.formElement(), "selectedConfigurations");
    }

    var that = this;
    $j("tr[id^='dialog-configuration-row']").each(function() {
      that.changeRowColor(this.id, select);
    });
  },

  closeAndRefresh: function() {
    this.close();
    BS.reload(true);
  }

}));
