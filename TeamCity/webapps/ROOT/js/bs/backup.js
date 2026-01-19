BS.BackupRunForm = OO.extend(BS.AbstractWebForm, {
  _backupStarted: false,
  _inited: false,
  _canStartBackup: false,

  init2: function(canStartBackup, currentPreset) {

    this._canStartBackup = typeof canStartBackup !== 'undefined' ? canStartBackup : false;

    var initialPreset = currentPreset;
    if (initialPreset == null || initialPreset == '')
      initialPreset = 'DCU';
    $('settings.preset').setValue(initialPreset);

    this.refreshPresetPanels();
    this._inited = true;

    if (this._canStartBackup) {
      this.updateButtonStatusPeriodically();
    }
  },

  formElement: function() {
    return $('BackupRunForm');
  },

  savingIndicator: function() {
    return $('startBackup');
  },

  justModified: function() {
    this.updateButtonStatus();
  },

  updateButtonStatus: function() {
    if (this._canStartBackup) {
      var scopeSelected = $("settings.customIncludeConfiguration").checked ||
                          $("settings.customIncludeDatabase").checked ||
                          $("settings.customIncludeBuildLogs").checked ||
                          $("settings.customIncludePersonalChanges").checked ||
                          $("settings.preset").value == "DCU" ||
                          $("settings.preset").value == "DCULP";

      $("settings.preset").disabled = false;
      var fileNameSelected = $("settings.fileName").value.length > 0;
      $("submitStartBackup").disabled = !(scopeSelected && fileNameSelected);
    }
  },

  updateButtonStatusPeriodically: function() {
    var that = this;
    this.updateButtonStatus();
    setTimeout(function() {
      that.updateButtonStatusPeriodically()
    }, 250);
  },

  doSubmitStart: function() {
    $("submitStartBackup").disabled = true;
    // this.formElement().backupAction.value = "start";
    this.doSubmit();
  },

  doSubmitStop: function() {
    var toStop = confirm("Stop the running backup process?\nOK - stop, Cancel - continue backup");
    if (toStop) {
      // this.formElement().backupAction.value = "cancel";
      this.doSubmit();
    }
    return toStop;
  },

  doSubmit: function() {
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onSuccessfulSave: function() {
        BS.reload(true);
      },
      onFileNameError: function(elem) {
        $j('#fileNameError').text(elem.firstChild.nodeValue);
      },
      onArchiveFileIsOutsideOfBackupDirectoryError: function(elem) {
        $j('#fileNameError').text(elem.firstChild.nodeValue);
      },
      onUnexpectedError: function(elem) {
        $j('#unexpectedError').text("Something goes wrong:\n" +
                                    elem.firstChild.nodeValue);
      }
    }));
  },

  backupInProgress: function() {
    this._backupStarted = true;
    window.setTimeout(function() {
      $('backupProgress').refresh();
    }, 5000);
  },

  backupStopped: function() {
    if (this._backupStarted) {
      window.setTimeout(function() {
        BS.reload(true);
      }, 800);
    }
  },

  refreshPresetPanels: function() {
    var curPreset = $('settings.preset').value;
    if (!this._inited) {
      $('settings.preset').setValue(curPreset);
    }

    if (curPreset == "DCU") jQuery("#noteForPresetCD").removeClass("hidden"); else jQuery("#noteForPresetCD").addClass("hidden");
    if (curPreset == "DCULP") jQuery("#noteForPresetCDLP").removeClass("hidden"); else jQuery("#noteForPresetCDLP").addClass("hidden");
    if (curPreset == "X") jQuery("#customScopeCheckBoxes").removeClass("hidden"); else jQuery("#customScopeCheckBoxes").addClass("hidden");
    this.updateButtonStatus();
  }
});