
BS.ServerConfigForm = OO.extend(BS.AbstractPasswordForm, {

  setupEventHandlers: function() {
    var that = this;
    this.removeUpdateStateHandlers();
    this.setUpdateStateHandlers({
      updateState: function() {
        that.storeInSession();
      },
      saveState: function() {
        that.submitSettings();
      }
    })
  },

  storeInSession: function() {
    $('submitSettings').value = 'storeInSession';
    BS.FormSaver.save(this, this.formElement().action, BS.StoreInSessionListener);
  },

  submitSettings: function() {
    $('submitSettings').value = 'store';
    if (!this.checkArtifactDirectories()) return false;

    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onInvalidRootUrlError: function(elem) {
        $j("#invalidRootUrl").text(elem.firstChild.nodeValue);
      },
      onInvalidArtifactsRootUrlError: function(elem) {
        $j("#invalidArtifactsRootUrl").text(elem.firstChild.nodeValue);
      },
      onInvalidDomainIsolationEnabledError: function(elem) {
        $j("#invalidDomainIsolationEnabled").text(elem.firstChild.nodeValue);
      },
      onInvalidMaxArtifactSizeError: function(elem) {
        $j("#invalidMaxArtifactSize").text(elem.firstChild.nodeValue);
      },

      onInvalidMaxArtifactsNumberError: function(elem) {
        $j("#invalidMaxArtifactsNumber").text(elem.firstChild.nodeValue);
      },

      onInvalidMaxInternalArtifactsNumberError: function(elem) {
        $j("#invalidMaxInternalArtifactsNumber").text(elem.firstChild.nodeValue);
      },

      onInvalidDefaultExecutionTimeoutError: function(elem) {
        $j("#invalidDefaultExecutionTimeout").text(elem.firstChild.nodeValue);
      },

      onInvalidDefaultModificationCheckIntervalError: function(elem) {
        $j("#invalidDefaultModificationCheckInterval").text(elem.firstChild.nodeValue);
      },

      onInvalidDefaultQuietPeriodError: function(elem) {
        $j("#invalidDefaultQuietPeriod").text(elem.firstChild.nodeValue);
      },

      onEmptyGuestUsernameError: function(elem) {
        $j("#invalidGuestUsername").text(elem.firstChild.nodeValue);
      },

      onGuestUsernameUsedError: function(elem) {
        $j("#invalidGuestUsername").text(elem.firstChild.nodeValue);
      },

      onEmptyRootUsernameError: function(elem) {
        $j("#invalidRootUsername").text(elem.firstChild.nodeValue);
      },

      onRootUsernameUsedError: function(elem) {
        $j("#invalidRootUsername").text(elem.firstChild.nodeValue);
      },

      artifactDirectoriesError: function(elem) {
        $j("#artifactDirectoriesError").text(elem.firstChild.nodeValue);
      },

      invalidEncryptionKey: function(elem) {
        $j("#invalidEncryptionKey").text(elem.firstChild.nodeValue);
      },

      onSaveError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },

      onCompleteSave: function(form, responseXml, wereErrors) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXml, wereErrors);
        if (!wereErrors) {
          BS.reload(true);
        }
      }
    }));

    return false;
  },

  checkArtifactDirectories: function() {
    var origVal = $('originalArtifactDirectories').value;
    var newVal = $('artifactDirectories').value;

    if (origVal == newVal) return true;

    var origSplitted = origVal.split(/[\r\n]+/);
    var newSplitted = newVal.split(/[\r\n]+/);

    var removedPaths = "";
    for (var i=0; i<origSplitted.length; i++) {
      var path = origSplitted[i];
      if (path.length > 0 && newSplitted.indexOf(path) == -1) {
        if (removedPaths.length > 0) {
          removedPaths += ", ";
        }
        removedPaths += path;
      }
    }

    if (removedPaths.length == 0) return true;
    return confirm("You removed the following artifact directories from the list: " + removedPaths + "\n" +
                   "Artifacts stored in these directories will not be accessible via TeamCity anymore.\n" +
                   "Are you sure you want to continue?");
  }
});
