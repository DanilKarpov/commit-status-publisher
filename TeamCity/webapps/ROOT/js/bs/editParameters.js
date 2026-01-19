BS.BaseSaveParameterListener = OO.extend(BS.SaveConfigurationListener, {
  onBeginSave: function(form) {
    form.formElement().parameterName.value = BS.Util.trimSpaces(form.formElement().parameterName.value);
    form.clearErrors();
    form.hideSuccessMessages();
    form.disable();
    form.setSaving(true);
  }
});

class ParameterState {
  // Create new instances of the same class as static attributes
  static Inherited = new ParameterState("inherited");
  static UndefinedParam = new ParameterState("undefinedParam");
  static AddNew = new ParameterState("addNew");
  static Default = new ParameterState("default");

  constructor(name) {
    this.name = name
  }
}

BS.EditParameterForm = OO.extend(BS.AbstractWebForm, {
  setSaving: function(saving) {
    if (saving) {
      BS.Util.show('userParamsSaving');
    } else {
      BS.Util.hide('userParamsSaving');
    }
  },

  formElement: function() {
    return $('editParamForm');
  },

  saveParameter: function() {
    this.formElement().submitAction.value = 'updateParameter';
    var that = this;

    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.BaseSaveParameterListener, {
      onEmptyParameterNameError: function(elem) {
        $("error_parameterName").innerHTML = elem.firstChild.nodeValue.escapeHTML();
        that.highlightErrorField($('parameterName'));
      },

      onParameterSpecError: function(elem) {
        $('error_parameterSpec').innerHTML = elem.firstChild.nodeValue.escapeHTML();
        that.highlightErrorField($('parameterSpec'));
      },

      onParameterValueError: function(elem) {
        $('error_parameterValue').innerHTML = elem.firstChild.nodeValue.escapeHTML();
        that.highlightErrorField($('parameterValue'));
      },

      onPasswordConversionError: function (elem) {
        var msg = elem.firstChild.nodeValue.escapeHTML();
        if (confirm(msg)) {
          $('parameterValue').value = '';
          that.saveParameter();
        }
      },

      onCompleteSave: function (form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);

        form.enable();
        if (!err) {
          that.updateParamLists();
          BS.EditParameterDialog.close();
        }
      }
    }));
    return false;
  },

  doRemoveParameter: function(paramId, paramType) {
    var that = this;

    var url = this.formElement().action + "&submitBuildType=1&submitAction=removeParameter&removedPropertyId=" + paramId + "&paramType=" + paramType;

    BS.ajaxRequest(url, {
      onComplete: function (response) {
        var $errors = $j(response.responseXML).find("error");
        if ($errors.length > 0) {
          $errors.each(function (idx, elt) {
            alert($j(elt).text());
          });
        } else {
          that.updateParamLists();
          BS.EditParameterDialog.close();
        }
      }
    });
  },

  removeParameter: function(paramId, paramType) {
    if (!confirm("Are you sure you want to delete this parameter?")) return;
    this.doRemoveParameter(paramId, paramType);
  },

  resetParameter: function(paramId, paramType) {
    if (!confirm("Are you sure you want to reset the parameter to its template value?")) return;
    this.doRemoveParameter(paramId, paramType);
  },

  updateParamLists: function() {
    BS.reload(true);
  },

  toggleInheritedParams: function(showParams, containerId) {
    $j('#' + containerId + ' .inheritedParam').each(function() {
      if (showParams) {
        this.show();
      } else {
        this.hide();
      }
    });

    if (showParams) {
      $j('#' + containerId + ' .parametersTable').show();
    } else {
      $j('#' + containerId + ' .parametersTable').each(function() {
        if ($j(this).find('.ownParam').size() == 0) {
          $j(this).hide();
        }
      });
    }
  }
});


