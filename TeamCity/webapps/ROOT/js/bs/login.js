BS.LoginListener = OO.extend(BS.ErrorsAwareListener, {
  onLoginErrorError: function(elem) {
    $("errorMessage").innerHTML = elem.firstChild.nodeValue;
    BS.Util.show("errorMessage");
    BS.LoginForm.highlightErrorField($("username"));
    BS.LoginForm.highlightErrorField($("password"));
  },

  onUnexpectedError: function(form, _, elem) {
    $("errorMessage").innerHTML = elem.firstChild.nodeValue;
    BS.Util.show("errorMessage");
    form.setSaving(false);
    form.enable();
  },

  onCompleteSave: function(form, responseXML, errStatus) {
    if (errStatus) {
      form.setSaving(false);
      form.enable();
      form.focusFirstErrorField();
    }

    if (!errStatus) {
      BS.XMLResponse.processRedirect(responseXML);
    }
  }
});

BS.LoginForm = OO.extend(BS.AbstractPasswordForm, {
  submitLogin: function() {
    BS.PasswordFormSaver.save(this, this.formElement().action, BS.LoginListener);
    return false;
  }
});
