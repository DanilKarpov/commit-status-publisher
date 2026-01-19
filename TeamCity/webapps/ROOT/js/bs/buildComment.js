BS.BuildCommentDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  formElement: function() {
    return $('buildCommentForm');
  },

  getContainer: function() {
    return $('buildCommentFormDialog');
  },

  showBuildCommentDialog: function(promotionId, defaultMessage, isNew) {
    var _this = this;
    this.formElement().promotionId.value = promotionId;

    var messageIsValid = defaultMessage != null && defaultMessage.length > 0;
    this.formElement().buildComment.value = messageIsValid ? defaultMessage : this.formElement().buildComment.defaultValue;
    $('buildCommentFormTitle').innerHTML = (messageIsValid ? 'Change' : 'Add') + ' comment for build&nbsp;<span id="commentBuildNumber"></span>';
    ReactUI.renderBuildNumber('commentBuildNumber', {
      buildId: promotionId,
      hideStar: true,
      withLink: true,
      className: 'titleBuildNumber'
    });

    this.showAtFixed($(this.getContainer()));

    $(this.formElement().buildComment).activate();

    this.bindCtrlEnterHandler(this.submit.bind(this));

    this._doNotReload = isNew;
    return new Promise(function (resolve, reject) {
      _this._resolve = resolve;
      _this._reject = reject;
    });
  },

  submit: function() {
    var _this = this;
    var f = this.formElement();
    if (this.formElement().buildComment.value == this.formElement().buildComment.defaultValue) {
      this.formElement().buildComment.value = "";
    }

    BS.Util.show("buildCommentProgressIcon");

    BS.FormSaver.save(BS.BuildCommentDialog, BS.BuildCommentDialog.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      
      onCompleteSave: function(form, responseXML, err) {
        BS.Util.hide("buildCommentProgressIcon");
        Form.enable(f);
        BS.BuildCommentDialog.close();

        if (!_this._doNotReload) {
          BS.reload(true);
        }

        _this._resolve && _this._resolve(f.querySelector('.commentTextArea').value);
      },

      onFailure: function() {
        BS.Util.hide("buildCommentProgressIcon");
        alert("Problem accessing server");
      }
    }));

    return false;
  }
}));
