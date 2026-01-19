BS.CheckList = {
  _filterChangedDelayedInvocator: {},
  _stateChangedDelayedInvocator: {},
  _childItemIds: {},

  filterChanged: function(typeId) {
    var invocator = this._filterChangedDelayedInvocator[typeId];
    if (invocator == null) {
      invocator = this._filterChangedDelayedInvocator[typeId] = BS.Util.createDelayedInvocator(function() {
        BS.CheckList._doFilterChanged(typeId);
      }, 300);
    }
    invocator.invoke();
  },

  stateChanged: function(checkbox, typeId, hasValidationSupport, hasCustomOptionsSupport) {
    if (checkbox.checked) {
      this._checkChildren(checkbox.value, typeId);
    }

    var invocator = this._stateChangedDelayedInvocator[typeId];
    if (invocator == null) {
      invocator = this._stateChangedDelayedInvocator[typeId] = BS.Util.createDelayedInvocator(function() {
        BS.CheckList._doStateChanged(typeId, hasValidationSupport, hasCustomOptionsSupport);
      }, 800);
    }
    invocator.invoke();
  },

  _checkChildren: function(itemId, typeId) {
    var childItemIds = this._childItemIds[itemId] || [];
    for (var i = 0; i < childItemIds.length; i++) {
      var childItemId = childItemIds[i];
      $("checkListItem-" + typeId + "-" + childItemId).checked = true;
      this._checkChildren(childItemId, typeId);
    }
  },

  _doFilterChanged: function(typeId) {
    var emptyId = "checkListFilterEmptyIcon_" + typeId;
    var errorId = "checkListFilterErrorIcon_" + typeId;
    var progressId = "checkListFilterProgressIcon_" + typeId;
    BS.Util.hide(emptyId);
    BS.Util.hide(errorId);
    BS.Util.show(progressId);
    BS.CheckList._ajax("filter", typeId, "keyPhrase=" + encodeURIComponent(BS.Util.trimSpaces($("checkListFilter_" + typeId).value)), {
      onError: function(error) {
        BS.Util.hide(progressId);
        BS.Util.show(errorId);
        $(errorId).firstElementChild.title = error;
      },

      onComplete: function() {
        $("checkListItems_" + typeId).refresh(progressId, null, function() {
          //BS.Util.show(emptyId);
        });
      }
    });
  },

  _doStateChanged: function(typeId, hasValidationSupport, hasCustomOptionsSupport) {
    var emptyId = null;
    var errorId = null;
    var progressId = null;
    if (hasValidationSupport) {
      emptyId = "checkListValidationEmpty_" + typeId;
      errorId = "checkListValidationError_" + typeId;
      progressId = "checkListValidationProgress_" + typeId;
      BS.Util.hide(emptyId);
      BS.Util.hide(errorId);
      BS.Util.show(progressId);
    }
    BS.CheckList._ajax("state", typeId, BS.CheckList._getStateParams(typeId, hasCustomOptionsSupport), {
      onError: function(error) {
        if (hasValidationSupport) {
          BS.Util.hide(progressId);
          BS.Util.show(errorId);
          $("checkListValidationErrorText_" + typeId).innerHTML = error.escapeHTML();
        }
      },

      onComplete: function() {
        $("checkListStateInfo_" + typeId).refresh();
        if (hasValidationSupport) {
          $("checkListWarnings_" + typeId).refresh();
        }
      }
    });
  },

  submitForm: function(typeId, hasCustomOptionsSupport) {
    var params = BS.CheckList._getStateParams(typeId, hasCustomOptionsSupport);
    BS.CheckList._modalAction("apply", typeId, params, hasCustomOptionsSupport, function() {
      BS.PopupDialog.hide(typeId, true);
    });
  },

  cancel: function(typeId) {
    BS.CheckList._ajax("cancel", typeId, null, { onError: function() {}, onComplete: function() {} });
    BS.PopupDialog.hide(typeId, false);
  },

  _modalAction: function(action, typeId, params, hasCustomOptionsSupport, afterComplete) {
    var form1 = new BS.CheckListForm("First", typeId);
    var form2 = new BS.CheckListForm("Second", typeId);
    var customOptionsForm = new BS.CheckListForm("CustomOptions", typeId);
    var progressId = "checkListMainProgressIcon_" + typeId;
    form1.disable();
    form2.disable();
    if (hasCustomOptionsSupport) {
      customOptionsForm.disable();
    }
    BS.Util.show(progressId);
    var formEnabler = function() {
      form1.enable();
      form2.enable();
      if (hasCustomOptionsSupport) {
        customOptionsForm.enable();
      }
    };
    BS.CheckList._ajax(action, typeId, params, {
      onError: function(error) {
        BS.Util.hide(progressId);
        formEnabler();
        alert(error);
      },

      onComplete: function() {
        afterComplete(progressId, formEnabler);
      }
    });
  },

  _getStateParams: function(typeId, hasCustomOptionsSupport) {
    var result = "";
    $j(".check-list-item-" + typeId + ":checked:not(:disabled)").each(function() {
      result += "&checkedItemId=" + encodeURIComponent(this.value);
    });
    if (hasCustomOptionsSupport) {
      var customOptionsForm = new BS.CheckListForm("CustomOptions", typeId);
      var customParams = customOptionsForm.serializeParameters();
      if (customParams.length > 0) {
        result += "&" + customParams;
      }
    }
    return result.length > 0 ? result.substring(1) : null;
  },

  _ajax: function(action, typeId, params, listener) {
    BS.ajaxRequest(window['base_uri'] + "/popupDialog.html", {
      method: "post",
      parameters: "typeId=" + typeId + "&action=" + action + (params ? "&" + params : ""),

      onComplete: function(transport) {
        if (listener._error) return;
        var responseXML = transport.responseXML;
        var hasErrors = responseXML && BS.XMLResponse.processErrors(responseXML, {}, function(id, elem) {
          listener.onError(elem.firstChild.nodeValue);
        });
        if (!hasErrors) {
          listener.onComplete();
        }
      },

      onFailure: function() {
        listener._error = true;
        listener.onError("Error accessing server");
      },

      onException: function(obj, e) {
        listener._error = true;
        if (e.message) {
          listener.onError(e.message);
        }
        else {
          listener.onError(e.toString());
        }
      }
    });
  }
};

BS.CheckListForm = function(prefix, typeId) {
  _.extend(this, BS.AbstractWebForm);
  this.formElement = function() {
    return $("checkList" + prefix + "Form_" + typeId);
  };
};
