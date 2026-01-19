/*
 * Copyright 2000-2024 JetBrains s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

BS.AbstractWebForm = {
  formElement: function() {
    return document.forms[0];
  },

  disable: function(elementsFilter) {
    // do not allow to disable form twice because in this case we will remember that
    // fields were disabled and will not enable them when enable will be called
    // (see Form.disable and _wasDisabled property for more details)
    if (this._formDisabled) return;
    var disabledElems = BS.Util.disableFormTemp(this.formElement(), elementsFilter);
    this._formDisabled = true;
    return disabledElems;
  },

  enable: function(elementsFilter) {
    if (this._formDisabled) {
      BS.Util.reenableForm(this.formElement(), elementsFilter);
    }
    var modifiedMessageForm = this._modifiedMessageForm();
    if (modifiedMessageForm) {
      BS.Util.reenableForm(modifiedMessageForm);
    }
    this._formDisabled = false;
  },

  savingIndicator: function() {
    return $('saving');
  },

  setSaving: function(saving) {
    var savingElem = this.savingIndicator();
    if (savingElem) {
      if (!this.progress_saving) {
        this.progress_saving = new BS.DelayedShow(savingElem);
      }

      if (saving) {
        this.progress_saving.start();
      } else {
        this.progress_saving.stop();
      }
    }
  },

  clearErrors: function() {
    var that = this;

    $j("#errorMessage").html('&nbsp;').hide();
    $j('.errorField').removeClass('errorField');
    $j('.error').each(function() {
      that.clearTextInsideElement(this);
    });

    BS.VisibilityHandlers.updateVisibility(this.formElement());
  },

  trimSpacesInTextFields: function() {
    var inputs = Form.getInputs(this.formElement(), "text");
    for (var i=0; i<inputs.length; i++) {
      inputs[i].value = BS.Util.trimSpaces(inputs[i].value);
    }
  },

  serializeParameters: function() {
    return BS.Util.serializeForm(this.formElement())
  },

  _modifiedMessageForm: function() {
    return $("modifiedMessageForm");
  },

  setModified: function(modified) {
    if (modified) {
      BS.Util.show("modifiedMessage");
      this.hideSuccessMessages();
      var modifiedMessageForm = this._modifiedMessageForm();
      if (modifiedMessageForm) {
        if (this._modifiedHandlers && this._modifiedHandlers.saveState) {
          modifiedMessageForm.style.display = 'inline';
        } else {
          BS.Util.hide("modifiedMessage");
        }
      }
    } else {
      BS.Util.hide("modifiedMessage");
    }
    this.modified = modified;
    this.onModifiedChange();
  },

  onModifiedChange: function () { },

  hideSuccessMessages: function() {
    BS.Util.hideSuccessMessages();
  },

  clearTextInsideElement: function(elem) {
    if (!elem || !elem.firstChild) return;
    elem.normalize();
    if (!elem.firstChild || !elem.firstChild.nodeType == 3) return;
    elem.firstChild.nodeValue = '';
  },

  highlightErrorField: function(field) {
    $(field).addClassName('errorField');
    if (BS.MultilineProperties) {
      BS.MultilineProperties.updateVisible();
    }
  },

  focusFirstErrorField: function() {
    $j('.errorField').each(function() {
      if (BS.Util.visible(this)) {
        this.focus();
        return false;
      }
    });
  },

  _clearStateChangeHandler: function() {
    if (!this._stateChangeHandlerInfo) return;

    Event.stopObserving(this._stateChangeHandlerInfo._object, 'keyup', this._stateChangeHandler);
    Event.stopObserving(this._stateChangeHandlerInfo._object, 'click', this._stateChangeHandler);
    Event.stopObserving(this._stateChangeHandlerInfo._object, 'paste', this._stateChangeHandler);

    this._stateChangeHandlerInfo = null;
    this._stateChangeHandler = null;
  },

  _setupStateChangeHandler: function(handler, delay) {
    this._clearStateChangeHandler();

    if (delay == undefined) delay = 1000;

    var that = this;
    this._stateChangeHandlerInfo = {
      _lastCallTimestamp : null,
      _object : that.formElement(),
      _func : handler
    };

    this._stateChangeHandler = function(event) {
      if (!that._stateChangeHandlerInfo) return;
      if (!event.type || !event.target || $j(event.target).is('input:submit')) return;

      if (that._stateChangeHandlerInfo._timeout) {
        clearTimeout(that._stateChangeHandlerInfo._timeout);
      }

      var funcCall = function() {
        // check required for the case when runType select change handler have already removed `this._stateChangeHandlerInfo`
        // but AJAX request for new runner haven't finished yet and `BS.EditBuildRunnerForm.setupEventHandlers`
        // haven't set up new `this._stateChangeHandlerInfo`
        if (that._stateChangeHandlerInfo) {
          that._stateChangeHandlerInfo._func();
          that._stateChangeHandlerInfo._lastCallTimestamp = new Date().getTime();
        }
      };

      var scheduleFuncCall= function() {
        that._stateChangeHandlerInfo._timeout = setTimeout(function() { funcCall(); }, delay);
      };

      //don't call func() immediately after paste, because content is not changed yet when 'paste' event occurs.
      if (event.type === "paste") {
        scheduleFuncCall();
      } else if (that._stateChangeHandlerInfo._lastCallTimestamp === null || new Date().getTime() - that._stateChangeHandlerInfo._lastCallTimestamp > delay) {
        funcCall();
      } else {
        scheduleFuncCall();
      }
    }.bindAsEventListener(this);

    $(this.formElement()).observe('keyup', this._stateChangeHandler);
    $(this.formElement()).observe('click', this._stateChangeHandler);
    $(this.formElement()).observe('paste', this._stateChangeHandler);
    $(this.formElement()).observe('change', this._stateChangeHandler);
  },

  _setupExitHandler: function() {
    this._exitHandler = function(event) {
      if (this.modified) {
        if (!this._shouldCheckForExit(event))  {
          return;
        }

        if (!Event.isLeftClick(event) || event.ctrlKey || event.altKey || event.shiftKey || event.metaKey) {
          return;
        }

        if (!confirm("Discard your changes?")) {
          Event.stop(event);
        }
      }
    }.bindAsEventListener(this);

    document.body.addEventListener("click", this._exitHandler, {capture: true});
  },

  _shouldCheckForExit: function(event) {
    var element = Event.element(event);
    if (element.closest("[showdiscardchangesmessage=true]")) {
      return true;
    }

    if (element.tagName != "A") {
      element = Event.findElement(event, "A");
    }

    if (!element || element.nodeType != 1) {
      return false;
    }

    if ("false" == element.getAttribute("showdiscardchangesmessage")) {
      return false;
    }

    // by default treat all non-js links as exit points
    return element && element.href && element.href != "#" && element.href != document.location.href + "#" && !element.target;
  },

  // Use this function if you actually need to call it several times.
  doSetUpdateStateHandlers: function(handlers) {
    this._modifiedHandlers = handlers;
    this._setupStateChangeHandler(handlers.updateState);
    if (handlers.saveState) {
      var form = this._modifiedMessageForm();
      if (form && form.save) {
        $j(form.save).on("click", handlers.saveState);
      }

      this.bindCtrlEnterHandler(handlers.saveState.bind(this));
    }
    this._setupExitHandler();
  },

  checkStateModified: function() {
    if (this._stateChangeHandler) {
      this._stateChangeHandler();
    }
  },

  removeUpdateStateHandlers: function() {
    this._clearStateChangeHandler();
    if (this._modifiedHandlers && this._modifiedHandlers.saveState) {
      var form = this._modifiedMessageForm();
      if (form && form.save) {
        $j(form.save).off("click");
      }
    }

    $j(document.body).off("click");
    this._modifiedHandlers = null;
    this._exitHandler = null;
  },

  bindCtrlEnterHandler: function(handler) {
    var f = function() {
      this._ctrlEnterHandler = function(event) {
        if (event.ctrlKey && event.keyCode == Event.KEY_RETURN) {
          handler && handler();
        }
      }.bindAsEventListener(this);

      $j(document).off("keydown.formCtrlEnter").on("keydown.formCtrlEnter", this._ctrlEnterHandler);
    }.bind(this);

    f.defer();
  },

  setReadOnly: function (exceptions) {
    this.templateBased = true;
    this._formDisabled = false; // always disable form

    var excludedClasses = {};
    var excludedNames = {};

    if (exceptions != null) {
      for (var i = 0; i < exceptions.length; i++) {
        var className = exceptions[i].className;
        var name = exceptions[i].name;
        if (className != null) {
          excludedClasses[className] = true;
        }
        if (name != null) {
          excludedNames[name] = true;
          excludedNames[BS.jQueryDropdown.namePrefix + name] = true;
          excludedNames[name + BS.jQueryDropdown.namePrefix] = true;
          excludedClasses[BS.jQueryDropdown.namePrefix + name] = true;
          excludedClasses[name + BS.jQueryDropdown.namePrefix] = true;
        }
      }
    }

    var filter = function (elem) {
      if (excludedNames[elem.name]) return false;
      var classes = elem.className.split(' ');
      for (var i = 0; i < classes.length; i++) {
        if (excludedClasses[BS.Util.trimSpaces(classes[i])]) return false;
      }
      return true;
    };

    var disabled = this.disable(filter);

    for (i = 0; i < disabled.length; i++) {
      disabled[i]._inherited = true;
    }

    this.removeUpdateStateHandlers();
  }
};

// accepts two handlers: one for session state update and one for state saving. Handler for state
// saving is optional - in this case Save button won't appear in "The changes are not yet saved" message
BS.AbstractWebForm.setUpdateStateHandlers = _.once(BS.AbstractWebForm.doSetUpdateStateHandlers);

BS.SimpleListener = {
  onBeginSave: function(form) {},

  onCompleteSave: function(form, responseXML, err, responseText) {},

  onException: function(form, e) {
    BS.Util.processError(e);
    form.setSaving(false);
    form.enable();
  },

  onUnexpectedError : function(form, responseXML, elem) {
    alert(elem.firstChild.nodeValue);
    form.setSaving(false);
    form.enable();
  },

  /**
   * @param {BS.AbstractWebForm} form
   * @param {XMLHttpRequest} xhr
   */
  onFailure: function(form, xhr) {
    if (xhr && xhr.status && xhr.responseText) {
      var message = "Error accessing server. Check for proxy and server errors.\nHTTP status: " + xhr.status + "\nResponse text: " + xhr.responseText;
      BS.Log.error(message);

      if (xhr.status == 503) {
        message = "The server is in a maintenance mode";
        var info = xhr.responseText.match(/\[Stage description: ([^\]]+)]/);
        if (info) {
          message += ":\n " + info[1];
        }
      }
      alert(message);
    }
    else {
      BS.Log.error(xhr);
      alert("Error accessing server. Check for proxy and server errors.");
    }
  },

  onRequestCancelled: function (form) {}
};

