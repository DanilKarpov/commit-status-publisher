BS.ProjectsImport = {

  actionUrl: function() {
    return window['base_uri'] + '/admin/projectsImport.html';
  },

  refreshPage: function(progressIndicator) {
    $('importProjects').refresh(progressIndicator);
  },

  scheduleRefresh: function () {
    window.setTimeout(function () {
      var scrollAtBottom = BS.ScrollUtil.isScrollAtBottom(100);
      $('importProjects').refresh(null, null, function() {
        if (scrollAtBottom) {
          BS.ScrollUtil.scrollToBottom();
        }
      });
    }, 3000);
  },

  cancelCurrentTask: function () {
    BS.ajaxRequest(this.actionUrl(), {
      method: "post",
      parameters: "cancelCurrentImportTask=true",
      onComplete: function() {
        BS.reload(true);
      }
    });
    return false;
  }
};

BS.ProjectsImport.UploadArchiveDialog =  OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, OO.extend(BS.FileBrowse, {
  getContainer: function () {
    return $('uploadImportedArchiveDialog');
  },

  formElement: function () {
    return $('uploadImportedArchiveForm');
  },

  refresh: function() {
    BS.Util.setParamsInHash(['fileName', $j('#fileName').val()], '&', false);
    BS.ProjectsImport.refreshPage();
  },

  savingIndicator: function() {
    return $j('#uploadingProgress');
  },

  /**
   * Will validate on server
   */
  validate: function() {
    this.setSaving(true);
    return true;
  }
})));

BS.ProjectsImport.SelectArchiveForm = OO.extend(BS.AbstractWebForm, {

  formElement: function () {
    return $('selectArchiveForm')
  },

  init: function() {
    var preselectedFileName = BS.Util.paramsFromHash("&")["fileName"];
    if (preselectedFileName) {
      $j('#archiveSelector > option').each(function() {
        if (this.text === preselectedFileName) {
          $('archiveSelector').setSelectValue(this.value);
        }
      });
    }
    this.archiveSelectorChange();
  },

  archiveSelectorChange: function() {
    if ($('archiveSelector')) {
      if ($('archiveSelector').selectedIndex === 0 || BS.ProjectsImport.SelectArchiveForm.formElement().dataset.importDisabled == "true") {
        $('submitArchiveButton').disable();
      } else {
        $('submitArchiveButton').enable();
      }
    }
  },

  submit: function () {
    BS.FormSaver.save(this, BS.ProjectsImport.actionUrl(), OO.extend(BS.SimpleListener, {

      onBeginSave: function(form) {
        form.disable();
        BS.Util.show('selectArchiveProgress');
      },

      projectImportUnexpectedError: function(elem) {
        $('projectImportUnexpectedError').innerHTML = elem.firstChild.nodeValue;
      },

      archiveVersionMismatchError: function(elem) {
        $('archiveVersionMismatchError').innerHTML = elem.firstChild.nodeValue;
      },

      invalidArchiveError: function(elem) {
        $('invalidArchiveError').innerHTML = elem.firstChild.nodeValue;
      },

      onCompleteSave: function (form, responseXml, hasErrors) {
        if (hasErrors) {
          form.enable();
          BS.Util.hide('selectArchiveProgress');
        } else {
          BS.ProjectsImport.refreshPage('selectArchiveProgress');
        }
      }
    }));
    return false;
  }
});

