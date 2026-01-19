BS.SendResetEmailForm = OO.extend(BS.AbstractWebForm, {
  submit: function () {

    var that = this;

    BS.FormSaver.save(that, that.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onCompleteSave: function (form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
        form.enable();
        if (!err) {
          $j('#resetPasswordResult').html(responseXML.documentElement.firstChild.nodeValue);
          $j("#resetPasswordResult").show();
          $j("#changePasswordForm").hide();
          $j("#formNote").hide();
          $j("#errorMessage").hide();
        }
      },

      onError: function (elem) {
        $j("#errorMessage").text(elem.firstChild.nodeValue);
        $j("#resetPasswordResult").hide();
        $j("#errorMessage").show();
      },

      onEmptyEmailError: function(elem) {
        this.onError(elem);
      },

      onInvalidEmailError: function(elem) {
        this.onError(elem);
      },

      onResetPasswordDisabledError: function(elem) {
        BS.reload(true);
      }
    }));
  }
});

BS.SendChangeEmailForm = OO.extend(BS.AbstractWebForm, {
  submit: function () {

    var that = this;

    BS.FormSaver.save(that, that.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onCompleteSave: function (form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
        form.enable();
        if (!err) {
          $j('#resetPasswordResult').html(responseXML.documentElement.firstChild.nodeValue);
          $j("#resetPasswordResult").show();
          $j("#changePasswordForm").hide();
          $j("#errorMessage").hide();
        }
      },

      onError: function (elem) {
        $j("#errorMessage").text(elem.firstChild.nodeValue);
        $j("#resetPasswordResult").hide();
        $j("#errorMessage").show();
        $j("#input_email").focus();
      },

      onEmptyEmailError: function(elem) {
        this.onError(elem);
      },

      onInvalidEmailError: function(elem) {
        this.onError(elem);
      },

      onResetPasswordDisabledError: function(elem) {
        BS.reload(true);
      }
    }));
  }
});


BS.ResetPasswordForm = OO.extend(BS.AbstractPasswordForm, {
  submit: function () {

    var that = this;

    BS.PasswordFormSaver.save(that, that.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onCompleteSave: function (form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
        if (!err) {
          BS.XMLResponse.processRedirect(responseXML);
        }
      },

      onFailedToSetPasswordError: function (elem) {
        $j("#resetError").text(elem.firstChild.nodeValue);
      },

      onResetPasswordDisabledError: function(elem) {
        BS.reload(true);
      },

      onInvalidTokenError: function(elem) {
        BS.reload(true);
      }
    }));
  }
});