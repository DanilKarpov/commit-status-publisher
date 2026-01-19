BS.UserEmailVerifier = {

  _currentEmailIsValid: false,
  _profileFormIsModified: false,

  updateVerifyButtonState: function() {
    if (this._profileFormIsModified) {
      this.toggleVerifyButton("notSavedEmail");
    } else if (!this._currentEmailIsValid) {
      this.toggleVerifyButton("notValidEmail");
    } else {
      this.toggleVerifyButton("activeVerifyLink");
    }
  },

  toggleVerifyButton: function(newMode) {
    BS.Util.toggleDependentElements(newMode, 'verifyLink');
  },

  sendVerificationEmail: function() {
    BS.Util.show("emailVerificationProgress");
    this.toggleVerifyButton("sendingEmail");
    BS.ajaxRequest(window['base_uri'] + '/verifyUserEmail.html?userId=' + this._userId, {
      method: "POST",
      onComplete: function() {
        BS.reload(true);
      }
    });
  },

  onModifiedChange: function(modified) {
    this._profileFormIsModified = modified;
    this.updateVerifyButtonState();
  },

  init: function(userId, emailIsValid) {
    this._currentEmailIsValid = emailIsValid;
    this._userId = userId;
    this.updateVerifyButtonState();
  }
};