BS.ErrorsAwareListener = OO.extend(BS.SimpleListener, {
  onBeginSave: function(form) {
    form.trimSpacesInTextFields();
    form.clearErrors();
    form.hideSuccessMessages();
    form.disable();
    form.setSaving(true);
  },

  onCompleteSave: function(form, responseXML, err) {
    var errFields = $j('.advancedSetting .errorField');
    if (errFields.length > 0) {
      errFields.parents().each(function() {
        if (this._advancedOptions) {
          this._advancedOptions.showAdvanced(true, false);
        }
      });
    }

    form.setSaving(false);
    form.enable();
    if (err) {
      form.focusFirstErrorField();
    } else {
      this.onSuccessfulSave(responseXML);
    }
  },

  onSuccessfulSave: function(responseXML) {}
});


BS.StoreInSessionListener = OO.extend(BS.SimpleListener, {
  onCompleteSave: function(form, responseXML, errStatus) {
    if (!errStatus) {
      BS.XMLResponse.processModified(form, responseXML);
    }
  },

  onException: function(form, e) {
  },

  onFailure: function(form) {
  }
});


BS.AbstractPasswordForm = OO.extend(BS.AbstractWebForm, {
  publicKey: function() {
    return $F("publicKey");
  },

  serializeParameters: function() {
    var params = BS.AbstractWebForm.serializeParameters.bind(this)();
    var passwordFields = BS.Util.getPasswordInputs(this.formElement());
    if (!passwordFields) return params;
    for (var i = 0; i < passwordFields.length; i++) {
      if (BS.Util.isParameterIgnored(passwordFields[i])) continue;

      var name = passwordFields[i].name;
      var encryptedName = "encrypted" + name.charAt(0).toUpperCase() + name.substring(1);
      params += "&" + encryptedName + "=";

      if (passwordFields[i].value.length == 0) continue;

      var encryptedValue = "";
      if (passwordFields[i].getEncryptedPassword != null) {
        encryptedValue = passwordFields[i].getEncryptedPassword(this.publicKey());
      } else {
        encryptedValue = BS.Encrypt.encryptData(passwordFields[i].value, this.publicKey());
      }
      params += encryptedValue;
    }

    return params;
  }
});


