BS.SaveGeneralBuildTypeInfoListener = OO.extend(BS.SaveConfigurationListener, {
  _invalidBuildTypeNameError: function (elem) {
    if ($("errorName")) {
      $("errorName").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
      this.getForm().highlightErrorField($("name"));
    } else {
      alert(elem.firstChild.nodeValue);
    }
  },

  _invalidBuildTypeIdError: function (elem) {
    if ($("errorExternalId")) {
      $("errorExternalId").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
      this.getForm().highlightErrorField($("externalId"));
    } else {
      alert(elem.firstChild.nodeValue);
    }
  },

  onEmptyNameError: function (elem) {
    this._invalidBuildTypeNameError(elem);
  },

  onInvalidNameError: function (elem) {
    this._invalidBuildTypeNameError(elem);
  },

  onCannotRenameError: function (elem) {
    this._invalidBuildTypeNameError(elem);
  },

  onEmptyIdError: function (elem) {
    this._invalidBuildTypeIdError(elem);
  },

  onInvalidValueError: function (elem) {
    alert(elem.firstChild.nodeValue);
  },

  onInvalidIdError: function (elem) {
    this._invalidBuildTypeIdError(elem);
  },

  onDuplicateIdError: function (elem) {
    this._invalidBuildTypeIdError(elem);
  },

  onInvalidBuildNumberFormatError: function (elem) {
    if ($("errorBuildNumberFormat")) {
      $("errorBuildNumberFormat").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
      this.getForm().highlightErrorField($("buildNumberFormat"));
    } else {
      alert(elem.firstChild.nodeValue);
    }
  },

  onInvalidBuildCounterError: function (elem) {
    if ($("errorBuildCounter")) {
      $("errorBuildCounter").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
      this.getForm().highlightErrorField($("buildCounter"));
    } else {
      alert(elem.firstChild.nodeValue);
    }
  },

  onInvalidTimeoutValueError: function (elem) {
    if ($("errorExecutionTimeout")) {
      $("errorExecutionTimeout").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
      this.getForm().highlightErrorField($("executionTimeout"));
    } else {
      alert(elem.firstChild.nodeValue);
    }
  },

  onInvalidMaxBuildsValueError: function (elem) {
    if ($("errorMaxBuilds")) {
      $("errorMaxBuilds").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
      this.getForm().highlightErrorField($("maxBuilds"));
    } else {
      alert(elem.firstChild.nodeValue);
    }
  },

  onInvalidMaxBuildsPerBranchValueError: function (elem) {
    if ($("errorMaxBuildsPerBranch")) {
      $("errorMaxBuildsPerBranch").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
      this.getForm().highlightErrorField($("maxBuildsPerBranch"));
    } else {
      alert(elem.firstChild.nodeValue);
    }
  },

  invalidBranchFilter: function (elem) {
    if ($("errorBranchFilter")) {
      $("errorBranchFilter").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
    } else {
      alert(elem.firstChild.nodeValue);
    }
  },

  onError: function (form, e) {
    alert(e);
  }
});

BS.BaseEditBuildTypeForm = OO.extend(BS.AbstractWebForm, {
  enable: function () {
    var filter = function (elem) {
      return !elem._inherited;
    };
    BS.AbstractWebForm.enable.call(this, filter);
  },

  showCustomItemDslWithValues: function (version, portable, controlId) {
    BS.Util.show(this.savingIndicator());
    BS.EditDsl
      .customLoadDslFragment(version, portable)
      .catch(() => setTimeout(BS.EditDsl.closeEditDsl, 1, controlId))
      .finally(() => {
        BS.Util.hide(this.savingIndicator());
        BS.EditDsl.showEditDslPanel();
      });
    },

  showItemDslWithValues: function (version, portable, className, controlId, uiPanelId, dslEditorId) {
    $j("#showDSL").val("item");
    $j("#showDSLVersion").val(version);
    $j('#showDSLPortable').val(portable ? 'true' : 'false');

    return this._showItemDsl(true, controlId, uiPanelId, dslEditorId);
  },

  showBuildTypeDslWithValues: function (version, portable, className, controlId, uiPanelId, dslEditorId) {
    $j("#buildTypeShowDSL").val("buildType");
    $j("#buildTypeShowDSLVersion").val(version);
    $j('#buildTypeShowDSLPortable').val(portable ? 'true' : 'false');
    $j('#submitBuildType').val('');

    return this._showItemDsl(true, controlId, uiPanelId, dslEditorId);
  },

  _showItemDsl: function (skipShowDialog, controlId, uiPanelId, dslEditorId) {
    var that = this;
    this.removeUpdateStateHandlers();
    this.clearErrors();
    BS.PasswordFormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onFailedTestConnectionError: function (elem) {
        var text = "";
        if (elem.firstChild) {
          text = elem.firstChild.nodeValue;
        }
        ReactUI.closeEditDsl(controlId, uiPanelId, dslEditorId)
      },

      onCompleteSave: function (form, responseXML, err) {
        var wereErrors = BS.XMLResponse.processErrors(responseXML, {}, that.propertiesErrorsHandler);
        if (!wereErrors) {
          ReactUI.storeDslFragment(new XMLSerializer().serializeToString(responseXML));
          BS.EditDsl.showEditDslPanel(uiPanelId, dslEditorId);
        } else {
          ReactUI.closeEditDsl(controlId, uiPanelId, dslEditorId);
        }

        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, false);
        form.enable();

        BS.MultilineProperties.updateVisible();
      },

      onUnexpectedError: function(form, responseXML, elem){
        ReactUI.storeDslFragment(new XMLSerializer().serializeToString(responseXML));
        BS.EditDsl.showEditDslPanel(uiPanelId, dslEditorId);

        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, false);

        form.enable();

        BS.MultilineProperties.updateVisible();
      }
    }));
    return false;
  }
});

BS.EditBuildTypeForm = OO.extend(BS.BaseEditBuildTypeForm, {
  formElement: function () {
    return $('editBuildTypeForm');
  },

  setupEventHandlers: function () {
    var that = this;
    this.setUpdateStateHandlers({
                                  updateState: function () {
                                    that.saveInSession();
                                  },

                                  saveState: function () {
                                    that.submitBuildType();
                                  }
                                });
  },

  saveInSession: function () {
    $("submitBuildType").value = 'storeInSession';

    BS.PasswordFormSaver.save(this, this.formElement().action, BS.StoreInSessionListener);
  },

  submitBuildType: function () {
    var that = this;
    $("buildTypeShowDSL").value = '';
    $("submitBuildType").value = 'store';

    BS.PasswordFormSaver.save(this, this.formElement().action, OO.extend(BS.SaveGeneralBuildTypeInfoListener, {
      getForm: function () {
        return that;
      },

      onCompleteSave: function (form, responseXML, err) {
        BS.SaveGeneralBuildTypeInfoListener.onCompleteSave(form, responseXML, err);

        if (!err) {
          var externalIdInput = $j("#externalId"),
              originalId = externalIdInput.attr("originalId"),
              newId = externalIdInput.val();
          if (newId != originalId) {
            var currentUrl = window.location.href;
            window.location.href = currentUrl.replace("id=buildType:" + originalId, "id=buildType:" + newId)
                .replace("id=template:" + originalId, "id=template:" + newId);
          } else {
            BS.reload(true);
          }
        }
      }
    }), false);

    return false;
  }
});

BS.EditVcsRootsForm = OO.extend(BS.BaseEditBuildTypeForm, {
  formElement: function () {
    return $('editVcsSettingsForm');
  },

  detachVcsRoot: function (vcsRootId) {
    if (confirm("Are you sure you want to detach this VCS root?")) {
      BS.ajaxRequest(this.formElement().action, {
        parameters: "detachVcsRoot=" + vcsRootId,
        onComplete: function () {
          BS.EditVcsRootsForm.update();
        }
      })
    }
  },

  setupEventHandlers: function () {
    var that = this;
    this.setUpdateStateHandlers({
                                  updateState: function () {
                                    that.saveInSession();
                                  },

                                  saveState: function () {
                                    that.applyVcsSettings();
                                  }
                                });
  },

  saveInSession: function () {
    $("submitBuildType").value = 'storeInSession';

    BS.FormSaver.save(this, this.formElement().action, BS.StoreInSessionListener);
  },

  applyVcsSettings: function () {
    $("buildTypeShowDSL").value = '';
    $("submitBuildType").value = 'store';
    $('doApplyVcsSettings').value = 'true';
    BS.Util.show('applyVcsSettingsProgress');
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.SaveGeneralBuildTypeInfoListener, {
      onCompleteSave: function (form, responseXML, err) {
        $('doApplyVcsSettings').value = 'false';
        BS.Util.hide('applyVcsSettingsProgress');
        BS.SaveGeneralBuildTypeInfoListener.onCompleteSave(form, responseXML, err);

        if (!err) {
          BS.EditVcsRootsForm.update();
        }
      }
    }));

    return false;
  },

  updateCheckoutDirectoryWarning: function () {
    var show = $('cleanBuild').checked;
    if (show) {
      $('deletionWarning').innerHTML = $('deletionWarning').innerHTML.gsub("might be", "will be");
    }
    else {
      show = $('checkoutType').selectedIndex < 2;
      $('deletionWarning').innerHTML = $('deletionWarning').innerHTML.gsub("will be", "might be");
    }

    if (BS.Util.trimSpaces($('checkoutDir').value) == '') {
      show = false;
    }
    $('deletionWarning').style.display = show ? 'block' : 'none';

    BS.VisibilityHandlers.updateVisibility('mainContent');
  },

  update: function () {
    this.enable();
    this.removeUpdateStateHandlers();
    BS.reload(true);
  },

  updateCheckoutSharing: function () {
    var customCheckout = $j('#customCheckout'),
        pathField = $j("#checkoutDir"),
        autoCheckout = $j("#autoCheckout");

    if (customCheckout.is(":visible")) {
      this._checkoutDir = pathField.val();
      pathField.val("");
    } else {
      pathField.val(this._checkoutDir || "");
    }

    customCheckout.toggle();
    autoCheckout.toggle();
    BS.VisibilityHandlers.updateVisibility(pathField[0]);
  }
});


BS.EditBuildRunnerForm = OO.extend(BS.BaseEditBuildTypeForm, OO.extend(BS.PluginPropertiesForm, {
  Controls: null, // see container.tag

  formElement: function () {
    return $('editBuildTypeForm');
  },

  setupCtrlEnterForTextareas: function (settingsId) {
    var that = this;
    $j('#editBuildTypeForm textarea').each(function () {
      var ctrl = false;
      $j(this).keydown(function (event) {
        if (event.keyCode === $j.ui.keyCode.CONTROL) {
          ctrl = true;
        } else if (ctrl && event.keyCode === $j.ui.keyCode.ENTER) {
          that.submitBuildRunner(settingsId)
        }
      }).keyup(function (event) {
                 if (event.keyCode === $j.ui.keyCode.CONTROL) {
                   ctrl = false;
                 }

               });
    });
  },

  setupEventHandlers: function (settingsId) {
    var that = this;

    this.setUpdateStateHandlers({
                                  updateState: function () {
                                    that.saveInSession();
                                  },

                                  saveState: function () {
                                    that.submitBuildRunner(settingsId);
                                  }
                                });
  },

  saver: function (validationRequired) {
    return this.Controls.createFormSaver(null, validationRequired);
  },

  saveInSession: function () {
    this.saver(false).save(this, this.formElement().action + "&submitBuildType=storeInSession", BS.StoreInSessionListener);
  },

  submitBuildRunner: function (settingsId) {
    var that = this;

    this.saver(true).save(this, this.formElement().action + "&submitBuildType=store", OO.extend(BS.SaveGeneralBuildTypeInfoListener, {

      onInvalidIdError: function (elem) {
        $j("#error_newRunnerId").html(elem.firstChild.nodeValue);
        that.highlightErrorField(that.formElement().newRunnerId);
      },

      onDuplicateIdError: function (elem) {
        this.onInvalidIdError(elem);
      },

      onCompleteSave: function (form, responseXML, err) {
        that.setSaving(false);
        var wereErrors = BS.XMLResponse.processErrors(responseXML, {}, that.propertiesErrorsHandler) || err;

        if (wereErrors) {
          that.enable();
          that.focusFirstErrorField();
        } else {
          setTimeout(function () {
            document.location.href = 'editBuildRunners.html?init=1&id=' + settingsId;
          }, 100);
        }
      }
    }));

    return false;
  }
}));

