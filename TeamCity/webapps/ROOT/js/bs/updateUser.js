BS.UpdateUserListener = OO.extend(BS.ErrorsAwareListener, {
  onBeginSave: function(form) {
    BS.UpdateUserListener.form = form;
    $j('.input-wrapper').removeAttr('data-error');
    BS.ErrorsAwareListener.onBeginSave(form);
  },

  duplicateAccount: function(element) {
    $j(".input-wrapper_username").attr('data-error', element.firstChild.nodeValue);
  },

  emptyUsername: function(element) {
    $j(".input-wrapper_username").attr('data-error', element.firstChild.nodeValue);
  },

  onEmptyEmailError: function(elem) {
    $j(".input-wrapper_email").attr('data-error', elem.firstChild.nodeValue);
  },

  onInvalidEmailError: function(elem) {
    $j(".input-wrapper_email").attr('data-error', elem.firstChild.nodeValue);
  },

  passwordsMismatch: function(element) {
    $j(".input-wrapper_password1").attr('data-error', element.firstChild.nodeValue);
  },

  passwordNotSecure: function(element) {
    $j(".input-wrapper_retypedPassword").attr('data-error', element.firstChild.nodeValue);
  },

  incorrectCurrentPassword: function(element) {
    $j(".input-wrapper_currentPassword").attr('data-error', element.firstChild.nodeValue);
  },

  onUserPropertyError: function(element) {
    BS.UserProfile.onUserPropertyError(element, BS.UpdateUserListener.form);
  }
});

BS.UpdateUserForm = OO.extend(BS.AbstractPasswordForm, {
  _modifiedChangeListener: null,

  subscribeToModifiedChange: function(listener) {
    this._modifiedChangeListener = listener;
  },

  setSaving: function(saving) {
    if (saving) {
      BS.Util.show('saving1');
    } else {
      BS.Util.hide('saving1');
    }
  },

  saveInSession: function() {
    var that = this;
    $("submitUpdateUser").value = 'storeInSession';

    BS.PasswordFormSaver.save(this, this.formElement().action, OO.extend(BS.StoreInSessionListener, {
      onPublicKeyExpiredError: function(elem) {
        $("publicKey").value = elem.firstChild.nodeValue;
      }
    }));
  },

  onModifiedChange: function() {
    if (this._modifiedChangeListener) {
      this._modifiedChangeListener(this.modified);
    }
  }
});


BS.UpdatePersonalProfileForm = OO.extend(BS.UpdateUserForm, {

  _currentParameters: null,

  formElement: function() {
    return $("profileForm");
  },

  setupEventHandlers: function() {
    var that = this;

    this._currentParameters = this.serializeParameters();

    this.setUpdateStateHandlers({
      updateState: function() {
        //probably this logic can be moved to forms.js and can be common for all forms
        var newParameters = that.serializeParameters();
        if (newParameters !== that._currentParameters) {
          that._currentParameters = newParameters;
          that.setModified(true);
        }
        that.saveInSession();
      },

      saveState: function() {
        that.submitPersonalProfile();
      }
    });
  },

  submitPersonalProfile: function() {
    var that = this;
    $("submitUpdateUser").value = 'storeInDatabase';

    BS.PasswordFormSaver.save(this, this.formElement().action, OO.extend(BS.UpdateUserListener, {
      onUserNotFoundError: function(element) {
        BS.reload(true);
      },

      onCompleteSave: function(form, responseXML, errStatus) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, errStatus);

        if (!errStatus) {
          that.removeUpdateStateHandlers();
          const rootElement = responseXML.documentElement;
          const redirect = rootElement.getElementsByTagName("redirect")[0];
          if (redirect) {
            BS.XMLResponse.processRedirect(responseXML);
          } else {
            BS.reload(true);
          }
        }
      }
    }));

    return false;
  }
});

BS.AdminUpdateUserForm = OO.extend(BS.UpdateUserForm, {
  setupEventHandlers: function() {
    var that = this;

    this.setUpdateStateHandlers({
      updateState: function() {
        that.saveInSession();
      },

      saveState: function() {
        that.submitUserProfile();
      }
    });
  },

  submitUserProfile: function() {
    var that = this;
    $("submitUpdateUser").value = 'storeInDatabase';

    BS.PasswordFormSaver.save(this, this.formElement().action, OO.extend(BS.UpdateUserListener, {
      onUserNotFoundError: function(element) {
        document.location.href = "admin.html?item=users";
      },

      onCompleteSave: function(form, responseXML, errStatus) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, errStatus);

        if (!errStatus) {
          that.removeUpdateStateHandlers();
          BS.reload(true);
        }
      }
    }));

    return false;
  },

  deleteUserAccount: function() {
    var that = this;
    BS.confirm('Are you sure you want to delete this user account?', function () {
      BS.FormSaver.save(that, that.formElement().action + "&removeUserAccount=1", OO.extend(BS.ErrorsAwareListener, {
        onCompleteSave: function(form, responseXML, err) {
          if (!err) {
            BS.XMLResponse.processRedirect(responseXML);
          }
        }
      }));
    });

    return false;
  },

  logoutAllUserSessions: function() {
    var that = this;
    BS.confirm('Are you sure you want to log out all user sessions for this account?', function () {
      BS.FormSaver.save(that, that.formElement().action + "&logoutAllUserSessions=1", OO.extend(BS.ErrorsAwareListener, {
        onCompleteSave: function(form, responseXML, err) {
          if (!err) {
            BS.reload(false);
          }
        }
      }));
    });

    return false;
  }
});