BS.FormSaver = {
  /**
   * @param form
   * @param submitUrl
   * @param {BS.SimpleListener} listener
   * @param debug
   */
  save: function(form, submitUrl, listener, debug) {
    try {
      listener.onBeginSave(form);
      var params = form.serializeParameters();
      if (debug) {
        alert(params);
      }

      BS.ajaxRequest(submitUrl, {
        method: "post",

        parameters: params,

        onComplete: function(transport) {
          if (debug) {
            alert(transport.responseText);
          }

          if (transport.status === 0) {
            // usually it means user is leaving a page and nothing should be done
            listener.onRequestCancelled(form);
          } else if (!transport.responseXML) {
            listener.onCompleteSave(form, null, null, transport.responseText);
          } else {
            var responseXML = transport.responseXML;
            var err = BS.XMLResponse.processErrors(responseXML, listener);
            listener.onCompleteSave(form, responseXML, err, transport.responseText);
          }
        },
        onFailure: function(response) {
          listener.onFailure(form, response.transport);
        },
        onException: function(obj, e) {
          listener.onException(form, e);
        },
        onUnexpectedError: function(response, e) {
          listener.onUnexpectedError(form, response, e);
        }
      });
    }
    catch (e) {
      listener.onException(form, e);
    }
  }
};