BS.BuildRunnerIdGenerator = {
  install: function (unavailableStepIds) {
    const nameField = document.getElementById('buildStepName');
    const idField = document.getElementById('newRunnerId');

    function isAlreadyTaken(id) {
      for(let takenId of unavailableStepIds) {
        if (takenId == id) {
          return true;
        }
      }
      return false;
    }

    function updateIdFromName() {
      if (idField.disabled) {
        return;
      }

      let generatedValue = idField.getAttribute("generated");
      if (!nameField.value) {
        // Reset ID to original value if the name field is cleared and ID was not modified after that
        if (idField.defaultValue && idField.value == generatedValue) {
          idField.value = idField.defaultValue;
        }
        idField.removeAttribute("generated");
        return;
      }

      if (generatedValue) {
        // the field what changed manually, after some generation
        // keep user modifications
        if (idField.value && generatedValue != idField.value) {
          return;
        }
      }
      else {
        // There was a manual change before any generation at all,
        // keep user modifications
        if (idField.defaultValue && idField.value && idField.defaultValue != idField.value) {
          // the field what changed manually, keep the current value
          return;
        }
      }


      const base = nameField.value.replace(/\W+/g, ' ').trim().replace(/\W+/g, '_').substring(0, 80);
      let counter = 1;
      let generated = base;
      while(isAlreadyTaken(generated)) {
        generated = base + "_" + (counter++);
      }

      if (generated != "") {
        idField.value = generated;
        idField.setAttribute("generated", generated);
      }
    }

    nameField.addEventListener("keyup", updateIdFromName);
  }
};



BS.GeneralRequirementsForm = OO.extend(BS.BaseEditBuildTypeForm, {
  formElement: function () {
    return $('editGeneralRequirementsForm');
  },

  updateGeneralRequirements: function () {
    $('updateGeneralRequirements').value = 'updateGeneralRequirements';
    var that = this;
    BS.PasswordFormSaver.save(this, this.formElement().action, OO.extend(BS.SaveConfigurationListener, {
      getForm: function () {
        return that;
      },

      _baseErrorHandle: function (elem, errorClassId) {
        if ($(errorClassId)) {
          $(errorClassId).innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        } else {
          alert(elem.firstChild.nodeValue);
        }
      },

      onInvalidCpuCountBoundsError: function(elem) {
        this._baseErrorHandle(elem, "errorCpuCounts")
      },

      onInvalidMemorySizeBoundsError: function(elem) {
        this._baseErrorHandle(elem, "memorySizeError")
      },

      onCompleteSave: function (form, responseXML, err) {
        BS.SaveConfigurationListener.onCompleteSave(form, responseXML, err);
        if (!err) {
          BS.reload(true);
        }
      }


    }), false);
    return false;
  },

  showHideOsSpecification: function () {
    var osOptions = $('operatingSystemsOptions');
    if ($('osSpecification').value == "specified") {
      osOptions.show();
    } else {
      osOptions.hide();
    }
  },

  createAutocompletionSource: function (baseUrl, parameterName, fieldId) {
    var that = this;
    return function (request, response) {
      var term = request.term;
      var separator = baseUrl.indexOf('?') > 0 ? "&" : "?";
      var url = baseUrl + separator + 'what=value&term=' + encodeURIComponent(term) + '&name=' + encodeURIComponent(parameterName);
      $j.getJSON(url, function (data) {
        BS.Util.fadeOutAndDelete(BS.Util.escapeId(that.getLoadingImageId(fieldId)));
        response(data);
      });
    }
  },

  getLoadingImageId: function (fieldId) {
    return $j(BS.Util.escapeId(fieldId)).attr('id') + '_compl_loading_img';
  }

});

BS.RequirementsForm = OO.extend(BS.BaseEditBuildTypeForm, {
  formElement: function () {
    return $('editRequirement');
  },

  saveRequirement: function () {
    this.clearErrors();

    $('submitAction').value = 'updateRequirement';
    var that = this;

    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.BaseSaveParameterListener, {
      onEmptyParameterNameError: function (elem) {
        $("error_parameterName").innerHTML = elem.firstChild.nodeValue;
        that.highlightErrorField($('parameterName'));
      },

      onEmptyParameterValueError: function (elem) {
        $("error_parameterValue").innerHTML = elem.firstChild.nodeValue;
        that.highlightErrorField($('parameterValue'));
      },

      onInvalidParameterValueError: function (elem) {
        $("error_parameterValue").innerHTML = elem.firstChild.nodeValue.replace(/(\n\n)+/g, '<br/>').replace(/ /g, '&nbsp;'); // workaround for regex errors
        that.highlightErrorField($('parameterValue'));
      },

      onSimilarRequirementExistsError: function (elem) {
        $("errorSimilarRequirementExists").innerHTML = elem.firstChild.nodeValue;
      },

      onCompleteSave: function (form, responseXML, err) {
        BS.SaveConfigurationListener.onCompleteSave(form, responseXML, err);
        if (!err) {
          BS.EditRequirementDialog.close();
          BS.reload(true);
        }
      }
    }));

    return false;
  },

  doRemoveRequirement: function (paramId) {
    var url = this.formElement().action + "&submitBuildType=1&submitAction=removeRequirement&removedReqParameterId=" + paramId;

    BS.ajaxRequest(url, {
      onComplete: function () {
        BS.reload(true);
      }
    });

  },

  removeRequirement: function (paramId) {
    if (!confirm("Are you sure you want to delete this requirement?")) return;
    this.doRemoveRequirement(paramId);
  },

  resetRequirement: function (paramId) {
    if (!confirm("Are you sure you want to reset the requirement to its template definition?")) return;
    this.doRemoveRequirement(paramId);
  }
});


BS.EditRequirementDialog = OO.extend(BS.AbstractModalDialog, {

  parameterValueRequired: {},
  parameterCanBeEmpty: {},

  myHiddenOption: null,

  /**
   * @param settings map from parameter type to the need to show 'value' field
   */
  setParameterValueRequired: function (settings) {
    this.parameterValueRequired = settings;
  },

  /**
   * @param settings map from parameter type to the need to have the value field non-empty
   */
  setParameterCanBeEmpty: function (settings) {
    this.parameterCanBeEmpty = settings;
  },

  createFindNameFunction: function (baseUrl) {
    var that = this;
    return function (request, response) {
      var term = request.term;
      var separator = baseUrl.indexOf('?') > 0 ? "&" : "?";
      var url = baseUrl + separator + 'what=name&term=' + encodeURIComponent(term);
      $j.getJSON(url, function (data) {
        BS.Util.fadeOutAndDelete(BS.Util.escapeId(that.getLoadingImageId('parameterName')));
        response(data);
      });
    }
  },

  createFindValueFunction: function (baseUrl) {
    var that = this;
    return function (request, response) {
      var term = request.term;
      var parameterName = $j("#parameterName").val();
      var separator = baseUrl.indexOf('?') > 0 ? "&" : "?";
      var url = baseUrl + separator + 'what=value&term=' + encodeURIComponent(term) + '&name=' + encodeURIComponent(parameterName);
      $j.getJSON(url, function (data) {
        BS.Util.fadeOutAndDelete(BS.Util.escapeId(that.getLoadingImageId('parameterValue')));
        response(data);
      });
    }
  },

  getLoadingImageId: function (fieldId) {
    return $j(BS.Util.escapeId(fieldId)).attr('id') + '_compl_loading_img';
  },

  showLoadingImage: function (fieldjQuerySelector) {
    var that = this;
    return function () {
      var position = $j(fieldjQuerySelector).position();
      var spinnerId = that.getLoadingImageId(fieldjQuerySelector);
      return $j("<i>")
          .attr("id", spinnerId)
          .attr("className", "icon-refresh icon-spin ring-loader-inline")
          .css({width: 16,
                 height: 16,
                 position: 'absolute',
                 left: position.left + $j(fieldjQuerySelector).outerWidth(true) + 2,
                 top: position.top + 2})
          .insertAfter(fieldjQuerySelector);
    };
  },

  showSlowly: function (query) {
    return function (event, ui) {
      $j(query).fadeIn('slow', function () {
      });
    };
  },

  getContainer: function () {
    return $('editRequirementDialog');
  },

  showDialog: function (id, name, value, reqType, inherited, enforced) {
    BS.RequirementsForm.enable();
    BS.RequirementsForm.clearErrors();

    $('currentName').value = name;
    $('parameterName').value = name;
    $('parameterValue').value = value;
    $('requirementId').value = id;

    if (reqType != 'any') {
      var hiddenOption = $j("#requirementType option[value='any']")[0];
      if (hiddenOption) {
        var hiddenOptionIdx = hiddenOption.index;
        this.myHiddenOption = hiddenOption;
        $('requirementType').remove(hiddenOptionIdx);
      }
    } else {
      if (this.myHiddenOption) {
        $('requirementType').add(this.myHiddenOption);
        this.myHiddenOption = null;
      }
    }
    this.selectRequirement($('requirementType'), reqType);


    if (enforced) {
      $('editRequirementTitle').innerHTML = "View ";
    } else {
      $('editRequirementTitle').innerHTML = name.length == 0 ? "Add " : "Edit ";
    }
    $('editRequirementTitle').innerHTML += this.titleName();

    this.showCentered();
    this.installNameCompleter();
    this.installValueCompleter();

    if (inherited || enforced) {
      if (enforced) {
        Form.Element.disable($('requirementType'));
        Form.Element.disable($('parameterValue'));
      }
      Form.Element.disable($('parameterName'));
      $('inheritedParamName').show();
    } else {
      Form.Element.enable($('parameterName'));
      Form.Element.enable($('requirementType'));
      Form.Element.enable($('parameterValue'));
      $('inheritedParamName').hide();
      $('parameterName').focus();
    }
  },

  installNameCompleter: function() {
    $j("#parameterName").autocomplete("readTerm");
    $j('#parameterName').placeholder("refresh");
  },

  installValueCompleter: function() {
    $j("#parameterValue").autocomplete("readTerm");
    $j("#parameterValue").autocomplete({close: function (event, ui) {
        $j('#parameterValue').placeholder("refresh");
      }});
    $j('#parameterValue').placeholder("refresh");
  },

  titleName: function() {
    return "Requirement";
  },

  selectRequirement: function (requirementTypeElement, type) {
    var i;
    for (i = 0; i < requirementTypeElement.options.length; i++) {
      if (requirementTypeElement.options[i].value === type) {
        requirementTypeElement.selectedIndex = i;
        BS.jQueryDropdown(requirementTypeElement).ufd("changeOptions");
        this.requirementChanged(requirementTypeElement);
        return;
      }
    }
    BS.jQueryDropdown(requirementTypeElement).ufd("changeOptions");
    requirementTypeElement.selectedIndex = 0;
    requirementTypeElement.value = requirementTypeElement.options[0].value;
    this.requirementChanged(requirementTypeElement);
  },

  requirementChanged: function (requirementTypeElement) {
    if (this.parameterValueRequired[requirementTypeElement.value]) {
      BS.Util.show('editParameterValue');
    } else {
      BS.Util.hide('editParameterValue');
    }
    $j('#parameterValue').placeholder("refresh");
  },

  cancelDialog: function () {
    this.close();
    BS.Util.hide("parameterNameAutocompleteLoading");
    BS.Util.hide("parameterValueAutocompleteLoading");
  },

  afterClose: function () {
    $j("#parameterName").autocomplete("close");
    $j("#parameterValue").autocomplete("close");
  }
});


