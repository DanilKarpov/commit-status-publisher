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

BS.PluginPropertiesForm = OO.extend(BS.AbstractWebForm, {

  serializeParameters: function() {
    var params = BS.Util.serializeForm(this.formElement());
    var passwordFields = BS.Util.getPasswordInputs(this.formElement());
    if (!passwordFields) return params;

    for (var i=0; i<passwordFields.length; i++) {
      var name = passwordFields[i].name;
      if (name.indexOf("prop:") != 0) continue;
      var encryptedName = "prop:encrypted:" + passwordFields[i].id;

      params += "&" + encryptedName + "=";
      var encryptedValue = $(encryptedName).value;
      if (encryptedValue == "" || passwordFields[i].value != passwordFields[i].defaultValue) {
        encryptedValue = BS.Encrypt.encryptData(passwordFields[i].value, this.formElement().publicKey.value);
      }

      params += encryptedValue;
    }

    return params;
  },

  propertiesErrorsHandler: function(id, elem) {
    BS.PluginPropertiesForm.showError(id, elem.firstChild.nodeValue);
  },

  showError: function(id, message) {
    var input = $(id),
        error = $('error_' + id);

    if (error) {
      error.innerHTML = message.escapeHTML();
    }
    if (input && input.type && (input.type == 'text' || input.type == 'password')) {
      input.addClassName('errorField');
    }
  }
});

// contains names of all multiline properties on the page
BS.MultilineProperties = {
  init: function(name, codeMirror, wrapLines, mode) {
    BS.MultilineProperties.addProperty(name, codeMirror, function(focus) {
      var textarea = document.getElementById(name);
      var $textarea = $j(textarea);
      if (codeMirror) {
        var lines = textarea.value.split('\n').length;
        var cm = BS.CodeMirror.fromTextArea(textarea, {
          lineWrapping: wrapLines,
          mode: mode,
          autofocus: focus === true,
          readOnly: textarea.disabled
        });

        $textarea.data('cm', cm);
        cm.on('change', function() {
          $textarea.trigger('cm-change', cm.getValue());
        });
        $textarea.on('cm-set-value', function (e, value) {
          cm.setValue(value);
          cm.refresh();
        });
        $textarea.on('cm-show', function (e, value) {
          cm.refresh();
        });
        if (textarea.form) {
          var onSubmit = textarea.form.onsubmit;
          if (onSubmit) {
            textarea.form.onsubmit = function() {
              cm.save();
              return onSubmit.apply(this, arguments);
            };
          }
        }
        var onKeyDown = textarea.getAttribute('onkeydown');
        if (onKeyDown != null) {
          cm.on('keydown', new Function('_', 'event', onKeyDown));
        }

        // TW-23090
        cm.on('beforeChange', function(_, change) {
          var hasNBSP = change.text.some(function(text) {
            return /\u00A0/.test(text)
          });
          if (hasNBSP) {
            var newText = change.text.map(function (text) {
              return text.replace(/\u00A0/g, ' ')
            });
            change.update(null, null, newText);
          }
        });

        var wrapToggle = document.getElementById('wrapToggle');
        wrapToggle.addEventListener('click', function() {
          wrapLines = !wrapLines;
          wrapToggle.classList[wrapLines ? 'add' : 'remove']('wrapToggleOn');
          cm.setOption('lineWrapping', wrapLines);
          BS.User.setBooleanProperty('wrapLines', wrapLines)
        });

        if ($textarea.data('editableObjId') != null) {
          BS.AvailableParams.initAutocompleteOnCMFocus(textarea);
        }
      } else {
        $textarea.off('keypress paste').on('keypress paste', function() {
          BS.MultilineProperties.sanitize(this);
        });
      }
    })
  },

  _init: function() {
    if (!this._properties) {
      this._properties = [];
    }
  },

  _findProperty: function(name) {
    for (var i=0; i<this._properties.length; i++) {
      var prop = this._properties[i];
      if (prop.name == name) {
        return prop;
      }
    }

    return null;
  },

  clearProperties: function() {
    this._properties = null;
  },

  addProperty: function(name, codeMirror, initFunc) {
    this._init();

    var found = this._findProperty(name);

    if (found) {
      found.visible = false;
      found.codeMirror = codeMirror;
      found.initFunc = initFunc;
    } else {
      var prop = {};
      this._properties.push(prop);
      prop.visible = false;
      prop.name = name;
      prop.codeMirror = codeMirror;
      prop.initFunc = initFunc;
    }
  },

  setVisible: function(name, visible) {
    var found = this._findProperty(name);
    if (found) {
      found.visible = visible;
    }
  },

  isVisible: function(name) {
    var found = this._findProperty(name);
    if (found) {
      return found.visible;
    }

    return false;
  },

  updateVisible: function() {
    var that = this;

    if (this._properties) {
      this._properties.forEach(function (prop) {
        prop.visible && that.doShow(prop.name, false);
      });
    }

    BS.VisibilityHandlers.updateVisibility('mainContent');
  },

  show: function(name, focus) {
    this.doShow(name, focus);
    BS.MultilineProperties.setVisible(name, true);
    BS.MultilineProperties.updateVisible();
  },

  doShow: function(name, focus) {
    var found = this._findProperty(name);
    if (!found) return;

    var container = $(name + '_Container');
    if (!container) return; // todo: remove property from collection

    var linkContainer = $(name + '_LinkContainer');
    var hideLinkPromise = linkContainer ? BS.Util.hide(linkContainer) : Promise.resolve();
    var noteContainer = $(name + '_NoteContainer');
    if (noteContainer) {
      noteContainer.style.opacity = 0;
      BS.Util.show(noteContainer);
      hideLinkPromise.then(function() {
        noteContainer.style.opacity = 1;
      });
    }

    var textarea = $(name);

    if (!container) return;

    var note = $('note_' + name);
    if (note && note.hasClassName('smallNote_hidden')) {
      note.removeClassName('smallNote_hidden');
    }

    if (found.initFunc && !found.inited) {
      container.style.opacity = 0;
      container.style.height = 0;
    }
    BS.Util.show(container);
    ReactUI.onShow(container, function() {
      if (found.initFunc && !found.inited) {
        found.initFunc(focus);
        found.inited = true;
        container.style.opacity = null;
        container.style.height = null;
      }

      if (!found.codeMirror) {
        container.style.width = null;
        container.style.height = null;

        if (focus && !textarea.disabled) {
          textarea.focus();
        }
      }
    });
  },

  sanitize: function(el) {
    // u00A0 is &nbsp;
    // When changing the value, cursor will jump to the end in IE and Opera which is OK since
    // this character can only appear through paste
    if (el.value.match(/\u00A0/)) {
      el.value = el.value.replace(/\u00A0/g, ' ');
    }
  }
};

Event.observe(window, "resize", function() {
  BS.MultilineProperties.updateVisible();
});