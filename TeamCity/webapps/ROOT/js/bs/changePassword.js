
BS.ChangePasswordForm = OO.extend(BS.AbstractPasswordForm, {
  submitChangePassword: function() {
    var that = this;

    BS.PasswordFormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onVerificationErrorError: function(element) {
        $j("#errorMessage").text(element.firstChild.nodeValue);
        BS.Util.show("errorMessage");
        that.highlightErrorField($("password"));
        that.highlightErrorField($("repeatPassword"));

      },

      onComplete: function(form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);

        if (!err) {
          BS.XMLResponse.processRedirect(responseXML);
        }
      },

      onError: function (elem) {
        $j("#errorMessage").text(elem.firstChild.nodeValue);
        $j("#errorMessage").show();
        $j("#password").focus();
      },

      onNotMatchPolicyError: function(elem) {
        this.onError(elem);
      },
    }));

    return false;
  },
  sendResetPasswordEmail: function() {
    BS.Util.show("emailVerificationProgress");
    this.toggleVerifyButton("sendingEmail");
    BS.ajaxRequest(this.ACTION_URL + "?action=sentEmail", {
      method: "POST",
      onComplete: function() {
        BS.reload(true);
      }
    });
  }
});