BS.EditBuildStepConditionDialog = OO.extend(BS.EditRequirementDialog, {
  titleName: function() {
    return "Parameter-based Execution Condition";
  },

  installValueCompleter: function() {
    BS.EditRequirementDialog.installValueCompleter.call(this);
    $j("#parameterValue").attr('placeholder', '');
  },


  validate: function(form) {
    var isValid = true;
    if (!form.parameterName.value.trim()) {
      $('error_parameterName').innerHTML = "parameter name is required";
      isValid = false;
    }
    else {
      $('error_parameterName').innerHTML = "";
    }

    if (this.parameterValueRequired[form.requirementType.value]) {
      if (!this.parameterCanBeEmpty[form.requirementType.value] && !form.parameterValue.value.trim()) {
        $('error_parameterValue').innerHTML = "value is required";
        isValid = false;
      }
      else {
        $('error_parameterValue').innerHTML = "";
      }
    }
    else {
      $('error_parameterValue').innerHTML = "";
      form.parameterValue.value = "";
    }
    return isValid;
  },

  saveCondition: function (form) {
    if (!this.validate(form)) {
      return false;
    }
    if (this._targetRow) {
      // Edit
      BS.BuildStepConditionsList.updateRowParams(
        this._targetRow,
        form.parameterName.value.trim(),
        form.requirementType.value,
        form.parameterValue.value
      );
      this._targetRow = null;
    }
    else {
      // Add new
      BS.BuildStepConditionsList.addConditionRow(
        form.parameterName.value.trim(),
        form.requirementType.value,
        form.parameterValue.value
      );
    }

    BS.EditBuildRunnerForm.saveInSession();
    this.close();
    return false;
  },

  editConditionRow: function(element) {
    var row = $j(element).closest(".buildStepCondition")[0];
    var input = row.querySelector(".buildStepCondition__input");
    if (!input) {
      return;
    }
    this._targetRow = row;

    this.showDialog(
      '', // id from BS.EditRequirementDialog.showDialog
      input.getAttribute('data-pname'),
      input.getAttribute('data-pvalue'),
      input.getAttribute('data-rtype'));
  }
});


BS.BuildStepConditionsList = {
  addConditionRow: function(parameterName, requirementType, parameterValue, userDescription) {
    var rowTemplate = $('buildStepConditionRowTemplate').innerHTML;

    var tmp = document.createElement("div");
    tmp.innerHTML = rowTemplate;
    this.updateRowParams(tmp.firstElementChild, parameterName, requirementType, parameterValue, userDescription);

    $j(".buildStepConditionsList").append(tmp.firstElementChild);
    document.querySelector(".buildStepConditions").style.display = '';
  },

  updateRowParams: function(tmp, parameterName, requirementType, parameterValue, userDescription) {
    var input = tmp.querySelector(".buildStepCondition__input");
    input.value = parameterName + "|" + requirementType + "|" + parameterValue;
    input.setAttribute('data-pname', parameterName);
    input.setAttribute('data-rtype', requirementType);
    input.setAttribute('data-pvalue', parameterValue);

    if (!userDescription) {
      if (!parameterValue) {
        parameterValue = "[empty]";
      }
      userDescription = parameterName + " " + requirementType + " " + parameterValue;
    }
    tmp.querySelector(".buildStepCondition__description").innerText = userDescription;
  },

  editConditionRow: function(element) {
    BS.EditBuildStepConditionDialog.editConditionRow(element);
  },

  addOnlyDefaultBranch: function() {
    this.addConditionRow('teamcity.build.branch.is_default', 'equals', 'true');
    BS.EditBuildRunnerForm.saveInSession();
  },

  addSkipIfPersonal: function() {
    this.addConditionRow('env.BUILD_IS_PERSONAL', 'does-not-equal', 'true',
      'env.BUILD_IS_PERSONAL does not equal true');
    BS.EditBuildRunnerForm.saveInSession();
  },

  addSpecificBranch: function() {
    this.addConditionRow('teamcity.build.branch', 'equals', 'release');
    BS.EditBuildRunnerForm.saveInSession();
  },

  deleteConditionRow: function(link) {
    BS.confirmDialog.show({
      title: "Delete condition",
      text: "Are you sure you want to delete this condition?",
      actionButtonText: "Yes",
      action: function () {
        $(link).up(".buildStepCondition").remove();
        if (!document.querySelector(".buildStepConditionsList").childNodes.length) {
          $j(".buildStepConditions").hide();
        }

        BS.EditBuildRunnerForm.saveInSession();
      }
    });
  }
};


BS.VcsRootsUtil = {
  attachVcsRoot: function (settingsId, rootId) {
    BS.ajaxRequest(window['base_uri'] + "/admin/editBuildTypeVcsRoots.html", {
      parameters: "id=" + settingsId + "&vcsRootId=" + rootId + "&submitBuildType=store&doAttach=true",
      onComplete: function (transport) {
        BS.XMLResponse.processRedirect(transport.responseXML);
      }
    });

    return false;
  }
};

BS.ArtifactDependencyForm = OO.extend(BS.DialogWithProgress, OO.extend(BS.BaseEditBuildTypeForm, {
  controlId: 'adDsl',

  getContainer: function () {
    return $('artifactDependencyFormDialog');
  },

  showArtifactDepDSLWithValues: function(version, portable, controlId, id1, id2){
    var oldVal = $j("input[name='saveArtifactDependency']").val();
    $j("input[name='saveArtifactDependency']").val('');
    $j("#showArtifactDSL").val("item");
    $j("#showArtifactDSLVersion").val(version);
    $j('#showArtifactDSLPortable').val(portable ? 'true' : 'false');
    this.prepareRevisionRuleParams();
    this._showItemDsl(true, controlId, id1, id2);
    $j("input[name='saveArtifactDependency']").val(oldVal);
  },

  formElement: function () {
    return $('artifactDependencyForm');
  },

  resetDependency: function(id) {
    if(!confirm('Are you sure you want to reset the artifact dependency to its template definition?')) return;
    this.hideSuccessMessages();
    this.setSaving(true);
    BS.ajaxRequest(this.formElement().action, {
      parameters: "artDepDelete=" + id,
      onSuccess: function () {
        BS.reload(true);
      }
    });
  },

  removeDependencies: function (ids) {
    if (!BS.EditDepsUtil.confirmDepsRemove(ids.length, "remove")) return;

    this.hideSuccessMessages();
    this.setSaving(true);
    var removeUrl = this.formElement().action;
    BS.ajaxRequest(removeUrl, {
      parameters: "artDepDelete=" + ids.join("&artDepDelete=") + "&checkDepParams=true",
      onSuccess: function (transport) {
        BS.XMLResponse.processErrors(transport.responseXML, {
          onHaveDepParamsError: function (elem) {
            if (confirm("The following parameters will be unavailable after dependenc" + (ids.length == 1 ? 'y' : 'ies') + " remove:"
              + "\n" + elem.firstChild.nodeValue
              + "\n\nDo you want to continue?")) {
              BS.ajaxRequest(
                removeUrl, {
                  parameters: "artDepDelete=" + ids.join("&artDepDelete="),
                  onSuccess: function () {
                    BS.reload(true);
                  }
                });
            }
          }
        });
        BS.reload(true);
      }
    });
  },

  refreshDialog: function () {
    $('artifactDependencyDialog').refresh(null, "noCacheRnd=" + Math.random(), function () {
      BS.ArtifactDependencyForm.showCentered();
      BS.ArtifactDependencyForm.updateTargetDirectoryWarning();
    });
  },

  dependenciesSelected: function () {
    return BS.EditDepsUtil.itemsSelected($('artifactDeps'), "depId");
  },

  getSelectedDeps: function () {
    return BS.EditDepsUtil.getSelectedItems($('artifactDeps'), "depId");
  },

  editDependency: function (event, id) {
    if (BS.EditDepsUtil.eventTargetIsLink(event)) return true;
    this.hideSuccessMessages();
    this.showProgress("Loading...");
    BS.ajaxRequest(this.formElement().action, {
      parameters: "artDepEdit=" + id,
      onSuccess: function () {
        BS.ArtifactDependencyForm.refreshDialog();
      }
    });
  },

  addDependency: function (event) {
    this.hideSuccessMessages();
    this.showProgress("Loading...");
    BS.ajaxRequest(this.formElement().action, {
      parameters: "artDepAdd=1",
      onSuccess: function () {
        BS.ArtifactDependencyForm.refreshDialog();
      }
    });
  },

  updateTargetDirectoryWarning: function () {
    setTimeout(() => {
      if ($('cleanDestination') && $('cleanDestinationWarning')) {
        var show = $('cleanDestination').checked && this._hasRootDestination() && !BS.isCompositeBuildType;
        $('cleanDestinationWarning').style.display = show ? 'block' : 'none';
      }
    }, 10);
  },

  _hasRootDestination: function() {
    let rules = document.getElementById('artifactPaths')?.value;
    if (!rules) {
      return false;
    }

    rules = rules.split(/\n+/);
    for (let rule of rules) {
      rule = rule.trim();
      if (!rule.length || rule[0] === '#' || rule[0] === '-') {
        continue;
      }

      if (rule.indexOf("=>") < 0) {
        // No destination separator - destination is checkout directory
        return true;
      }

      const parts = rule.split(/=>\s*/);
      const destination = parts[1].trim();

      // Empty destination or dot destination is the checkout directory
      if (!destination.length || destination === "." || destination === "./") {
        return true;
      }
    }
    return false;
  },

  _counter: 0,

  addArtifactPath: function () {
    var item = document.createElement("li");
    item.innerHTML = $('artifactPathTemplate').innerHTML;
    var input = item.getElementsByTagName("input")[0];
    input.name = 'artifactPath';
    item.style.display = 'block';
    input.className += ' buildTypeParams';
    input.id = 'artifactPath_new_' + (this._counter++);
    $('artifactsPaths').insertBefore(item, $('artifactsPaths_lastItem'));

    BS.VisibilityHandlers.updateVisibility(this.getContainer());
  },

  savingIndicator: function () {
    return $('saveArtifactDependencyProgress');
  },

  switchToUI: function() {
    BS.EditDsl.hideEditDslPanel('#adUiContainer', '.adDslContainer.fragmentEditDsl');
    if (window.ReactUI && ReactUI.closeEditDsl) {
      ReactUI.closeEditDsl(this.controlId);
    }
  },

  prepareRevisionRuleParams: function() {
    this.formElement().revisionRuleName.value = $('revisionRules').options[$('revisionRules').selectedIndex].value;
    this.formElement().revisionRuleValue.value = '';
    if (!$('buildNumberPattern').disabled) {
      this.formElement().revisionRuleValue.value = $('buildNumberPattern').value;
    } else if (!$('buildTag').disabled) {
      this.formElement().revisionRuleValue.value = $('buildTag').value;
    }
  },

  saveDependency: function () {
    this.prepareRevisionRuleParams();

    var that = this;

    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onEmptyBuildNumberPatternError: function (elem) {
        $("errorBuildNumberPattern").innerHTML = elem.firstChild.nodeValue;
        that.highlightErrorField($("buildNumberPattern"));
        that.switchToUI();
      },

      onEmptyBuildTagError: function (elem) {
        $("errorBuildTag").innerHTML = elem.firstChild.nodeValue;
        that.highlightErrorField($("buildTag"));
        that.switchToUI();
      },

      onNoArtifactsPathsError: function (elem) {
        $("errorArtifactsPaths").innerHTML = elem.firstChild.nodeValue;
        that.highlightErrorField($("artifactsPaths").getElementsByTagName("textarea")[0]);
        that.switchToUI();
      },

      onDuplicateArtifactsPathsError: function (elem) {
        $("errorArtifactsPaths").innerHTML = elem.firstChild.nodeValue;
        that.switchToUI();
      },

      onBadDestinationPathError: function (elem) {
        $("errorArtifactsPaths").innerHTML = elem.firstChild.nodeValue;
        that.highlightErrorField($("artifactsPaths").getElementsByTagName("textarea")[0]);
        that.switchToUI();
      },

      onSimilarDependencyExistsError: function (elem) {
        $("errorSimilarDependencyExists").innerHTML = elem.firstChild.nodeValue;
        that.switchToUI();
      },

      onBuildTypeNotExistsError: function (elem) {
        $("errorSourceBuildTypeNotExists").innerHTML = elem.firstChild.nodeValue;
        that.highlightErrorField($("sourceBuildTypeId"));
        that.switchToUI();
      },

      onBuildBranchError: function(elem) {
        $("errorBuildBranch").innerHTML = elem.firstChild.nodeValue;
        that.highlightErrorField($("buildBranch"));
        that.switchToUI();
      },

      onHaveDepParamsError: function(elem) {
        if (confirm("The following parameters will be unavailable after dependency change:"
          + "\n" + elem.firstChild.nodeValue
          + "\n\nDo you want to continue?")) {
          $j("#checkArtifactDepParams").val('false');
          BS.ArtifactDependencyForm.saveDependency('false');
        }
      },

      onCompleteSave: function (form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
        if (!err) {
          BS.ArtifactDependencyForm.close();
          form.enable();
          BS.reload(true);
        }
      }
    }));

    return false;
  },

  showOrHideActionsOnSelect: function() {
    BS.AdminActions.showOrHideActions("#artifactDeps input", "#artifact-actions-docked");
  },

  close: function () {
    $j(this.getContainer()).find('select').ufd('destroy');
    this.doClose();
  }
}));

