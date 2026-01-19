BS.Pin = {
  _onBuildPage: false,

  pin: function(onBuildPage, doNotReload) {
    if (onBuildPage) {
      BS.Pin._onBuildPage = true;
    }
    return BS.Pin.togglePin(doNotReload);
  },

  unpin: function(onBuildPage, doNotReload) {
    if (onBuildPage) {
      BS.Pin._onBuildPage = true;
    }
    return BS.Pin.togglePin(doNotReload);
  },

  togglePin: function(doNotReload) {
    var buildId = BS.PinBuildDialog.formElement().buildId.value;
    var link = $('pinLink' + buildId);

    return new Promise(function (resolve, reject) {
      BS.Util.show("progressIcon" + buildId);
      BS.Util.hide(link);

      BS.FormSaver.save(BS.PinBuildDialog, BS.PinBuildDialog.formElement().action, OO.extend(BS.ErrorsAwareListener, {

        onCompleteSave: function(form, responseXML, err) {
          if (link) {
            $(link.parentNode).cleanWhitespace();
          }

          BS.Util.hide("progressIcon" + buildId);
          BS.Util.show(link);

          if (!doNotReload) {
            BS.reload(true);
          }

          BS.PinBuildDialog.formElement().enable();
          resolve();
        },

        onFailure: function() {
          BS.Util.show(link);
          BS.Util.hide("progressIcon" + buildId);
          alert("Problem accessing server");
          reject()
        }
      }));
    })
  },

  showSuccessMessage: function(buildId, pinned) {
    var link = $('pinLink' + buildId);
    var tr = link.parentNode.parentNode.parentNode;
    $(tr).cleanWhitespace();
    if (pinned) {
      tr.addClassName('highlight');
      BS.Util.show('successMessage');
      $('successMessage').innerHTML = "Pinned build won't be removed from the history list until you unpin it.";
    }
    else {
      BS.Util.show('successMessage');
      $('successMessage').innerHTML = "The build has been unpinned.";
    }

    BS.Util.hideSuccessMessages();
  }
};

BS.PinBuildDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  formId: 'pinBuildForm',
  formElement: function() {
    return $(this.formId);
  },

  getContainer: function() {
    return $('pinBuildFormDialog');
  },

  onText: "Pin",
  offText: "Unpin",

  appendTag: function(tag) {
    BS.Util.addWordToTextArea(this.formElement().buildTagsInfo, tag);
  },

  showPinBuildDialog: function(buildId, pin, partOfChain, defaultMessage, availableTagsContainerId, isAsync, buildTypeId) {
    this.formElement().buildId.value = buildId;

    var pinText = pin ? this.onText : this.offText;

    this.formElement().pin.value = pin;
    this.formElement().PinSubmitButton.value = pinText;
    $('pinBuildFormTitle').innerHTML = pinText + ' build&nbsp;<span id="pinBuildNumber"></span>';
    ReactUI.renderBuildNumber('pinBuildNumber', {
      buildId: buildId,
      hideStar: true,
      withLink: true,
      className: 'titleBuildNumber'
    });

    this.formElement().pinComment.value = defaultMessage != null && defaultMessage.length > 0 ? defaultMessage : this.formElement().pinComment.defaultValue;

    this.showTags(availableTagsContainerId, partOfChain, buildTypeId);

    this.showCentered().then(() => {
      this.formElement().pinComment.focus();
      this.formElement().pinComment.select();

      this.__loadTags(buildId);
    });

    this.bindCtrlEnterHandler(this.submit.bind(this));

    if (isAsync) {
      var _this = this;

      return new Promise(function(resolve, reject) {
        _this._resolve = resolve;
        _this._reject = reject;
      })
    }

    return false;
  },


  __loadTags: function(buildId) {
    var that = this;
    that.formElement().PinSubmitButton.disable();
    var saving = $j('#pinBuildDialogSaving');
    var oldTitle = saving.prop('title');
    saving.prop('title', 'Loading tags...');
    saving.show();
    $j.getJSON(window['base_uri'] + "/app/rest/ui/builds/id:" + buildId + "/tags", function(data) {
      if ($j(that.formElement().buildTagsInfo).is(':visible') && data.tag) { //don't fill tags in closed dialog && don't parse empty data response
        that.formElement().buildTagsInfo.value = data.tag.map(function (tag) {
          return tag.name;
        }).join(' ')
      }
      that.formElement().PinSubmitButton.enable();
      saving.prop('title', oldTitle);
      saving.hide();
    });
  },


  submit: function() {
    var onBuildPage = this.formElement().onBuildPage.value == 'true';

    if (this.formElement().pinComment.value == this.formElement().pinComment.defaultValue) {
      this.formElement().pinComment.value = "";
    }

    var pin = this.formElement().pin.value == 'true';

    BS.Pin[pin ? 'pin' : 'unpin'](onBuildPage, !!this._resolve)
      .then(this._resolve && (function () {this._resolve(pin)}.bind(this)), this._reject)
      .then(BS.PinBuildDialog.close.bind(this));

    this.formElement().buildTagsInfo.value = '';
    return false;
  },

  close: function() {
    this.formElement().buildTagsInfo.value = '';
    this.doClose();
  }
}));
BS.TagsEditingMixin.init(BS.PinBuildDialog);
