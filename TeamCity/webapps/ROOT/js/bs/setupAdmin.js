
BS.SetupAdminForm = OO.extend(BS.AbstractPasswordForm, {
  submitSetupAdmin: function() {
    var that = this;

    BS.PasswordFormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onVerificationErrorError: function(element) {
        $j("#errorMessage").text(element.firstChild.nodeValue);
        BS.Util.show("errorMessage");
        that.highlightErrorField($("input_teamcityUsername"));
        that.highlightErrorField($("password1"));

      },

      onCompleteSave: function(form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);

        if (!err) {
          BS.XMLResponse.processRedirect(responseXML);
        }
      }
    }));
    return false;
  }
});