BS.ArtifactDependencyVerificationForm = OO.extend(BS.BaseEditBuildTypeForm, {
  _password: null,

  formElement: function () {
    return $('enterCredentialsForm');
  },

  verifyDependencies: function(url) {
    var that = this;

    BS.EnterCredentialsDialog.showDialog(function(formElement) {
      var username = formElement.username1.value;
      var encrypted = formElement.password1.getEncryptedPassword();

      BS.EnterCredentialsDialog.disable();
      BS.EnterCredentialsDialog.setSaving(true);
      BS.ajaxRequest(url, {
        parameters: "artDepVerifyDependencies=1&encryptedPassword=" + encrypted + "&username=" + username,
        onSuccess: function (transport) {
          BS.EnterCredentialsDialog.enable();
          BS.EnterCredentialsDialog.setSaving(false);

          var hasError = BS.XMLResponse.processErrors(transport.responseXML, {
            onInvalidCredentialsError: function (elem) {
              $('invalidCredentials').innerHTML = elem.firstChild.nodeValue;
            }
          });

          if (!hasError) {
            BS.EnterCredentialsDialog.close();
            BS.EnterCredentialsDialog.formElement().password1.maskPassword();
            that.setSaving(true);
            $('dependencyResolverMessages').refresh();
          }
        }
      })
    });

    return false;
  },

  verificationFinished: function () {
    this.enable();
    this.setSaving(false);
  }
});

BS.EnterCredentialsDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  formElement: function () {
    return $('enterCredentials');
  },

  getContainer: function () {
    return $('enterCredentialsDialog');
  },

  showDialog: function (onSubmit) {
    this.showCentered();
    this.clearErrors();
    this._onSubmit = onSubmit;

    this.bindCtrlEnterHandler(this.submit.bind(this));
  },

  submit: function () {
    this._onSubmit(this.formElement());
    return false;
  },

  clearErrors: function () {
    $('invalidCredentials').innerHTML = "";
  },

  savingIndicator: function () {
    return $('submitCredentials');
  }
}));

BS.EditDepsUtil = {
  eventTargetIsLink: function (event) {
    var target = Event.element(event || window.event);
    return target.tagName == 'A' && target.innerHTML != 'edit' && target.innerHTML != 'Edit' && target.innerHTML != 'Override';
  },

  itemsSelected: function (container, itemName) {
    if (BS.EditDepsUtil.getSelectedItems(container, itemName).length == 0) {
      alert("Please select at least one dependency.");
      return false;
    }

    return true;
  },

  getSelectedItems: function (container, itemName) {
    var values = [];
    var checkboxes = Form.getInputs(container, "checkbox", itemName);
    for (var i = 0; i < checkboxes.length; i++) {
      if (checkboxes[i].checked) {
        values.push(checkboxes[i].value);
      }
    }

    return values;
  },

  confirmDepsRemove: function (numDeps, action) {
    return confirm("Are you sure you want to " + action + " " + numDeps + " dependenc" + (numDeps == 1 ? 'y' : 'ies') + "?");
  }
};

BS.SourceDependencyForm = OO.extend(BS.DialogWithProgress, OO.extend(BS.BaseEditBuildTypeForm, {
  getContainer: function () {
    return $('sourceDependenciesDialog');
  },

  showSourceDepDSLWithValues: function(version, portable, controlId, id1, id2){
    var oldVal = $j("input[name='saveSourceDependency']").val();
    $j("input[name='saveSourceDependency']").val('');
    $j("#showSourceDSL").val("item");
    $j("#showSourceDSLVersion").val(version);
    $j('#showSourceDSLPortable').val(portable ? 'true' : 'false');
    this._showItemDsl(true, controlId, id1, id2);
    $j("input[name='saveSourceDependency']").val(oldVal);
  },

  showDialog: function () {
    this.showCentered();
    this.bindCtrlEnterHandler(this.saveDependency.bind(this));
  },

  formElement: function () {
    return $('sourceDependencies');
  },

  savingIndicator: function () {
    return $('addSourceDependencyProgress');
  },

  dependenciesSelected: function () {
    return BS.EditDepsUtil.itemsSelected($('snapshotDeps'), "snDepChkbox");
  },

  getSelectedDeps: function () {
    return BS.EditDepsUtil.getSelectedItems($('snapshotDeps'), "snDepChkbox");
  },

  removeDependencies: function (buildTypeIds, action) {
    if (!BS.EditDepsUtil.confirmDepsRemove(buildTypeIds.length, action)) return;

    this.hideSuccessMessages();
    this.setSaving(true);
    var removeUrl = this.formElement().action;
    BS.ajaxRequest(removeUrl, {
      parameters: "srcDepDelete=" + buildTypeIds.join("&srcDepDelete=") + "&checkDepParams=true",
      onSuccess: function (transport) {
        BS.XMLResponse.processErrors(transport.responseXML, {
          onHaveDepParamsError: function (elem) {
            if (confirm("The following parameters will be unavailable after dependenc" + (buildTypeIds.length == 1 ? 'y' : 'ies') + " remove:"
              + "\n" + elem.firstChild.nodeValue
              + "\n\nDo you want to continue?")) {
              BS.ajaxRequest(
                removeUrl, {
                  parameters: "srcDepDelete=" + buildTypeIds.join("&srcDepDelete="),
                  onSuccess: function () {
                    BS.reload(true);
                  }
                });
            }
          }
        });
        BS.reload(true);
      }
    });
  },

  editDependency: function (event, buildTypeId) {
    if (BS.EditDepsUtil.eventTargetIsLink(event)) return true;

    this.hideSuccessMessages();
    this.showProgress("Loading...");
    BS.ajaxRequest(this.formElement().action, {
      parameters: "srcDepEdit=" + buildTypeId,
      onSuccess: function () {
        BS.SourceDependencyForm.refreshDialog();
      }
    });
  },

  addDependency: function (event, selectedBuildTypes) {
    this.hideSuccessMessages();
    this.showProgress("Loading...");
    BS.ajaxRequest(this.formElement().action, {
      parameters: "srcDepAdd=1" + (selectedBuildTypes ? "&selectedBuildTypes=" + selectedBuildTypes.join("&selectedBuildTypes=") : ""),
      onSuccess: function () {
        BS.SourceDependencyForm.refreshDialog();
      }
    });
  },

  refreshDialog: function () {
    $('sourceEditingDependencyDialog').refresh(null, "noCacheRnd=" + Math.random(), function () {
      BS.SourceDependencyForm.showCentered();
    });
  },

  configurationIsChosen: function() {
    var selected = document.querySelectorAll("#buildTypeSelectorResult input[type='checkbox']");
    var edited = $j("#srcDependOn");
    var selectedForOptionChange = $j('input[name="srcDependOn"]');

    if (selected.length == 0 && edited.val() == undefined && selectedForOptionChange.length == 0) {
      alert("Please choose at least one build configuration.");
      return false;
    }
    return true;
  },

  saveDependency: function () {
    if (!this.configurationIsChosen()) {
      return false;
    }
    var that = this;
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.SaveConfigurationListener, {
      onNoBuildTypesFoundError: function (elem) {
        alert(elem.firstChild.nodeValue);
      },
      onCyclicDependencyFoundError: function (elem) {
        alert(elem.firstChild.nodeValue);
      },
      onHaveDepParamsError: function(elem) {
        if (confirm("The following parameters will be unavailable after dependency change:"
          + "\n" + elem.firstChild.nodeValue
          + "\n\nDo you want to continue?")) {
          $j("#checkSnapshotDepParams").val('false');
          BS.SourceDependencyForm.saveDependency('false');
        }
      },
      onCompleteSave: function (form, responseXML, err) {
        BS.SaveGeneralBuildTypeInfoListener.onCompleteSave(form, responseXML, err);

        if (!err) {
          that.close();
          BS.reload(true);
        }
      }
    }));

    return false;
  },

  showOrHideActionsOnSelect: function() {
    BS.AdminActions.showOrHideActions("#snapshotDeps input", "#snapshot-actions-docked");
  }
}));

