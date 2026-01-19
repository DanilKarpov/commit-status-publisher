

BS.EditVcsUsername = OO.extend(BS.AbstractModalDialog, {
  getContainer: function() {
    return $('editVcsSettingsDialog');
  },

  showEditDialog: function(key, vcsUsername, title) {
    BS.Util.hide('vcsRootSelector');

    $('editVcsSettingsTitle').innerHTML = title;
    $('vcsUsername').value = vcsUsername;
    $('vcsUsernameKey').value = key;

    this.showCentered();
    this.bindCtrlEnterHandler(this.submitUsername.bind(this));

    setTimeout(function () {
      $('vcsUsername').focus();
    }.bind(this), 250);
  },

  showAddDialog: function(defaultVcsUsername) {
    BS.Util.show('vcsRootSelector');

    $('editVcsSettingsTitle').innerHTML = "Add VCS username";
    $('vcsUsername').value = defaultVcsUsername;
    $('vcsUsernameKey').value = "";
    $("vcsRoot").onchange();

    this.showCentered();
    this.bindCtrlEnterHandler(this.submitUsername.bind(this));

    $("vcsRoot").focus();
  },

  deleteUsername: function(vcsUsernameKey) {
    var form = $('editVcsSettings');
    BS.confirm("Are you sure you want to delete this username?", function () {
      BS.ajaxRequest(form.action, {
        parameters: "vcsUsernameKey=" + vcsUsernameKey + "&vcsUsername=" + "&userId=" + form.userId.value,
        onComplete: function() {
          $('vcsUsernames').refresh();
        }
      });
    }.bind(this));
  },

  submitUsername: function() {
    var form = $('editVcsSettings');
    BS.Util.show('savingUsername');
    Form.disable(form);
    BS.ajaxRequest(form.action, {
      parameters: BS.Util.serializeForm(form),
      onComplete: function(result) {
        var success = true;
        BS.XMLResponse.processErrors($j.parseXML(result.responseText), {}, function(id, elem) {
          success = false;
          $j("#vcs_usernames_error").text(elem.firstChild.nodeValue);
        });

        BS.Util.hide('savingUsername');

        if (success) {
          BS.EditVcsUsername.close();
          $('vcsUsernames').refresh();
        } else {
          Form.enable(form);
        }
      }
    });
    return false;
  }
});

BS.VcsUsername = {
  addVcsNameFromModification: function(modId) {
    BS.confirm("Add this vcs username to your profile?", function () {
      var onSuccess = function() {
        BS.reload(true);
      };
      var onFailure = function(error) {
        alert(error);
      };
      this.addVcsNameByModId(modId, null, onSuccess, onFailure);
    }.bind(this));
  },

  viewModificationAddVcsName: function(modId, vcsUsername) {
    BS.confirm("Add VCS username \"" + vcsUsername + "\" to your profile?", function () {
      var beforeRequest = function() {
        $j('#addVcsNameProgress').show();
      };
      var onSuccess = function() {
        BS.reload(true);
      };
      var onFailure = function(error) {
        $j('#addVcsNameProgress').hide();
        alert(error);
      };
      this.addVcsNameByModId(modId, beforeRequest, onSuccess, onFailure);
    }.bind(this));
  },

  addVcsNameByModId: function(modId, beforeRequest, onSuccess, onFailure) {
    if (beforeRequest) {
      beforeRequest();
    }
    BS.ajaxRequest(window['base_uri'] + "/ajax.html", {
      parameters: 'addVcsUsername=' + modId,
      onComplete: function(transport) {
        var errors = BS.XMLResponse.processErrors(transport.responseXML, {}, function(id, error) {
          var msg = error.firstChild.nodeValue;
          if (onFailure) {
            onFailure(msg);
          } else {
            alert(msg);
          }
        });

        if (!errors && onSuccess) {
          onSuccess();
        }
      }
    });
  }
};