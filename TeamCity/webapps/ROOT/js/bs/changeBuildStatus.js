
BS.ChangeBuildStatusDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  formElement: function() {
    return $('changeBuildStatus');
  },

  getContainer: function() {
    return $('changeBuildStatusDialog');
  },

  showDialog: function(buildId, isCurrentlyFailing, isFinished, noReload) {
    this.noReload = noReload;

    var statusText = (isCurrentlyFailing ? "successful" : "failed");
    $("changeBuildStatusTitle").innerHTML = "Mark build " + statusText + $$(".changeBuildStatus-why")[0].innerHTML;
    $("changeBuildStatusSubmitButton").value = "Mark " + statusText;
    //$$("#changeBuildStatus textarea")[0].placeholder = "Why should be " + statusText + "?";

    this.formElement().changeBuildStatus.value = buildId;
    this.formElement().status.value = isCurrentlyFailing ? "NORMAL" : "FAILURE";

    this.showCentered();
    this.bindCtrlEnterHandler(this.submit.bind(this));

    this._activateComment();

    this.clearErrors();
    this.formElement().down(".changeBuildStatus-errorText").innerHTML = '';

    this.formElement().down(".changeBuildStatus-warningText").innerHTML = !isFinished ?
                                                                          "Running build may overwrite the status change later" : "";
    return new Promise(function (resolve, reject) {
      this._resolve = resolve;
      this._reject = reject;
    }.bind(this));
  },

  _activateComment: function() {
    var comment = this.formElement().comment;
    comment.disabled = false;
    comment.focus();
    comment.select();
  },

  submit: function() {

    var that = this;
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {

      onStatusError: function(error) {
        this._processError(error);
      },

      onBuildError: function(error) {
        this._processError(error);
      },

      onCommentError: function(error) {
        that.highlightErrorField(that.formElement().comment);
        this._processError(error);
        that._activateComment();
      },

      _processError: function(error) {
        that.formElement().down(".changeBuildStatus-errorText").innerHTML = error.firstChild.nodeValue;
      },

      onSuccessfulSave: function() {
        if (!that.noReload) {
          BS.reload(true);
        } else {
          that.close();
        }
        if (that._resolve != null) {
          that._resolve();
        }
      },

      onFailure: function() {
        alert("Problem accessing server");
      }
    }));

    return false;
  },

  _f: null
}));