BS.AttachDetachTemplateAction = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  getContainer: function () {
    return $('useTemplateFormDialog');
  },

  formElement: function () {
    return $('useTemplateForm');
  },

  showDialog: function (buildTypeId) {
    this.clearErrors();
    $('useTemplateForm').buildTypeId.value = buildTypeId;
    $('templateId').selectedIndex = 0;
    this.templateChanged(null, null, null);
    this.showCentered();
    this.bindCtrlEnterHandler(this.submit.bind(this));

    return false;
  },

  savingIndicator: function () {
    return $('associateWithTemplateProgress');
  },

  submit: function () {
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      attachFailed: function (elem) {
        $('error_attachFailed').innerHTML = elem.firstChild.nodeValue;
      },

      onCompleteSave: function (form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);

        if (!err) {
          BS.reload(true);
        }
      }
    }));
    return false;
  },

  cancelDialog: function () {
    this.close();
  },

  markTemplateAsDetached: function (templateId) {
    $('tpl_' + templateId).hide();
    $('detach_tpl_' + templateId).value = templateId;
    return false;
  },

  detachFromTemplate: function (buildTypeId) {
    if (!confirm("Are you sure you want to detach this build configuration from the template?\n" +
                 "Upon detach template settings will be copied to the build configuration.")) {
      return false;
    }

    BS.ajaxRequest(this.formElement().action, {
      parameters: "buildTypeId=" + buildTypeId + "&detachFromTemplate=1",
      onSuccess: function (transport) {
        var hasError = BS.XMLResponse.processErrors(transport.responseXML, {
          detachFailed: function (elem) {
            alert(elem.firstChild.nodeValue);
          }
        });

        if (!hasError) {
          BS.reload(true);
        }
      }
    });

    return false;
  },

  templateChanged: function (buildTypeId, templateId) {
    $('templateParameters').innerHTML = '';
    this.submitEnabled(false);

    if (templateId) {
      this.loadTemplateData(buildTypeId, templateId);
    } else {
      BS.jQueryDropdown('#templateId').ufd("changeOptions");
    }
  },

  loadTemplateData: function (buildTypeId, templateId) {
    BS.TemplateParametersLoader.loadParameters(
        "templateId=" + templateId + "&buildTypeId=" + buildTypeId,
        'templateParameters',
        'templateParamsUpdateProgress', function () {
          BS.AttachDetachTemplateAction.submitEnabled(true);
          BS.AttachDetachTemplateAction.recenterDialog();
          BS.VisibilityHandlers.updateVisibility($j('.templateParametersTable')[0]);
        });
  },

  submitEnabled: function (enabled) {
    if (enabled) {
      Form.Element.enable(this.formElement().associateWithTemplate);
    } else {
      Form.Element.disable(this.formElement().associateWithTemplate);
    }
  }
}));

BS.ExtractTemplateAction = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  getContainer: function () {
    return $('extractTemplateFormDialog');
  },

  formElement: function () {
    return $('extractTemplateForm');
  },

  showDialog: function (buildTypeId) {
    this.clearErrors();
    this.formElement().buildTypeId.value = buildTypeId;
    this.showCentered();
    $('templateName').focus();

    this.bindCtrlEnterHandler(this.submit.bind(this));

    return false;
  },

  savingIndicator: function () {
    return $('extractTemplateProgress');
  },

  submit: function () {
    var that = this;
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      extractFailed: function (elem) {
        $('error_extractFailed').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
      },

      invalidName: function (elem) {
        $('error_templateName').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField($('templateName'));
      },

      onEmptyIdError: function (elem) {
        $('error_templateExternalId').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField($('templateExternalId'));
      },

      onInvalidIdError: function (elem) {
        $('error_templateExternalId').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField($('templateExternalId'));
      },

      onDuplicateIdError: function (elem) {
        $('error_templateExternalId').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField($('templateExternalId'));
      },

      onCompleteSave: function (form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);

        if (!err) {
          BS.reload(true);
        }
      }
    }));
    return false;
  },

  cancelDialog: function () {
    this.close();
  }
}));

BS.TemplateParametersLoader = {
  loadParameters: function (reqParams, containerId, progressId, afterLoadFunc) {
    progressId = $(progressId);
    progressId.show();
    BS.ajaxUpdater($(containerId), window['base_uri'] + '/admin/showTemplateParams.html', {
      parameters: reqParams,
      evalScripts: true,
      onComplete: function () {
        progressId.hide();
        if (afterLoadFunc) {
          afterLoadFunc();
        }
      }
    });
  }
};

BS.EditArtifactDependencies = {
  currentTextField: null,
  expandNestedArchives: false,

  attachPopups: function (className, idPrefix, scopeName, addParams) {
    var scope = $(scopeName);
    var elems = scope.select('.' + className);
    var elemsToUpdate = {};

    for (var j = 0; j < elems.length; j++) {
      var elem = elems[j];
      if (elem.className.indexOf('disableBuildTypeParams') != -1) continue;
      if (!elem.id.startsWith(idPrefix)) continue;
      var imgId = elem.id + "_insertArtifact";
      if (scope.select('#' + imgId).length > 0) continue;

      elemsToUpdate[elem.id] = elem;
      this.attachPopup(elem, addParams);
    }

    for (var id in elemsToUpdate) {
      BS.VisibilityHandlers.updateVisibility(elemsToUpdate[id]);
    }
  },

  attachPopup: function (elem, addParams) {
    var popupControlId = elem.id + "_insertArtifact";
    var popupControl = document.createElement('button');
    popupControl.type = 'button';
    popupControl.innerHTML = ReactUI.createAndRenderStatic(ReactUI.FileTreeIcon, {
      icon: 'folder',
      className: 'actionIcon'
    });
    popupControl.id = popupControlId;
    popupControl.className = 'actionIconWrapper insert-artifacts';
    popupControl.style.display = 'none';
    popupControl.title = "Choose artifact";

    var that = this;
    popupControl.onclick = function () {
      that.currentTextField = elem;
      that.showArtifactsTree(popupControl, that.expandNestedArchives, addParams);
    };

    var parentClass = elem.parentNode.className;

    if (parentClass.indexOf('completionIconWrapper') == -1 && parentClass.indexOf('posRel') == -1) {
      var inputField = $j(elem);
      var wrapper = BS.Util.wrapRelative(inputField);

      if (inputField.prop('style').width == '100%') {
        wrapper.css('display', 'block');
      }
    }

    elem.parentNode.appendChild(popupControl);

    var handler = {
      updateVisibility: function () {
        var handle = $(popupControlId);
        var control = $(elem.id);
        if (control.disabled || control.readOnly) {
          BS.Util.hide(handle);
        } else {
          if (handle != null) {
            BS.Util.show(handle);
          }
        }
      }
    };
    BS.VisibilityHandlers.attachTo(elem.id, handler);
  },

  showArtifactsTree: function (elem, expandNestedArch, addParams) {
    var buildTypeId = this.findOutBuildTypeId();
    var buildTypeExternalId = this.findOutBuildTypeExternalId();
    var buildRevision = this.findOutBuildRevision();
    var buildNumber = this.findOutBuildNumber();
    var buildTag = this.findOutBuildTag();
    var buildBranch = this.findOutBuildBranch();

    var url = window['base_uri'] + "/editArtifactDepsHelper.html?";

    if (buildTypeId) {
      url += "&internalBuildTypeId=" + buildTypeId;
    }
    if (buildTypeExternalId) {
      url += "&buildTypeId=" + buildTypeExternalId;
    }
    if (buildRevision) {
      url += "&buildRevision=" + encodeURIComponent(buildRevision);
    }
    if (buildNumber) {
      url += "&buildNumber=" + encodeURIComponent(buildNumber);
    }
    if (buildTag) {
      url += "&buildTag=" + encodeURIComponent(buildTag);
    }
    if (buildBranch) {
      url += "&buildBranch=" + encodeURIComponent(buildBranch);
    }
    if (expandNestedArch != undefined) {
      url += "&expandNestedArch=" + expandNestedArch;
    }
    if (addParams) {
      url += "&" + addParams;
    }

    BS.LazyTree.treeUrl = url;
    BS.LazyTree.ignoreHashes = true;
    var popup = new BS.Popup("artifactsTreePopup", {
      hideOnMouseOut: false,
      hideOnMouseClickOutside: true,
      shift: {x: 20, y: 0},
      url: url
    });
    popup.showPopupNearElement(elem);
  },

  findOutBuildTypeId: function () {
    // NOTE: there are two elements with id='sourceBuildTypeId'!
    return $j('#sourceBuildTypeId').val();
  },

  findOutBuildTypeExternalId: function () {
    return null;
  },

  findOutBuildRevision: function () {
    var select = $('revisionRules');
    return select.selectedIndex > 3 ? null : select.options[select.selectedIndex].value;
  },

  findOutBuildNumber: function () {
    var textField = $('buildNumberPattern');
    return textField.disabled ? null : textField.value;
  },

  findOutBuildTag: function () {
    var textField = $('buildTag');
    return textField == null || textField.disabled ? null : textField.value;
  },

  findOutBuildBranch: function () {
    var textField = $('buildBranch');
    return textField == null || textField.disabled ? null : textField.value;
  },

  appendPath: function (path) {
    if (this.currentTextField) {
      var value = $(this.currentTextField).value;
      if (value.length > 0) {
        var lines = value.split("\n");
        lines.push(path);
        $(this.currentTextField).value = lines.join("\n");
      } else {
        $(this.currentTextField).value = path;
      }
    }
  },

  setPath: function (path) {
    if (this.currentTextField) {
      $(this.currentTextField).value = path;
    }
  },

  showHideValueFields: function (alwaysShowBranches) {
    var form = $('artifactDependencyForm');
    var buildNumberSelected = form.revisionRules.selectedIndex == 4;
    var buildTagSelected = form.revisionRules.selectedIndex == 5;

    if (buildNumberSelected) {
      $('buildNumberPattern').disabled = false;
      BS.Util.show('buildNumberField');
      $('buildTag').disabled = true;
      BS.Util.hide('buildTagField');
    } else if (buildTagSelected) {
      $('buildNumberPattern').disabled = true;
      BS.Util.hide('buildNumberField');
      $('buildTag').disabled = false;
      BS.Util.show('buildTagField');
    } else {
      $('buildNumberPattern').disabled = true;
      BS.Util.hide('buildNumberField');
      $('buildTag').disabled = true;
      BS.Util.hide('buildTagField');
    }
    this.updateBranchField(alwaysShowBranches);
    BS.VisibilityHandlers.updateVisibility('buildNumberField');
    BS.VisibilityHandlers.updateVisibility('buildTagField');
  },

  selectedRuleSupportsBranch: function(form) {
    var idx = form.revisionRules.selectedIndex;
    return idx == 0 || idx == 1 || idx == 2 || idx == 5;
  },

  checkRelatedSnapshotDependency: function (enforceRevisionRule, presetBuildType) {
    var form = $('artifactDependencyForm');

    var selectedBuildTypeId = this.getSelectedBuildTypeId(form);

    var isBtIdUpdated = false;

    if ('' != selectedBuildTypeId && snapshotDepsMap[selectedBuildTypeId] && form.revisionRules.selectedIndex != 3) {
      if (enforceRevisionRule) {
        form.revisionRules.setSelected(3, true);
        if (isBtIdUpdated) {
          $j(form.sourceBuildTypeId).ufd('setInputFromMaster')
        }
        BS.EditArtifactDependencies.showHideValueFields();
      } else {
        BS.Util.show('lastFinishedNote');
      }
    } else {
      BS.Util.hide('lastFinishedNote');
    }

    BS.VisibilityHandlers.updateVisibility('artifactDependencyForm');
  },

  getSelectedBuildTypeId: function(form){
    return $j('#sourceBuildTypeId').val();
  },


  getSelectedBuildTypeExternalId: function(form){
    return $j('#sourceBuildTypeId').attr('data-filter-data');
  },

  getBuildTypesLength: function(form){
    return 1;
  },

  updateBuildTypeTagsList: function () {
    var tagListHtml = "";
    var form = $('artifactDependencyForm');

    var selectedBuildTypeId = this.getSelectedBuildTypeId(form);

    if (!selectedBuildTypeId || 0 === selectedBuildTypeId.length) {
      BS.Util.hide('buildTagList');
      return;
    }
    var url = window['base_uri'] + "/editArtifactDepsHelper.html";

    BS.ajaxRequest(url, {
      parameters: {
        listTags: '',
        internalBuildTypeId: selectedBuildTypeId
      },
      onComplete: function (transport) {
        var responseXML = transport.responseXML;
        var tagData = responseXML.firstChild.firstChild;

        function renderTagLink(label, escapedLabel) {
          return "<a href=\"#\" onclick=\"BS.EditArtifactDependencies.setBuildTagValue('" +
            escapedLabel + "'); return false\">" + label.escapeHTML() + "</a> ";
        }

        if (tagData) {
          while (tagData) {
            tagListHtml = tagListHtml + renderTagLink(tagData.attributes.original.value,
                                                      tagData.attributes.escaped.value);
            tagData = tagData.nextSibling;
          }
          $('buildTagListSpan').innerHTML = tagListHtml;
          BS.Util.show('buildTagList')
        } else {
          BS.Util.hide('buildTagList');
        }
      }
    });
  },

  clearBranchField: function(){
      $j('#buildBranch').val('');
  },

  updateBranchField: function(alwaysShowBranchBuildTypeId, defExcl) {
    var form = $('artifactDependencyForm');
    if (!this.selectedRuleSupportsBranch(form)) {
      $('buildBranch').disabled = true;
      BS.Util.hide('buildBranchField');
      BS.EditArtifactDependencies.clearBranchField();
      BS.VisibilityHandlers.updateVisibility('buildBranchField');
      return;
    }

    var externalId = this.getSelectedBuildTypeExternalId(form);

    if (!externalId) {
      return;
    }

    var internalId = this.getSelectedBuildTypeId(form);

    var defaultExcluded = defExcl;

    if ($j('defaultBranchExcluded').val() == 'true'){
      defaultExcluded = true;
    }

    this.toggleDefaultBranch(defaultExcluded);

    var alwaysShowBranch = alwaysShowBranchBuildTypeId != undefined && alwaysShowBranchBuildTypeId == internalId;

    if (alwaysShowBranch) {
      //revision rule has a configured branch, show a branch field
      //even if the build type we depend on doesn't have branches (TW-29277)
      $('buildBranch').disabled = false;
      BS.Util.show('buildBranchField');
      BS.BranchesPopup.attachBuildTypeHandler(externalId, 'buildBranch', 'branchFilter', 'ALL_BRANCHES');
      BS.VisibilityHandlers.updateVisibility('buildBranchField');
      return;
    }

    BS.AdminActions.listBranches(externalId, function(branches) {
      var hasNonDefaultBranch = branches.length > 1;
      if (!hasNonDefaultBranch) {
        for (var i=0; i<branches.length; i++) {
          if (!branches[i].is_default) {
            hasNonDefaultBranch = true;
            break;
          }
        }
      }

      if (hasNonDefaultBranch) {
        $('buildBranch').disabled = '';
        BS.Util.show('buildBranchField');
        BS.BranchesPopup.attachBuildTypeHandler(externalId, 'buildBranch', 'branchFilter', 'ALL_BRANCHES');
      } else {
        $('buildBranch').disabled = true;
        BS.EditArtifactDependencies.clearBranchField();
        BS.Util.hide('buildBranchField');
      }

      BS.VisibilityHandlers.updateVisibility('buildBranchField');
    });
  },

  toggleDefaultBranch: function(param) {
    if (param) {
      if ($j('#buildBranch').val() == '+:<default>') {//'<default>' branch is selected for buildType with excluded default
        //make it empty to ask for a valid non-default branch
        $j('#buildBranch').val('');
      }
    } else {
      if ($j('#buildBranch').val() == '') {
        //buildType doesn't exclude the default branch, we can use default
        $j('#buildBranch').val('+:<default>');
      }
    }
  },

  setBuildTagValue: function (tagValue) {
    var textField = $('buildTag');
    if (!textField.disabled) {
      textField.value = tagValue;
    }
  }
};