BS.EditParameterDialog = OO.extend(BS.AbstractModalDialog, {
  parameterInheritanceOrigin: "",
  isWarningShown: false,
  showInheritancePopup: function (elem) {
    if (BS.EditParameterDialog.isWarningShown) {
      BS.Tooltip.showMessage(elem, {shift: {x: 10, y: 18}}, BS.EditParameterDialog.getWarningMessage())
    }
  },
  hideInheritancePopup: () => BS.Tooltip.hidePopup(),

  getContainer: function() {
    return $('editParamFormDialog');
  },

  showSpecEditFields : function(shown, updateVisibility) {
    if (shown) {
      BS.Util.hide('parameterSpecHolderExpand');
      BS.Util.show('parameterSpecHolderEdit');
    } else {
      BS.Util.show('parameterSpecHolderExpand');
      BS.Util.hide('parameterSpecHolderEdit');
    }
    if (updateVisibility) {
      this.updateVisibilityHandlers();
    }
  },

  disableElement: function (element) {
    if (element) {
      Form.Element.disable(element);
    }
  },

  enableElement: function (element) {
    if (element) {
      Form.Element.enable(element);
    }
  },

  disableForInheritance: function () {
    const parameterValue = $("parameterValue");
    const submitButton = $("parameterSpecEditFormSubmit");
    const enabledElements = [parameterValue, submitButton];
    BS.EditParameterForm.enable();
    BS.EditParameterDialog.isWarningShown = true;
    BS.EditParameterForm.disable((elem) => {
      debugger;
      if (enabledElements.indexOf(elem) == -1){
        elem.addEventListener("mouseover", () => BS.EditParameterDialog.showInheritancePopup(elem));
        elem.addEventListener("mouseout", BS.EditParameterDialog.hideInheritancePopup);
        return true;
      }
      return false;
    });
    BS.EditParameterDialog.changeDisabledStatusAppearanceSettings(true);
  },

  changeDisabledStatusAppearanceSettings: function (disabled){
    const appearanceSettingsRow = document.querySelector('#appearanceSettingsRow');
    const runCustomBuildSettingsButton = document.querySelector('#runCustomBuildSettingsRow a.appearanceSettingsBtn.btn');
    if (!appearanceSettingsRow || !runCustomBuildSettingsButton){
      return
    }

    const elements = [appearanceSettingsRow, runCustomBuildSettingsButton];
    elements.forEach(el => {
      el.classList.toggle("hidden", disabled);
      el.classList.toggle("disabled", disabled);
    });
  },

  getWarningMessage: function (){
    return `Cannot edit properties of an inherited parameter. Edit this property in ${BS.EditParameterDialog.parameterInheritanceOrigin}.`
  },

  updateParameterValue: function (value, readOnly, parameterState, editParameterSpec, specValue, inheritanceOrigin) {
    BS.EditParameterDialog.parameterInheritanceOrigin = inheritanceOrigin;
    const parameterValue = $('parameterValue');
    const specParameterTypeChooser = $('specParameterTypeChooser');
    const paramType = $('paramType');
    parameterValue.value = value;
    if (!readOnly){
      Form.Element.enable(parameterValue);
      if (parameterState == ParameterState.Inherited) {
        Form.Element.disable($('parameterName'));
        Form.Element.disable($('parameterSpec'));
        BS.EditParameterDialog.disableElement(editParameterSpec);
        BS.EditParameterDialog.disableElement(specParameterTypeChooser);
        BS.EditParameterDialog.disableElement(paramType);
        $('inheritedParamName').show();
        if (specValue?.indexOf("readOnly='true'") >= 0) {
          Form.Element.disable($('parameterValue'));
        } else {
          $('parameterValue').focus();
        }

        if (specValue.length == 0) {
          BS.EditParameterDialog.disableInheritanceWarning();
        }
      } else if (parameterState == ParameterState.UndefinedParam) {
        Form.Element.disable($('parameterName'));
        Form.Element.enable($('parameterSpec'));
        BS.EditParameterDialog.enableElement(editParameterSpec);
        BS.EditParameterDialog.enableElement(specParameterTypeChooser);
        BS.EditParameterDialog.disableInheritanceWarning();
        $('parameterValue').focus();
      } else if (parameterState != ParameterState.AddNew) {
        Form.Element.enable($('parameterName'));
        Form.Element.enable($('parameterSpec'));
        BS.EditParameterDialog.enableElement(editParameterSpec);
        BS.EditParameterDialog.enableElement(specParameterTypeChooser);
        $('parameterValue').focus();
        BS.EditParameterDialog.disableInheritanceWarning();
      } else {
        Form.Element.enable($('parameterName'));
        Form.Element.enable($('parameterSpec'));
        BS.EditParameterDialog.enableElement(editParameterSpec);
        BS.EditParameterDialog.enableElement(specParameterTypeChooser);
        $('inheritedParamName').hide();
        BS.EditParameterDialog.disableInheritanceWarning();
        $('parameterName').focus();
      }
    }
  },

  disableInheritanceWarning: function() {
    BS.EditParameterDialog.isWarningShown = false;
  },

  setReadOnlyState: function (readOnly) {
    if (readOnly) {
      BS.EditParameterForm.enable();
      BS.EditParameterForm.disable();
    } else {
      BS.EditParameterForm.disable();
      BS.EditParameterForm.enable();
    }
    BS.EditParameterDialog.changeDisabledStatusAppearanceSettings(readOnly);
  },

  showDialog: function(nameEl, valueEl, paramType, inherited, readOnly, undefinedParam, specEl, redefined, localReadOnly, inheritanceOrigin) {
    BS.EditParameterForm.clearErrors();
    BS.EditParameterDialog.setReadOnlyState(readOnly);

    let parameterState;
    if (inherited){
      parameterState = ParameterState.Inherited;
    } else if (undefinedParam){
      parameterState = ParameterState.UndefinedParam;
    } else if (addNew){
      parameterState = ParameterState.AddNew;
    } else {
      parameterState = ParameterState.Default;
    }


    var name = nameEl.firstChild ? nameEl.textContent : '';
    var value = valueEl.firstChild ? valueEl.textContent : '';
    var spec = specEl.firstChild ? specEl.textContent : '';
    var addNew = name.length == 0;
    BS.Util.hide($j('.systemPropOption')[0]);
    if (this.hasTypePrefix('system', name)) {
      BS.Util.show($j('.systemPropOption')[0]);
    }

    var replaceNewLines = function(x) {
      x = x.replace(/##10##/g, "\n");
      x = x.replace(/##13##/g, "\r");
      return x;
    };

    value = replaceNewLines(value);
    spec = replaceNewLines(spec);

    $('currentName').value = name;
    $('parameterName').value = name;
    $('currentNameWithPrefix').value = name;
    $j('#paramType').val(paramType);
    $('parameterSpec').value = spec;

    $('editParamFormTitle').innerHTML = addNew ? "Add New Parameter" : (readOnly || inherited ? "View Parameter" : "Edit Parameter");
    if (redefined) {
      $j('#editParamForm .submitButton').val("Save");
    } else if (inherited && !localReadOnly) {
      $j('#editParamForm .submitButton').val("Override");
    } else if (localReadOnly) {
      $j('#editParamForm .submitButton').val("Copy");
    } else {
      $j('#editParamForm .submitButton').val("Save");
    }

    this.showSpecEditFields(spec.length > 0);
    this.showCentered();


    const showAdvancedOptions = $('showAdvancedOptions');
    const specValue = $('parameterSpec').value;
    const editParameterSpec = $('editParameterSpec');
    if (showAdvancedOptions){
      BS.EditParametersSpecDialog.showAdvancedOptions(showAdvancedOptions, $('advancedOptions'), specValue, value, readOnly, parameterState, editParameterSpec, inheritanceOrigin);
    } else {
      this.updateParameterValue(value, readOnly, parameterState, editParameterSpec, specValue, inheritanceOrigin);
    }

    this.bindCtrlEnterHandler(function() {
        BS.EditParameterForm.saveParameter();
    });

    if (readOnly) return;
    BS.AvailableParams.attachPopups($('editableObjectId').value, 'buildTypeParams');
    this.updateVisibilityHandlers();
  },

  updateVisibilityHandlers : function() {
    BS.VisibilityHandlers.updateVisibility(this.getContainer());
  },

  cancelDialog: function() {
    this.close();
  },

  completionItemSelected: function(event, ui) {
    var sliced = $j(this).data("sliced_text");
    var position = sliced.before_length + ui.item.value.length + 1;
    this.value = sliced.before + ui.item.value + '%' + sliced.after;
    $j("#parameterValue").attr({selectionStart: position,
                                selectionEnd:   position});
    return false;
  },

  removeSystemPrefix: function(str) {
    return str.replace(/^system\./, '');
  },

  removeEnvPrefix: function(str) {
    return str.replace(/^env\./, '');
  },

  /**
   * @param {String} str
   * @returns {String}
   */
  removeSystemAndEnvPrefixes: function(str) {
    return str.replace(/^((system|env)\.)*/, '');
  },

  /**
   * @param type
   * @param str
   * @returns {String}
   */
  removePrefixes: function(type, str) {
    if (type === 'system') {
      return BS.EditParameterDialog.removeEnvPrefix(str);
    } else if (type === 'env') {
      return BS.EditParameterDialog.removeSystemPrefix(str);
    } else {
      return BS.EditParameterDialog.removeSystemAndEnvPrefixes(str);
    }
  },

  /**
   * @param {jQuery()} paramTypeEl
   * @param {jQuery()} paramNameEl
   * @returns {Function}
   */
  createParamTypeChangeHandler: function(paramTypeEl, paramNameEl) {
    return function() {
      var type = paramTypeEl.val(),
          name = paramNameEl.val(),
          _name = name;
      name = this.removePrefixes(type, name);
      name = this.addTypePrefixMaybe(type, name);
      if (_name !== name) {
        $j(paramNameEl).val(name);
      }
    }.bind(BS.EditParameterDialog);
  },

  /**
   * @param {jQuery()} parameterNameEl
   * @param {jQuery()} paramTypeEl
   * @returns {Function}
   */
  createParamNameChangeHandler: function(parameterNameEl, paramTypeEl) {
    return function() {
      var text = parameterNameEl.val();
      var type = /^env\./.test(text) ? "env" : /^system\./.test(text) ? "system" : "conf";
      if (type == 'system') {
        BS.Util.show($j('.systemPropOption')[0]);
      }
      paramTypeEl.val(type).trigger("change");
    };
  },

  splitAt: function(str, index) {
    return {
      prefix: str.slice(0, index),
      suffix: str.slice(index + 1, str.length)
    };
  },

  addTypePrefixMaybe: function(type, name) {
    if (this.hasTypePrefix(type, name)) {
      return name;
    } else {
      return type + '.' + name;
    }
  },

  hasTypePrefix: function(type, str) {
    return type === 'conf'
        || str.substring(0, type.length + 1) === type + '.';
  },

  /**
   * @param event
   * @returns {boolean}
   */
  canChangeSelectValue: function(event) {
    return event.keyCode === $j.ui.keyCode.UP
        || event.keyCode === $j.ui.keyCode.DOWN
        || event.keyCode === $j.ui.keyCode.PAGE_UP
        || event.keyCode === $j.ui.keyCode.PAGE_DOWN
        || event.keyCode === $j.ui.keyCode.HOME
        || event.keyCode === $j.ui.keyCode.END
        || event.keyCode === 67 //c
        || event.keyCode === 69 //e
        || event.keyCode === 83;//s
  }
});

BS.EditParametersSpecDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  formElement: function() {
    return $("parameterSpecEditForm");
  },

  getContainer: function() {
    return $("parameterSpecEditFormDialog");
  },

  showDialog: function(spec) {
    var that = this;
    $('error_parameterSpec').update('');
    BS.Util.show("parameterSpecEditFormContentLoading");
    BS.ajaxUpdater('parameterSpecEditFormContent', this.formElement().action, {
      method: 'post',
      evalScripts : true,
      parameters : {spec : encodeURIComponent(spec), init : 1 },
      onComplete: function(transport) {
        BS.Util.hide("parameterSpecEditFormContentLoading");

        var xml = transport.responseXML;
        if (xml) {
          var error = false;
          var setErrorText = function(text) {
            $('error_parameterSpec').update(text.escapeHTML());
            error = true;
          };

          BS.XMLResponse.processErrors(xml, {
            onSPEC_ERRORError: function() {
              setErrorText('Failed to parse parameter specification');
            },
            onUNKNOWN_TYPEError: function() {
              setErrorText('Unknown parameter type');
            },
            onNO_EDITORError: function() {
              setErrorText('Specified parameter type does not support edit');
            }
          });
          if (error) {
            return;
          }
        }

        that.initializeParameterEdit();
        that.showCentered();
        that.bindCtrlEnterHandler(that.submitDialog.bind(that));
        BS.Util.reenableForm(that.formElement());
        that.updateSelectedType();
        BS.VisibilityHandlers.updateVisibility(that.formElement());
        BS.MultilineProperties.updateVisible();
      }
    });
    return false;
  },

  updateSelectedType: function() {
    var that = this;
    var v = $('specParameterTypeChooser').value;

    if (v == '') {
      v = "--not_selected--";
      var disabled = true;
    }

    var params = "type=" + v;

    const editFormSubmit = $('parameterSpecEditFormSubmit');
    if (editFormSubmit) {
      editFormSubmit.disabled = disabled;
      editFormSubmit.title = disabled ? 'Select parameter type' : '';
    }
    $('specParameterEditorContainer').refresh(null, params, function(){
      BS.VisibilityHandlers.updateVisibility(that.formElement());
      BS.MultilineProperties.updateVisible();
    });
  },

  initializeParameterEdit: function() {
    jQuery("#specParameterTypeChooser").change(this.updateSelectedType.bind(this));
  },

  closeDialog: function() {
    this.close();
  },

  submitDialog: function() {
    var that = this;

    BS.Util.show('parameterSpecEditFormSaving');
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onCompleteSave: function(form, responseXML, err) {
        BS.Util.hide('parameterSpecEditFormSaving');
        var wereErrors = BS.XMLResponse.processErrors(responseXML, {}, BS.PluginPropertiesForm.propertiesErrorsHandler);

        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
        if (wereErrors) {
          BS.Util.reenableForm(that.formElement());
          return;
        }

        var parameterSpec = responseXML.getElementsByTagName("paramter-spec")[0];
        var spec = parameterSpec.getAttribute('spec');
        if (spec) {
          $('parameterSpec').value = spec;
          BS.EditParameterDialog.showSpecEditFields(true);
          BS.EditParameterDialog.updateVisibilityHandlers();
        }
        form.close();
      }
    }));

    return false;
  },

  getParameterSpecElem: function () {
    return $('parameterSpec');
  },

  saveAdvancedOptions: function(url) {
    const form = BS.EditParameterDialog.getContainer();
    const parameterSpecElem = this.getParameterSpecElem();
    if (!$('showAdvancedOptions')){
      parameterSpecElem.value = '';
    }

    BS.Util.show('parameterSpecEditFormSaving');

    const params = BS.Util.serializeForm(form);

    BS.ajaxRequest(url, {
      method: "post",
      parameters: params,
      onComplete: function (response) {
        const responseXML = response.responseXML;
        BS.Util.hide('parameterSpecEditFormSaving');
        const wereErrors = BS.XMLResponse.processErrors(responseXML, {}, BS.PluginPropertiesForm.propertiesErrorsHandler);
        if (wereErrors) {
          BS.Util.reenableForm(form);
          return;
        }

        const parameterSpec = responseXML.getElementsByTagName("paramter-spec")[0];
        const spec = parameterSpec.getAttribute('spec');
        if (spec) {
          parameterSpecElem.value = spec;
          BS.EditParameterDialog.showSpecEditFields(true);
          BS.EditParameterDialog.updateVisibilityHandlers();
        }
        BS.EditParameterForm.saveParameter();
      }
    });

    return false;
  },

  showAdvancedOptions: function (checkbox, advancedOptionsElem, parameterSpec, parameterValue, readOnly, parameterState, editParameterSpec, inheritanceOrigin) {
    const that = this;
    const specFormUrl = $('specFormUrl').value;
    const inherited = parameterState === ParameterState.Inherited;
    BS.ajaxUpdater(advancedOptionsElem, specFormUrl, {
      method: 'post',
      evalScripts: true,
      parameters: {spec: encodeURIComponent(parameterSpec), init: 1, readOnly: readOnly, inherited: inherited},
      onComplete: function (transport) {
        BS.Util.hide("parameterSpecEditFormContentLoading");

        const xml = transport.responseXML;
        if (xml) {
          let error = false;

          BS.XMLResponse.processErrors(xml, {
            onSPEC_ERRORError: function () {
              error = true;
            },
            onUNKNOWN_TYPEError: function () {
              error = true;
            },
            onNO_EDITORError: function () {
              error = true;
            }
          });
          if (error) {
            return;
          }
        }

        const specParameterTypeChooser = $('specParameterTypeChooser');
        if (specParameterTypeChooser.value == ''){
          specParameterTypeChooser.value = "text"
        }
        that.initializeParameterEdit();
        const specValue = $('parameterSpec').value;
        BS.EditParameterDialog.updateParameterValue(parameterValue, readOnly, parameterState, editParameterSpec, specValue, inheritanceOrigin);
        that.bindCtrlEnterHandler(that.submitDialog.bind(that));
        const container = BS.EditParameterDialog.getContainer();
        BS.Util.reenableForm(container);
        that.updateSelectedType();
        BS.VisibilityHandlers.updateVisibility(container);
        BS.MultilineProperties.updateVisible();

        if (that.shouldShowCustomDialogSettings()){
          that.showCustomDialogSettings();
        }
        BS.AvailableParams.attachPopups($('editableObjectId').value, 'buildTypeParams');
      }
    });
  },

  getCustomBuildSettingsElements : () => document.getElementsByClassName('customBuildSettings'),

  getAppearanceSettingsRow: () =>
    $('appearanceSettingsRow'),

  isDisabled: (event) => event?.target?.closest('.disabled'),

  showCustomDialogSettings: function (event) {
    if (BS.EditParametersSpecDialog.isDisabled(event)){
      return false;
    }
    const customBuildSettingsElems = this.getCustomBuildSettingsElements();
    const appearanceSettingsRow = this.getAppearanceSettingsRow();
    appearanceSettingsRow.hide();
    for (elem of customBuildSettingsElems){
      elem.show();
    }

    return true;
  },

  resetCustomDialogSettings: function (event) {
    if (BS.EditParametersSpecDialog.isDisabled(event)){
      return false;
    }
    const customBuildSettingsElems = this.getCustomBuildSettingsElements();
    const appearanceSettingsRow = this.getAppearanceSettingsRow();
    appearanceSettingsRow.show();
    for (elem of customBuildSettingsElems) {
      const input = elem.querySelector("input");
      if (input?.type === "checkbox") {
        input.checked = false;
      } else {
        input?.clear();
      }
      elem.querySelector("textarea")?.clear();
      const dropdownValue = elem.querySelector("select");
      if (dropdownValue) {
        dropdownValue.value = "normal";

      }
      elem.hide();
    }

    return true;
  },

  shouldShowCustomDialogSettings: function (){
    const parameterSpecElem = this.getParameterSpecElem();
    if (!parameterSpecElem){
      return false;
    }

    if (parameterSpecElem.value.includes("display") && !parameterSpecElem.value.includes("display='normal'")){
      return true;
    }
    if (parameterSpecElem.value.includes("label")){
      return true;
    }
    if (parameterSpecElem.value.includes("description")){
      return true;
    }
    return !!parameterSpecElem.value.includes("readOnly");
  }


}));
