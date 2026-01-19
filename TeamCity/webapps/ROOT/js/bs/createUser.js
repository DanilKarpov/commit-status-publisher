BS.CreateUserForm = OO.extend(BS.AbstractPasswordForm, {
  submitCreateUser: function(pwdIsOptional) {

    var that = this;

    var saveFunc = function() {
          BS.PasswordFormSaver.save(that, that.formElement().action, OO.extend(BS.ErrorsAwareListener, {
            onBeginSave: function(form) {
              $j('.input-wrapper').removeAttr('data-error');
              BS.ErrorsAwareListener.onBeginSave(form);
            },

            onDuplicateAccountError: function(elem) {
              $j(".input-wrapper_username").attr('data-error', elem.firstChild.nodeValue);
              that.highlightErrorField($("input_teamcityUsername"));
            },

            onEmptyUsernameError: function(elem) {
              $j(".input-wrapper_username").attr('data-error', elem.firstChild.nodeValue);
              that.highlightErrorField($("input_teamcityUsername"));
            },

            onEmptyEmailError: function(elem) {
              $j(".input-wrapper_email").attr('data-error', elem.firstChild.nodeValue);
              that.highlightErrorField($("input_teamcityEmail"));
            },

            onInvalidEmailError: function(elem) {
              $j(".input-wrapper_email").attr('data-error', elem.firstChild.nodeValue);
              that.highlightErrorField($("input_teamcityEmail"));
            },

            onPasswordsMismatchError: function(elem) {
              $j(".input-wrapper_password1").attr('data-error', elem.firstChild.nodeValue);
              that.highlightErrorField($("password1"));
              that.highlightErrorField($("retypedPassword"));
            },

            onEmptyPasswordError: function(elem) {
              $j(".input-wrapper_password1").attr('data-error', elem.firstChild.nodeValue);
              that.highlightErrorField($("password1"));
            },

            onMaxNumberOfUserAccountsReachedError: function(elem) {
              alert(elem.firstChild.nodeValue);
            },

            onCreateUserError: function(elem) {
              alert(elem.firstChild.nodeValue);
            },

            onUserPropertyError: function(element) {
              BS.UserProfile.onUserPropertyError(element, that);
            },

            onCompleteSave: function(form, responseXML, err) {
              BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
              if (!err) {
                BS.XMLResponse.processRedirect(responseXML);
              }
            }
          }));
    };

    if (pwdIsOptional && $j("#password1").val() === "") {
      BS.confirmDialog.show({
                              text: "The password is not specified and the user will not be able to log in with username/password.",
                              actionButtonText: "Create User",
                              cancelButtonText: 'Cancel',
                              title: "Create user with empty password",
                              action: saveFunc })
    } else {
      saveFunc();
    }

    return false;
  }
});

BS.AdminCreateUserForm = OO.extend(BS.CreateUserForm, {
  setSaving: function(saving) {
    if (saving) {
      BS.Util.show('saving1');
    } else {
      BS.Util.hide('saving1');
    }
  }
});