BS.MultipleRunnersForm = {

  resetRunner: function(settingsId, runnerId) {
    this.deleteRunnerEx("Are you sure you want to reset this build step to its template definition?", settingsId, runnerId);
  },

  deleteRunner: function(settingsId, runnerId) {
    this.deleteRunnerEx("Are you sure you want to delete this build step?", settingsId, runnerId);
  },

  deleteRunnerEx: function (msg, settingsId, runnerId) {
    if (!confirm(msg)) return;

    BS.ajaxRequest('editBuildRunners.html', {
      parameters: "id=" + settingsId + "&deleteRunner=" + runnerId,
      onSuccess: function () {
        if ($('buildTypeSettingsContainer')) {
          BS.reload(true);
        } else {
          document.location.href = 'editBuildRunners.html?init=1&id=' + settingsId;
        }
      }
    });
  },

  setEnabled: function (settingsId, runnerId, enabled) {
    BS.ajaxRequest('editBuildRunners.html', {
      parameters: "id=" + settingsId + "&setEnabled=" + runnerId + "&enabled=" + enabled,
      onSuccess: function () {
        BS.reload(true);
      }
    });
  }
};

BS.CopyBuildStepForm = OO.extend(BS.AbstractCopyMoveDialog, {
  __baseId: 'copyBuildStep',

  _prepareRequestParameters: function (settingsId, runnerId) {
    return {
      id: settingsId,
      runnerId: runnerId
    };
  },

  _onFetchDialogComplete: function (response) {
    $j('body').append(response.responseText);
    this.showCentered();
    this.bindCtrlEnterHandler(this.submitCopy.bind(this));
  },

  submitCopy: function () {
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      copyStepFailed: function (elem) {
        $("error_copyStepFailed").innerHTML = elem.firstChild.nodeValue;
      },

      onCompleteSave: function (form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);

        if (!err) {
          BS.CopyBuildStepForm.close();
          BS.XMLResponse.processRedirect(responseXML);
        }
      }
    }));

    return false;
  }
});

BS.BuildFeatureDialog = OO.extend(BS.BaseEditBuildTypeForm, OO.extend(BS.AbstractModalDialog, OO.extend(BS.PluginPropertiesForm, {
  formElement: function () {
    return $('buildFeatures');
  },

  getContainer: function () {
    return $('buildFeaturesDialog');
  },

  savingIndicator: function () {
    return $('saveFeatureProgress');
  },

  getSaveButton: function () {
    return $('submitBuildFeatureId')
  },

  setSaveButtonDisabled: function (state) {
    this.getSaveButton().disabled = state
  },

  showAddDialog: function (featurePlace, title, type) {
    this.formElement().featurePlace.value = featurePlace;

    $('featureParams').innerHTML = '';
    $('featureSaveButtonsBlock').show();
    $j('#editBuildFeatureAdditionalButtons').empty();
    BS.EditDsl.hideEditDslButtons();

    this._updateOptionsListAccordingToFeaturePlace();

    if ($('featureTypeSelector').childNodes.length == 2) {
      this._initializeDialogWithSingleOption();
    }
    else {
      this._initializeDialogWithMultipleOptions(title);
    }

    if (type != null) {
      var opts = $('featureTypeSelector').options;
      for (var i=0; i<opts.length; i++) {
        var opt = opts[i];
        if (opt.value == type) {
          $('featureTypeSelector').selectedIndex = i;
          BS.jQueryDropdown($('featureTypeSelector')).ufd("changeOptions");
          break;
        }
      }

      this.onTypeChange($('featureTypeSelector'));
    }

    this.formElement().featureId.value = '';
    this.showCentered();
    this.bindCtrlEnterHandler(this.save.bind(this));
  },

  _updateOptionsListAccordingToFeaturePlace: function () {
    var featurePlace = this.formElement().featurePlace.value;

    var options = $('featureTypeOptionsData').select("option");
    $('featureTypeSelector').innerHTML = '';
    for (var i = 0; i < options.length; i++) {
      var option = options[i];
      var fp = option.getAttribute('data-feature-place');
      if (!fp || featurePlace == fp) {
        $('featureTypeSelector').appendChild(option.cloneNode(true));
      }
    }
  },

  _initializeDialogWithSingleOption: function () {
    $('buildFeaturesTitle').innerHTML = $('featureTypeSelector').childNodes[1].innerHTML;
    $('featureTypeSelector').selectedIndex = 1;
    BS.BuildFeatureDialog.onTypeChange($('featureTypeSelector'));
    $('featureTypeSelector').up("table").hide();
    $('submitBuildFeatureId').enable();
  },

  _initializeDialogWithMultipleOptions: function (title) {
    $('buildFeaturesTitle').innerText = BS.Util.capitalize(title);
    $('featureTypeSelector').selectedIndex = 0;
    $('featureTypeSelector').options[0].innerHTML = "-- Choose " + title.substr(4) + " --";
    BS.jQueryDropdown($('featureTypeSelector'));
    $('featureTypeSelector').up("table").show();
    $('submitBuildFeatureId').disable();
  },

  showEditDialog: function (featurePlace, id, type, name, forceOwn, inherited, canNotEdit, overriden) {
    this.formElement().featurePlace.value = featurePlace;

    $('buildFeaturesTitle').innerText = name;
    $('featureParams').innerHTML = '';
    $('featureSaveButtonsBlock').hide();
    $('submitBuildFeatureId').enable();
    $j('#editBuildFeatureAdditionalButtons').empty();

    $('featureTypeSelector').up("table").hide();

    this.formElement().featureId.value = id;
    this.loadParams('featureId=' + id + (forceOwn ? '&forceOwn=true' : ''), overriden, inherited, canNotEdit);
    this.showCentered();
    this.bindCtrlEnterHandler(this.save.bind(this));
  },

  onTypeChange: function (selector) {
    $j('#editBuildFeatureAdditionalButtons').empty();
    if (selector.selectedIndex <= 0) {
      $('featureParams').innerHTML = '';
      $('submitBuildFeatureId').disable();
      BS.EditDsl.hideEditDslButtons();
      return;
    }
    $j('#showDSLButton').show();
    $('submitBuildFeatureId').enable();
    var type = selector.options[selector.selectedIndex].value;
    this.formElement().featureType.value = type;
    this.loadParams('featureId=&featureType=' + type);
    BS.EditDsl.showEditDslButtons();
  },

  loadParams: function (param, overriden, inherited, canNotEdit) {
    var buildTypeId = window.location.search.substring(1).split('&').grep(/id=(.*)/).join('').split('=')[1];
    $('loadParamsProgress').show();

    BS.ajaxUpdater($('featureParams'), window['base_uri'] + '/admin/showFeatureParams.html', {
      parameters: document.location.search.substring(1) + "&" + param,
      evalScripts: true,
      onComplete: function () {
        BS.BuildFeatureDialog.recenterDialog();
        BS.AvailableParams.attachPopups('settingsId=' + buildTypeId, 'textProperty', 'multilineProperty');
        $('loadParamsProgress').hide();
        BS.VisibilityHandlers.updateVisibility('buildFeaturesDialog');
        if (canNotEdit) {
          $j("#submitBuildFeatureId").attr("disabled", "disabled");
          Form.disable("featureParams");
        }
      }
    });
  },

  resetFeature: function  (featurePlace, id, messagePrefix, enforced, location) {
    if (enforced) {
      this.deleteFeatureEx(featurePlace, id, messagePrefix, "This build feature is defined in " + location + " but is overriden by enforced settings and will not be applied in the build. Do you want to reset this build feature and use enforced one?");
    } else {
      this.deleteFeatureEx(featurePlace, id, messagePrefix, "Are you sure you want to reset the build feature to its template definition?");
    }
  },

  deleteFeature: function  (featurePlace, id, messagePrefix, settingName) {
    this.deleteFeatureEx(featurePlace, id, messagePrefix, "Are you sure you want to delete this " + settingName + "?");
  },

  deleteFeatureEx: function (featurePlace, id, messagePrefix, confirmationMessage) {
    if (!messagePrefix) {
      messagePrefix = "The build feature";
    }
    if (!confirm(confirmationMessage)) return;

    BS.BuildFeatureDialog.doDeleteFeature(featurePlace, id, messagePrefix);
  },

  doDeleteFeature: function (featurePlace, id, messagePrefix) {
    var url = this.formElement().getAttribute('action');
    var buildTypeId = window.location.search.substring(1).split('&').grep(/id=(.*)/).join('').split('=')[1];

    BS.ajaxRequest(url, {
      parameters: "featurePlace=" + featurePlace + "&id=" + buildTypeId + "&removeFeature=true&featureId=" + id + "&messagePrefix=" + encodeURIComponent(messagePrefix),
      onComplete: function () {
        BS.reload(true);
      }
    });
  },

  save: function () {
    var that = this;
    var url = this.formElement().getAttribute('action');

    BS.PasswordFormSaver.save(that, url, OO.extend(BS.ErrorsAwareListener, {
      onBuildFeatureExistsError: function (elem) {
        $("errorBuildFeatureExists").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
      },
      onCompleteSave: function (form, responseXML, err) {
        var wereErrors = BS.XMLResponse.processErrors(responseXML, {}, that.propertiesErrorsHandler) || err;
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, wereErrors);

        if (wereErrors) {
          return;
        }

        var featurePlace = that.formElement().featurePlace.value;
        that.enable();
        that.close();
        BS.reload(true);
      }
    }));
    return false;
  }
})));

