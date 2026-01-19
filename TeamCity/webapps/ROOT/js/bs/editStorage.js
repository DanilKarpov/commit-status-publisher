BS.EditStorageForm = OO.extend(BS.PluginPropertiesForm, {
  formElement: function () {
    return $('editStorageForm');
  },

  confirmSave: function () {
    BS.editStorageDialog.showCentered();
    return false;
  },

  save: function () {
    var that = this;
    let storageType = $("storageType").value;
    let submitUrl = this.formElement().action + "&storageType=" + storageType;
    let storageSettingsId = $("storageSettingsId").value;
    let url = new URL(submitUrl);
    const isNewStorage = url.searchParams.get("newStorage");
    if (isNewStorage === 'true') {
      url.searchParams.delete("storageSettingsId");
      url.searchParams.set("storageSettingsId", storageSettingsId);
    }
    submitUrl = url.toString();

    BS.PasswordFormSaver.save(this, submitUrl, OO.extend(BS.ErrorsAwareListener, {
      onCompleteSave: function (form, responseXML, err) {
        var wereErrors = BS.XMLResponse.processErrors(responseXML, {}, that.propertiesErrorsHandler);

        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
        if (wereErrors) {
          BS.Util.reenableForm(that.formElement());
          BS.editStorageDialog.close();
          return;
        }
        form.close();
      },

      onSuccessfulSave: function () {
        document.location.href = window['base_uri'] + "/admin/editProject.html?projectId="+ $j('#projectId').val() +"&tab=artifactsStorage";
      }
    }));
    return false;
  },

  close: function () {
    document.location.href = window['base_uri'] + "/admin/editProject.html?projectId="+ $j('#projectId').val() +"&tab=artifactsStorage";
  }
});


BS.StorageSettings = {
  remove: function (settingsId) {
    this.doAction(settingsId, "remove");
  },

  setActive : function (settingsId) {
    this.doAction(settingsId, "setActive");
  },

  deactivate : function (settingsId) {
    this.doAction(settingsId, "deactivate");
  },

  showResetDialog : function (settingsId) {
    BS.resetStorageDialog.showFor(settingsId);
  },

  showDeleteDialog : function (settingsId, storageDescription, usages) {
    BS.deleteStorageDialog.showFor(settingsId, storageDescription, usages);
  },

  showUsagesDialog : function (settingsName, settingsId) {
    BS.storageUsagesDialog.show($j('#projectId').val(), settingsName, settingsId);
  },

  doAction: function (settingsId, action) {
    BS.ajaxRequest(window['base_uri'] + "/admin/storageSettings.html", {
      method: "post",
      parameters: Object.toQueryString(
          {
            projectId: $j('#projectId').val(),
            storageSettingsId: settingsId,
            action: action
          }),

      onComplete: function (transport) {
        $("storageSettingsList").refresh();
      }
    })
  }
};

BS.resetStorageDialog = OO.extend(BS.AbstractModalDialog, {
  settingsId: '',

  getContainer: function () {
    return $('resetConfirmation');
  },

  showFor: function (settingsId) {
    this.settingsId = settingsId;
    this.showCentered();
  },

  reset: function () {
    BS.StorageSettings.deactivate(this.settingsId);
    this.close();
  }
});

BS.deleteStorageDialog = OO.extend(BS.AbstractModalDialog, {
  settingsId: "",

  getContainer: function () {
    return $('deleteConfirmation');
  },

  showFor: function (settingsId, storageDescription, usages) {
    var span = $j('#deleteConfirmationText');
    span.html("You are going to remove " + BS.Util.escape(storageDescription) +
              (usages > 0 ?
                ", that has been used by at least <a href=\"\" onclick=\"BS.StorageSettings.showUsagesDialog('" + BS.Util.escape(storageDescription) + "', '" + settingsId + "'); return false;\">" + usages + " build(s).</a><br/>" +
                "If there are artifact dependencies on these builds, this may result in artifact dependency resolution failure." :
                "."));
    this.settingsId = settingsId;
    this.showCentered();
  },

  delete: function () {
    BS.StorageSettings.remove(this.settingsId);
    this.close();
  }
});

BS.editStorageDialog = OO.extend(BS.AbstractModalDialog, {
  getContainer: function () {
    return $('editConfirmation');
  }
});

BS.storageUsagesDialog = OO.extend(BS.AbstractModalDialog, {
  getContainer: function () {
    return $('showSettingsUsages');
  },

  show: function(projectId, settingsName, settingsId) {
    var showUsagesContainer = $("showSettingsUsagesInner");
    var loadingIndicator = $("showSettingsUsagesLoading");
    BS.Util.hide(showUsagesContainer);
    BS.Util.show(loadingIndicator);

    $j('#showSettingsUsagesTitle').text('Show Usages of ' + settingsName);

    this.showCentered();
    BS.ajaxUpdater(showUsagesContainer, window['base_uri'] + "/storageSettingsUsages.html", {
      method: 'get',
      evalScripts: true,
      parameters : {
        projectId : projectId,
        settingsId : settingsId
      },
      onComplete: function() {
        BS.Util.hide(loadingIndicator);
        BS.Util.show(showUsagesContainer);
      }
    });
    return false;
  }
});
