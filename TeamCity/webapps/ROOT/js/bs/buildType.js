BS.BuildType = {};
BS.BuildType.updateView = function () {
  BS.reload(false, function () {
    var containerId = 'buildConfigurationContainer';
    BS.Util.runWithElement(containerId, function(isElementPresent) {
      if (!isElementPresent) {
        throw new Error(containerId + ' is not found');
      } else {
        $(containerId).refresh(null, 'allTags=' + $j('#all-tags-switch').prop('checked'));
      }
    }, 5000);
  });
};
BS.BuildType.updateStatus = function (failed) {
  jQuery("#restNavigation").children(".buildType").toggleClass("failed", failed);
};

BS.BuildTypeResetSources = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  formElement: function () {
    return $('resetSources');
  },

  getContainer: function () {
    return $('resetSourcesDialog');
  },

  savingIndicator: function () {
    return $('resetSourcesProgress');
  },

  showResetSourcesDialog: function (noReload) {
    this.noReload = noReload;
    this.showCentered();
    this.bindCtrlEnterHandler(this.submitResetSources.bind(this));

    $('cleanSourcesDialogContent').refresh('cleanSourcesProgress', 'showCleanSourcesDialog=1', function() {
      BS.BuildTypeResetSources.recenterDialog();
    });

    return new Promise(function (resolve, reject) {
      this._resolve = resolve;
      this._reject = reject;
    }.bind(this));
  },

  submitResetSources: function () {
    if (this.formElement().agentId.selectedIndex == -1) {
      alert('Please choose an agent.');
      return false;
    }

    var that = this;
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onCompleteSave: function (form, responseXML, err) {
        that.setSaving(false);
        that.enable();
        if (!err) {
          that.close();
          if (!that.noReload) {
            BS.reload(true);
          }
          if (that._resolve != null) {
            that._resolve({alert: 'Build configuration sources will be cleaned upon the next build startup.'});
          }
        }
      }
    }));

    return false;
  }
}));

BS.PauseBuildTypeDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  formElement: function () {
    return $('pauseBuildTypeForm');
  },

  getContainer: function () {
    return $('pauseBuildTypeFormDialog');
  },

  onText: "Pause",
  offText: "Activate",

  showPauseBuildTypeDialog: function (buildTypeId, pause, hasPermissions, defaultMessage, noReload) {
    this.noReload = this.formElement().noRedirect.value = noReload;
    if (BS.bcActions_handle != null) {
      BS.bcActions_handle.hidePopup(0);
    }

    var text = pause ? this.onText : this.offText;

    if (pause) {
      $j('#removeFromQueue').attr('checked', hasPermissions);
      if (hasPermissions) {
        BS.Util.show('removeFromQueueDiv')
      } else {
        BS.Util.hide('removeFromQueueDiv')
      }
      // hide option to remove builds from queue in case of resuming
      BS.Util.show('pauseNote');
    } else {
      BS.Util.hide('pauseNote');
      BS.Util.hide('removeFromQueueDiv')
    }

    this.formElement().pause.value = pause;
    this.formElement().pauseBuildType.value = buildTypeId;
    this.formElement().PauseSubmitButton.value = text;
    $('pauseBuildTypeFormTitle').innerHTML = text + ' build configuration';

    this.formElement().pauseComment.value =
    defaultMessage != null && defaultMessage.length > 0 ? defaultMessage : this.formElement().pauseComment.defaultValue;

    this.showCentered();
    this.formElement().pauseComment.focus();
    this.formElement().pauseComment.select();

    this.bindCtrlEnterHandler(this.submit.bind(this));

    return new Promise(function (resolve, reject) {
      this._resolve = resolve;
      this._reject = reject;
    }.bind(this));
  },

  submit: function () {
    if (this.formElement().pauseComment.value == this.formElement().pauseComment.defaultValue) {
      this.formElement().pauseComment.value = "";
    }

    BS.Util.show('pauseProgressIcon');

    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onCompleteSave: function (form, responseXML, err) {
        form.enable();
        BS.Util.hide('pauseProgressIcon');
        if (!this.noReload) {
          BS.reload(true);
        } else {
          this.close();
        }
        if (this._resolve != null) {
          this._resolve();
        }
      }.bind(this),

      onFailure: function () {
        BS.Util.hide('pauseProgressIcon');
        alert("Problem accessing server");
      }
    }), false, this.noReload);

    return false;
  }
}));