BS.BuildStepsOrderDialog = OO.extend(BS.AbstractModalDialog, OO.extend(BS.AbstractWebForm, {
  getContainer: function () {
    return $('buildStepsOrderDialog');
  },

  formElement: function () {
    return $('buildStepsOrder');
  },

  savingIndicator: function () {
    return $('saveOrderProgress');
  },

  fixPageScroll: function () {
    window.scrollTo(0, 0);
  },

  submitForm: function (buildTypeId, resetRunners) {
    this.disable();
    if (resetRunners && !confirm('You are about to reset the order of build configuration steps in relation to the inherited build steps to default.')) {
      this.enable();
      return false;
    }

    this.setSaving(true);

    var order;
    if (resetRunners) {
      order = 'runnersOrder.reset=true';
    } else {
      var runners = OO.extend(BS.QueueLikeSorter, {
        containerId: 'buildRunners'
      });
      order = 'runnersOrder=' + runners.computeOrder($('buildRunners'), 'r_');
    }

    BS.ajaxRequest(this.formElement().action, {
      parameters: 'id=' + buildTypeId + '&' + order,
      onComplete: function (transport) {
        BS.BuildStepsOrderDialog.enable();
        BS.BuildStepsOrderDialog.setSaving(false);
        BS.BuildStepsOrderDialog.close();
        BS.reload(true);
      }
    });

    return false;
  }
}));

BS.TemplatesOrderDialog = OO.extend(BS.AbstractModalDialog, OO.extend(BS.AbstractWebForm, {
  getContainer: function () {
    return $('templatesOrderDialog');
  },

  formElement: function () {
    return $('templatesOrder');
  },

  savingIndicator: function () {
    return $('templateSaveOrderProgress');
  },

  fixPageScroll: function () {
    window.scrollTo(0, 0);
  },

  submitForm: function (buildTypeId) {
    this.disable();
    this.setSaving(true);

    var templates = OO.extend(BS.QueueLikeSorter, {
      containerId: 'buildTemplates'
    });

    var order = templates.computeOrder($('buildTemplates'), 'tpl_');
    var detachTpl = "";
    $('buildTemplates').select('input').each(function(el) {
      if (el.value) {
        if (detachTpl != "") detachTpl += ";";
        detachTpl += el.value;
      }
    });

    if (detachTpl) {
      if(!confirm("Are you sure you want to detach the build configuration from the selected template(s)?")) {
        this.enable();
        return false;
      }
      detachTpl = "&detach=" + detachTpl;
    }

    BS.ajaxRequest(this.formElement().action, {
      parameters: 'id=' + buildTypeId + '&templatesOrder=' + order + detachTpl,
      onComplete: function (transport) {
        BS.TemplatesOrderDialog.enable();
        BS.TemplatesOrderDialog.setSaving(false);
        BS.TemplatesOrderDialog.close();
        BS.reload(true);
      }
    });

    return false;
  }
}));


BS.EditTriggersDialog = OO.extend(BS.BaseEditBuildTypeForm, OO.extend(BS.AbstractModalDialog, OO.extend(BS.PluginPropertiesForm, {

  CustomControls: {},
  customControls: {},
  customBuildParametersIds: [],
  newParameterCounter: 0,

  getContainer: function () {
    return $('editTriggerDialog');
  },

  formElement: function () {
    return $('editTrigger');
  },

  showAddDialog: function(preselected) {
    this.formElement().editMode.value = "addTrigger";
    this.formElement().triggerId.value = '';
    $('editTriggerTitle').innerHTML = 'Add New Trigger';

    var selector = $j("#triggerNameSelector");
    selector.parents("table").show();
    $j("#triggerNameSelector").val(preselected || "");
    BS.jQueryDropdown(selector).ufd("changeOptions");
    this.triggerChanged(preselected || '');

    this.showDialog();
    return false;
  },

  showDialog: function () {
    this.showAtFixed($(this.getContainer()));
  },

  showEditDialog: function (triggerId) {
    this.formElement().editMode.value = "editTrigger";
    this.formElement().triggerId.value = triggerId;

    $('triggerNameSelector').up("table").hide();
    $j('.edit-trigger-progress-wrapper').removeClass('hidden');

    this.triggerChanged(this.allTriggersNames[triggerId]);

    this.showDialog();
  },

  getBuildTypeId: function () {
    return window.location.search.substring(1).split('&').grep(/id=(.*)/).join('').split('=')[1];
  },

  triggerChanged: function (triggerName) {
    $('editTriggerAdditionalButtons').hide();

    if (this.allTriggerServicesDisplayNames[triggerName]) {
      $('editTriggerTitle').innerHTML = this.allTriggerServicesDisplayNames[triggerName];
    }

    var buildTypeId = this.getBuildTypeId();

    this.formElement().triggerName.value = triggerName;
    $('triggerParams').innerHTML = '';

    if (triggerName == '') {
      BS.EditDsl.hideEditDslButtons();
      $('editTriggerSubmit').disable();
      return;
    }

    $('editTriggerSubmit').enable();

    $('loadParamsProgress').show();
    var that = this;
    BS.ajaxUpdater('triggerParams', window['base_uri'] + '/admin/showTriggerParams.html', {
      parameters: 'triggerName=' + encodeURIComponent(triggerName) + "&triggerId=" + this.formElement().triggerId.value + "&id=" + buildTypeId,
      evalScripts: true,
      onSuccess: function () {
        $('loadParamsProgress').hide();
        $j('.edit-trigger-progress-wrapper').addClass('hidden');

        window.setTimeout(function () {
          BS.AvailableParams.attachPopups('settingsId=' + buildTypeId, 'textProperty', 'multilineProperty');
          that.recenterDialog();
        }, 100);
      }
    });

    BS.EditDsl.showEditDslButtons();
  },

  serializeParameters: function() {
    var params = BS.PluginPropertiesForm.serializeParameters.bind(this)();

    for(var id in this.customControls) {
      if (this.customControls.hasOwnProperty(id) && this.customBuildParametersIds.includes(id)) {
        var control = this.customControls[id];
        var objName = control.getFormSerializeName();
        try {
          var val = control.getControlValue();
          if (val) {
            params += "&" + encodeURIComponent(objName) + "=" + encodeURIComponent(val);
          } else {
            params += "&" + encodeURIComponent(objName) + "=";
          }
        } catch(e) {
          BS.Log.error('Failed to get value of control: ' + objName + ". " + e);
        }
      }
    }

    $j("#customParametersTable tr.customParam_new").each(function() {
        params += "&new_parameter_" + encodeURIComponent($j(this).find("input[name='new-parameter-name']").val()) + "=" +
          encodeURIComponent($j(this).find("textarea[name='new-parameter-value']").val())
      }
    );

    return params;
  },

  submitForm: function () {
    var that = this;
    var url = this.formElement().getAttribute('action');
    BS.PasswordFormSaver.save(that, url, OO.extend(BS.ErrorsAwareListener, {
      onBuildTriggerExistsError: function(elem) {
        $("errorBuildTriggerExists").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
      },
      onCompleteSave: function (form, responseXML, err) {
        var wereErrors = BS.XMLResponse.processErrors(responseXML, {}, that.propertiesErrorsHandler) || err;

        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, wereErrors);

        if (wereErrors) {
          return;
        }

        that.enable();
        that.close();

        BS.reload(true);
      }
    }));
    return false;
  },

  removeTrigger: function (id) {
    let url = this.formElement().getAttribute('action');
    let requestFunc = function (removeQueuedBuilds) {
      BS.ajaxRequest(url, {
        parameters: 'removeTrigger=' + id + "&removeQueued=" + removeQueuedBuilds,
        onComplete: function () {
          BS.reload(true);
        }
      })
    };
    BS.DisablingTriggerDialog.show({
      requestFunc: requestFunc,
      title: 'Delete Trigger',
      text: 'Are you sure you want to delete this trigger?',
      buttonCaption: 'Delete'
    });
  },

  resetTrigger: function (id) {
    if (!confirm("Are you sure you want to reset the trigger to its template definition?")) return;

    BS.ajaxRequest(this.formElement().getAttribute('action'), {
      parameters: 'removeTrigger=' + id,
      onComplete: function () {
        BS.reload(true);
      }
    })
  },

  allTriggerServicesDisplayNames: {},

  allTriggersNames: {},

  getAddControlFunction: function(containerId, controlId) {
    var o = {
      id : controlId,
      containerId : containerId,
      getFormSerializeName: function() { return controlId; },
      errorsProcessor : {}
    };

    o.getControlValue = function() {
      var el = $(o.id);
      if (el == null) return null;
      return el.getValue();
    };

    BS.EditTriggersDialog.customControls[controlId] = o;

    return function(x) {
      if (x.getControlValue) {
        o.getControlValue = x.getControlValue.bind(x);
      }

      if (x.errorsProcessor) {
        for(var k in x.errorsProcessor) {
          o.errorsProcessor[k] = x.errorsProcessor[k].bind(x.errorsProcessor);
        }
      }
    }
  },

  customParameterSelected: function(parameterId) {
    if ($('customParameterSelector').selectedIndex === 1) {
      var newParamRow = $j("#customParam_new").clone();
      newParamRow.removeAttr("id");
      $j("#customParametersTable").append(newParamRow);
      $('customParameterSelector').selectedIndex = 0;
      newParamRow.find("input[name='new-parameter-name']").focus();

      var valueField = $j(newParamRow).find("textArea[name='new-parameter-value']");
      valueField.attr("id", "new-parameter-" + this.newParameterCounter++);
      BS.AvailableParams.attachPopupsTo('settingsId=' + this.getBuildTypeId(), $j(valueField));
    } else {
      var paramRow = $j("#customParam_" + parameterId);
      $j("#customParametersTable").append(paramRow);
      $j("#customParameterSelector option[value='" + parameterId + "']").remove();
      this.customBuildParametersIds.push(parameterId);
      $j("#selectedParametersHeader").removeAttr("hidden");
    }
    BS.jQueryDropdown($j("#customParameterSelector")).ufd('changeOptions');
  },

  removeBuildParameter: function(parameterId) {
    var paramRow = $j("#customParam_" + parameterId);
    $j("#hiddenParamsContainer table").append(paramRow);
    $j("#customParameterSelector").append($j(".buildParameterOption_" + parameterId).clone());
    BS.jQueryDropdown($j("#customParameterSelector")).ufd('changeOptions');
    this.customBuildParametersIds.splice(this.customBuildParametersIds.indexOf(parameterId), 1);
    if (this.customBuildParametersIds.length === 0) {
      $j("#selectedParametersHeader").attr("hidden", "true");
    }
  },

  removeNewParameter: function(el) {
    $j(el).closest("tr").remove();
  },

  initBuildParametersView: function() {
    this.customBuildParametersIds.forEach(function(parameterId) {
      var paramRow = $j("#customParam_" + parameterId);
      $j("#customParametersTable").append(paramRow);
      $j("#customParameterSelector option[value='" + parameterId + "']").remove();
      $j("#selectedParametersHeader").removeAttr("hidden");
    });
    BS.jQueryDropdown($j("#customParameterSelector")).ufd('changeOptions');
  }
})));