BS.ProjectsImport.ConfigureImportForm = OO.extend(BS.AbstractWebForm, {

  formElement: function () {
    return $('configureImportForm')
  },

  submit: function () {
    BS.FormSaver.save(this, BS.ProjectsImport.actionUrl(), OO.extend(BS.ErrorsAwareListener, {

      projectImportUnexpectedError: function(elem) {
        $('projectImportUnexpectedError').innerHTML = elem.firstChild.nodeValue;
      },

      onSuccessfulSave: function () {
        BS.ProjectsImport.refreshPage();
      }
    }));
    return false;
  },

  savingIndicator: function() {
    return $j('#startImportProgress');
  },

  scopeChanged: function() {
    var includeConfigsChecked = $('includeConfigs').checked;

    if (BS.ProjectsImport.ConfigureImportForm._dbDumpAvailable) {
      if (!includeConfigsChecked) {
        BS.ProjectsImport.ConfigureImportForm._disableCheckbox('includeBuildsData', "Build data can't be imported without projects configs")
      } else {
        BS.ProjectsImport.ConfigureImportForm._enableCheckbox('includeBuildsData');
      }
    }

    var projectsChecked = $j("#projectSelect :input:checked").length >= 1;
    var usersOrGroupsChecked = $('importNewUsers').checked ||
                               $('importConflictingUsersWithDifferentEmail').checked ||
                               $('importConflictingUsersWithSameVerifiedEmail').checked ||
                               $('importConflictingUsersWithSameNotVerifiedEmail').checked ||
                               $('importNewGroups').checked ||
                               $('mergeExistingGroups').checked;

    if ((includeConfigsChecked && projectsChecked) || (!includeConfigsChecked && usersOrGroupsChecked)) {
      $('startImportButton').enable()
    } else {
      $('startImportButton').disable()
    }
  },

  init: function(dbDumpAvailable, configsAvailable, conflictingUsersWithSameVerifiedEmailCount, conflictingUsersWithSameNotVerifiedEmailCount, conflictingUsersWithDifferentEmailCount, conflictingGroupsCount) {
    this._dbDumpAvailable = dbDumpAvailable;
    this._selectCheckbox($('includeConfigs'));
    this._selectCheckbox($('includeBuildsData'));

    this._selectCheckbox($('importNewGroups'));

    this._selectCheckbox($('importNewUsers'));

    if (conflictingUsersWithSameVerifiedEmailCount === 0 ) {
      this._disableCheckbox('importConflictingUsersWithSameVerifiedEmail', "Selected backup file doesn't contain such users");
    }

    if (conflictingUsersWithSameNotVerifiedEmailCount === 0 ) {
      this._disableCheckbox('importConflictingUsersWithSameNotVerifiedEmail', "Selected backup file doesn't contain such users");
    }

    if (conflictingUsersWithDifferentEmailCount === 0 ) {
      this._disableCheckbox('importConflictingUsersWithDifferentEmail', "Selected backup file doesn't contain such users");
    }

    if (conflictingGroupsCount === 0 ) {
      this._disableCheckbox('mergeExistingGroups', "Selected backup file doesn't contain such groups");
    }

    if (!configsAvailable) {
      this._disableCheckbox('includeConfigs', "Selected backup doesn't contain projects");
      this._disableCheckbox('includeBuildsData', "Selected backup doesn't contain projects");
    }

    if (!dbDumpAvailable) {
      this._disableCheckbox('includeBuildsData', "Selected backup file doesn't contain database dump");
      this._disableCheckbox('importNewUsers', "Selected backup file doesn't contain database dump");
      this._disableCheckbox('importConflictingUsersWithSameVerifiedEmail', "Selected backup file doesn't contain database dump");
      this._disableCheckbox('importConflictingUsersWithSameNotVerifiedEmail', "Selected backup file doesn't contain database dump");
      this._disableCheckbox('importConflictingUsersWithDifferentEmail', "Selected backup file doesn't contain database dump");
      this._disableCheckbox('importNewGroups', "Selected backup file doesn't contain database dump");
      this._disableCheckbox('mergeExistingGroups', "Selected backup file doesn't contain database dump");
    }

    $('includeConfigs').on('click', BS.ProjectsImport.ConfigureImportForm.scopeChanged);
    $('importNewUsers').on('click', BS.ProjectsImport.ConfigureImportForm.scopeChanged);
    $('importConflictingUsersWithSameVerifiedEmail').on('click', BS.ProjectsImport.ConfigureImportForm.scopeChanged);
    $('importConflictingUsersWithSameNotVerifiedEmail').on('click', BS.ProjectsImport.ConfigureImportForm.scopeChanged);
    $('importConflictingUsersWithDifferentEmail').on('click', BS.ProjectsImport.ConfigureImportForm.scopeChanged);
    $('importNewGroups').on('click', BS.ProjectsImport.ConfigureImportForm.scopeChanged);
    $('mergeExistingGroups').on('click', BS.ProjectsImport.ConfigureImportForm.scopeChanged);

    this.scopeChanged();
  },

  _disableCheckbox: function (element, title) {
    $(element).checked = false;
    $(element).disabled = true;
    $(element).title = title;
    if ($j('label[for='+element+']')) {
      $j('label[for='+element+']').addClass("grey");
      $j('label[for='+element+']').attr('title', title);
    }
  },

  _enableCheckbox: function (element) {
    $(element).disabled = false;
    $(element).title = "";
    if ($j('label[for='+element+']')) {
      $j('label[for='+element+']').removeClass("grey");
      $j('label[for='+element+']').attr('title', '');
    }
  },

  _selectCheckbox: function (element) {
    element.checked = true;
    element.disabled = false;
    element.title = "";
  }
});

BS.ProjectsImport.ConflictingUsersWithSameVerifiedEmailDialog = OO.extend(BS.AbstractModalDialog, {
  getContainer: function () {
    return $('conflictingUsersWithSameVerifiedEmailDialog');
  }
});

BS.ProjectsImport.ConflictingUsersWithSameNotVerifiedEmailDialog = OO.extend(BS.AbstractModalDialog, {
  getContainer: function () {
    return $('conflictingUsersWithSameNotVerifiedEmailDialog');
  }
});

BS.ProjectsImport.ConflictingUsersWithDifferentEmailDialog = OO.extend(BS.AbstractModalDialog, {
  getContainer: function () {
    return $('conflictingUsersWithDifferentEmailDialog');
  }
});

BS.ProjectsImport.ConflictingGroupsDialog = OO.extend(BS.AbstractModalDialog, {
  getContainer: function () {
    return $('conflictingGroupsDialog');
  }
});

BS.ProjectsImport.ProjectsConflictsDialog = OO.extend(BS.AbstractModalDialog, {
  getContainer: function () {
    return $('projectsConflictsDialog');
  }
});