BS.PasswordFormSaver = OO.extend(BS.FormSaver, {
  save: function(form, submitUrl, listener, debug) {
    var that = this;

    if (!listener.onPublicKeyExpiredError) {
      listener.onPublicKeyExpiredError = function(elem) {
        $("publicKey").value = elem.firstChild.nodeValue;
        setTimeout(function() {
          that.save(form, submitUrl, listener, debug);
        }, 100);
      }
    }

    BS.FormSaver.save(form, submitUrl, listener, debug);
  }
});

if (!BS.CustomCheckbox) {
  $j(document).ready(function() {
    new BS.CustomCheckbox();
  });
}

BS.CustomCheckbox = Class.create({
  initialize: function() {
    var $document = $j(document);
    var that = this;

    $document.find('.custom-checkbox_input').each(function() {
      if (this.disabled) {
        $j(this).parent().addClass('custom-checkbox_disabled');
      }

      that.update_state(this);
    });

    $document.on('change', '.custom-checkbox', function() {
      var checkbox = $j(this);

      if (checkbox.hasClass('custom-checkbox_disabled')) return false;

      var input = checkbox.find('.custom-checkbox_input'),
          checked = input.prop('checked');

      checkbox.toggleClass('custom-checkbox_checked custom-checkbox_focused', checked);
    });

    this.install_shift_click_interval_selection();
  },

  update_state: function(checkboxInput) {
    if (checkboxInput.checked) {
      $j(checkboxInput).parent().addClass('custom-checkbox_checked');
    }
    else {
      $j(checkboxInput).parent().removeClass('custom-checkbox_checked');
    }
  },

  install_shift_click_interval_selection: function() {

    var $document = $j(document);
    var that = this;

    var lastChanged = null;
    $document.on('click', '.custom-checkbox', function(event) {
      var checkbox = $j(this);

      if (checkbox.hasClass('custom-checkbox_disabled')) return false;

      if (event.shiftKey && lastChanged && lastChanged !== this) {
        var parent = this.closest(".group-div");
        var oldParent = lastChanged.closest(".group-div");
        if (parent === oldParent) {
          var all_boxes = Array.prototype.slice.call(parent.querySelectorAll(".custom-checkbox"));
          var inInterval = false;
          all_boxes.forEach(function(cb) {
            if (cb == checkbox[0] || cb == lastChanged) {
              // boundary
              inInterval = !inInterval;
            }
            else {
              // Change checkbox state in the interval
              if (inInterval) {
                var inputBox = $(cb).down(".custom-checkbox_input");
                inputBox.checked = !inputBox.checked;
                that.update_state(inputBox)
              }
            }
          })
        }
      }

      lastChanged = checkbox[0];
    });
  }
});