BS.TestOnFinishedBuildDialog = OO.extend(BS.AbstractModalDialog, {
  getContainer: function () {
    return $('testOnFinishedBuildDialog');
  },

  submit: function () {
    $j('#testOnFinishedBuildResult').html('');
    BS.Util.show("testOnFinishedBuildProgress");

    BS.ajaxRequest(window['base_uri'] + "/admin/testOnFinishedBuild.html?" + $j(BS.Util.escapeId("buildFailureOnMessage.finishedBuildId")).serialize(), {
      method: "post",
      parameters: BS.BuildFeatureDialog.serializeParameters(),

      onComplete: function (transport) {
        BS.Util.hide("testOnFinishedBuildProgress");
        var responseXML = transport.responseXML;
        var err = BS.XMLResponse.processErrors(responseXML, {}, BS.BuildFeatureDialog.propertiesErrorsHandler); // show errors on the initial dialog
        if (!err) {
          $j('#testOnFinishedBuildResult').html(responseXML.documentElement.childNodes[0].nodeValue);
        } else {
          BS.TestOnFinishedBuildDialog.close();
        }
      }
    });
    return false;
  },

  afterClose: function () {
    $j('#testOnFinishedBuildResult').html('');
  },

  showBuildLog: function (buildId) {
    window.location.href = window['base_uri'] + '/viewLog.html?tab=buildLog&logTab=tree&buildId=' + buildId;
  }
});

BS.AddTriggerRuleDialog = OO.extend(BS.AbstractModalDialog, {
  attachedToRoot: false,

  getContainer: function () {
    return $('addTriggerRuleDialog');
  },

  showDialog: function () {
    this.showCentered();
    this.bindCtrlEnterHandler(this.submit.bind(this));
  },

  submit: function () {
    if (!this.validate()) return false;

    var rule = $('triggerBuild1').checked ? '+:' : '-:';
    if (!$('username').value.empty()) {
      rule += 'user=' + $('username').value;
    }
    if ($('vcsRoot').selectedIndex > 0) {
      if (!rule.endsWith(';') && !rule.endsWith(':')) rule += ';';
      rule += 'root=' + $('vcsRoot').options[$('vcsRoot').selectedIndex].value;
    }
    if (!$('comment').value.empty() && $('comment').value != '<comment regexp>') {
      if (!rule.endsWith(';') && !rule.endsWith(':')) rule += ';';
      rule += 'comment=' + $('comment').value;
    }
    if (!rule.endsWith(':')) rule += ':';
    rule += $('wildcard').value;

    if (!$('triggerRules').value.empty()) {
      $('triggerRules').value += '\n';
    }
    $('triggerRules').value += rule;
    BS.MultilineProperties.show('triggerRules', true);
    this.close();
    return false;
  },

  validate: function () {
    if (!$('triggerBuild1').checked && !$('triggerBuild2').checked) {
      alert('Please choose rule type');
      return false;
    }
    if ($('wildcard').value.empty()) {
      alert('Wildcard cannot be empty');
      $('wildcard').focus();
      return false;
    }
    return true;
  }
});

BS.RunnersDiscovery = {
  update: function(settingsId) {
    $j('#discoveredRunners').html('');

    this.showProgress();

    this.startDiscovering(settingsId);
  },

  startDiscovering: function (settingsId) {
    var that = this;
    BS.ajaxRequest(window['base_uri'] + "/admin/discoverRunners.html", {
      parameters: "id=" + settingsId + "&startDiscovering=true"
    });

    window.setTimeout(function() {
      BS.RunnersDiscovery.showSuggestions(settingsId);
    }, 3000);
  },

  cancel: function(settingsId) {
    var that = this;
    BS.ajaxRequest(window['base_uri'] + "/admin/discoverRunners.html", {
      parameters: "id=" + settingsId + "&cancelDiscovery=true",
      onComplete: function () {
        that.hideProgress();
      }
    });
  },

  showProgress: function() {
    $j('#discoveryProgress').show();
    $j('#discoveryProgressContainer').show();
    if ($j('#updateDiscoveryContainer')) {
      $j('#updateDiscoveryContainer').hide();
    }
  },

  hideProgress: function() {
    $j('#discoveryProgressContainer').hide();
    if ($j('#updateDiscoveryContainer')) {
      $j('#updateDiscoveryContainer').show();
    }
  },

  showSuggestions: function(settingsId, afterComplete) {
    $j('#discoveredRunners').show();
    if ($j('#discoveredRunners input[type=checkbox]:checked').length > 0) {
      return false;
    }

    BS.ajaxUpdater($('discoveredRunners'), window['base_uri'] + "/admin/discoverRunners.html", {
      evalScripts: true,
      parameters: "id=" + settingsId + "&showDiscovered=true",
      method: 'get',
      onComplete: function() {
        if (afterComplete) {
          afterComplete();
        }
      }
    });

    return true;
  },

  addObjects: function(settingsId, objectIds) {
    if (objectIds.length == 0) {
      alert("Please select at least one build step");
      return;
    }

    var objectIdsParam = "";
    for (var i=0; i<objectIds.length; i++) {
      var id = objectIds[i];
      objectIdsParam += "&objectId=" + id;
    }
    BS.ajaxRequest(window['base_uri'] + "/admin/discoverRunners.html", {
      parameters: "id=" + settingsId + "&addObject=true" + objectIdsParam,
      onComplete: function (transport) {
        if (transport.responseXML) {
          BS.XMLResponse.processRedirect(transport.responseXML);
        } else {
          BS.reload(true);
        }
      }
    });

    return false;
  }
};

BS.EditArtifacts = {
  showPopup: function(elem, buildTypeId) {
    var popup = new BS.Popup("editArtifactsTreePopup", {
      hideOnMouseOut: false,
      hideOnMouseClickOutside: true,
      shift: {x: 20, y: 0},
      url: window["base_uri"] + "/editArtifactsTreePopup.html?buildTypeId=" + buildTypeId
    });
    popup.showPopupNearElement(elem);

    this.prepareSelection();

    return false;
  },

  prepareSelection: function() {
    var textarea = $j("#artifactPaths");
    $j(window).off("bs.agentFile bs.agentDir").on("bs.agentFile bs.agentDir", function(e, path) {
      var pathToAppend = e.namespace == "agentFile" ? path : path + " => " + path;
      var value = textarea.val();
      if (value.length > 0) {
        var lines = value.split("\n");
        lines.push(pathToAppend);
        textarea.val(lines.join("\n"));
      } else {
        textarea.val(pathToAppend);
      }
      BS.VisibilityHandlers.updateVisibility('artifactPaths');
      BS.EditBuildTypeForm.setModified(true);   // In theory this can be wrong, but in 99% of cases the form is modified.
    });
  }
};


BS.EditDsl = {
  activeClass: 'dsl_active',
  inactiveClass: 'dsl_inactive',

  hideEditDslButtons: function(){
    if ($j('.dialogDslButtons')) {$j('.dialogDslButtons').hide();}
  },

  showEditDslButtons: function(){
    if ($j('.dialogDslButtons')) {$j('.dialogDslButtons').show();}
  },

  hideSuccessMessages: function() {
    var successMessageContainer = $j('.successMessage');
    if (successMessageContainer) {
      successMessageContainer.hide();
    }
  },

  showEditDslPanel: function(selector1, selector2) {
    BS.EditDsl.hideSuccessMessages();
    $j("#showDSL").val("");
    $j("#showSourceDSL").val("");
    $j("#showArtifactDSL").val("");
    if (selector1 == undefined || selector2 == undefined) {
      selector1 = '#uiModeDialog';
      selector2 = '.fragmentEditDsl'
    }
    if (selector1 == '#uiMode') {
      $j(selector1).addClass(BS.EditDsl.inactiveClass);
      $j(selector2).show();
    } else {
      $j(selector2).height($j(selector1).height());
      $j(selector2).addClass(BS.EditDsl.activeClass);
   }
  },

  hideEditDslPanel: function(selector1, selector2) {
    BS.EditDsl.hideSuccessMessages();
    $j("#showDSL").val("");
    $j("#showSourceDSL").val("");
    $j("#showArtifactDSL").val("");
    if (selector1 == undefined || selector2 == undefined) {
      selector1 = '#uiModeDialog';
      selector2 = '.fragmentEditDsl'
    }
    if (selector1 == '#uiMode') {
      $j(selector1).removeClass(BS.EditDsl.inactiveClass);
      $j(selector2).hide();
    } else {
      $j(selector2).removeClass(BS.EditDsl.activeClass);
    }
  },

  closeEditDsl: function(controlId, uiPanel, dslEditor) {
    $j("#showDSL").val("");

    BS.EditDsl.hideEditDslPanel(uiPanel, dslEditor);
    ReactUI.closeEditDsl(controlId);
  },

  setCustomLoadDslFragment(callback) {
    this.customLoadDslFragment = callback
  },

  customLoadDslFragment() {
    return Promise.resolve();
  },

  getCurrentStage: function(){
    var location = document.location.href;
    if (location.indexOf('/editBuildTypeVcsRoots.html') > -1) {
      return 'vcs';
    }
    if (location.indexOf('/editTriggers.html') > -1) {
      return 'triggers';
    }
    if (location.indexOf('/editBuildRunners.html') > -1) {
      return 'steps';
    }
    if (location.indexOf('/editBuildFeatures.html') > -1) {
      return 'features';
    }
    if (location.indexOf('/editBuildFailureConditions.html') > -1) {
      return 'failureConditions';
    }
    if (location.indexOf('/editRequirements.html') > -1) {
      return 'requirements';
    }
    if (location.indexOf('/editDependencies.html') > -1) {
      return 'dependencies';
    }
    if (location.indexOf('/editBuildParams.html') > -1) {
      return 'params';
    }
    return undefined;
  }
};
