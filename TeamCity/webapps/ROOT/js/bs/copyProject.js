BS.AbstractCopyForm = OO.extend(BS.AbstractCopyMoveDialog, {
  showDialog: function(sourceId) {
    var temporaryContainerId = this.formElementId() + "Container",
      parameters = {};

    parameters[this.fetchParamName] = sourceId;
    this._loadingTimeoutId = setTimeout(function () {
      BS.LoadingDialog.showCentered();
      this._loadingTimeoutId = null;
    }.bind(this), this.loaderDisplayTimeout);

    // temporary container is used to fetch data by ajaxUpdater only, form jumps out of it
    // as soon as it is shown. Remove existing if found:
    $j(BS.Util.escapeId(temporaryContainerId)).remove();
    $j(this.formElement()).remove();

    $j("body").append("<div id='" + temporaryContainerId + "'></div>");
    BS.ajaxUpdater($(temporaryContainerId), window["base_uri"] + this.fetchUrl(), {
      method: "GET",
      evalScripts: true,
      parameters: parameters,
      onComplete: function () {
        this._loadingTimeoutId ? clearTimeout(this._loadingTimeoutId) : BS.LoadingDialog.close();
        this._loadingTimeoutId = null;

        this._onFetchDialogComplete();
      }.bind(this)
    });

    return false;
  },

  _onFetchDialogComplete: function() {
    var that = this;
    this.showCentered();
    $j(this.formElement().projectId).trigger("change").focus();
    $j(BS.Util.escapeId(this.inputId)).on("keyup change", function() {
      $j(BS.Util.escapeId(that.copyButtonId())).prop("disabled", !this.value);
    });
    this.bindCtrlEnterHandler(this.submitCopy.bind(this));
  }
});

BS.CopyProjectForm = OO.extend(BS.AbstractCopyForm, {
  __baseId: 'copyProject',
  fetchParamName: 'projectId',

  _onFetchDialogComplete: function () {
    this.showCentered();
    $j(this.formElement().newParent).change(function() {
      $j("#copyButton").prop("disabled", !$j(this).val());
    }).trigger("change");
    this.formElement().newName.focus();
    this.bindCtrlEnterHandler(this.submitCopy.bind(this));
  },

  submitCopy: function() {
    var that = this;
    BS.AdminActions.createHiddenMappingIfNecessary(that.getContainer());

    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onSaveProjectErrorError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },

      onMaxNumberOfBuildTypesReachedError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },

      onProjectNotFoundError: function(elem) {
        alert(elem.firstChild.nodeValue);
        BS.XMLResponse.processRedirect(elem.ownerDocument);
      },

      onEmptyProjectNameError: function(elem) {
        $('error_newProjectName').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField(that.formElement().newName);
      },

      onInvalidProjectNameError: function(elem) {
        $('error_newProjectName').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField(that.formElement().newName);
      },

      onInvalidProjectIdError: function(elem) {
        $("error_newProjectExternalId").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField(that.formElement().newProjectExternalId);
      },

      onInvalidSubprojectIdError: function(elem) {
        $("error_newSubProjects").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField($("copyMapping"));
      },

      onDuplicateProjectIdError: function(elem) {
        $("error_newProjectExternalId").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField(that.formElement().newProjectExternalId);
      },

      onDuplicateSubprojectIdError: function(elem) {
        $("error_newSubProjects").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField($("copyMapping"));
      },

      onInaccessibleTemplateError: function(elem) {
        $("error_newParent").innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField($("newParent"));
      },

      onCompleteSave: function(form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);

        if (!err) {
          BS.XMLResponse.processRedirect(responseXML);
        }
      }
    }));

    return false;
  }
});

BS.CopyBuildTypeForm = OO.extend(BS.AbstractCopyForm, {
  __baseId: 'copyBuildType',
  fetchParamName: 'buildTypeId',
  inputId: 'newBuildTypeName',

  submitCopy: function() {
    var that = this;

    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onSaveProjectErrorError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },

      onMaxNumberOfBuildTypesReachedError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },

      onProjectNotFoundError: function(elem) {
        $('error_projectId').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField(that.formElement().projectId);
      },

      onEmptyBuildTypeNameError: function(elem) {
        $('error_newName').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField(that.formElement().newName);
      },

      onEmptyIdError: function(elem) {
        $('error_newBuildTypeExternalId').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField(that.formElement().newBuildTypeExternalId);
      },

      onInvalidIdError: function(elem) {
        $('error_newBuildTypeExternalId').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField(that.formElement().newBuildTypeExternalId);
      },

      onDuplicateIdError: function(elem) {
        $('error_newBuildTypeExternalId').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField(that.formElement().newBuildTypeExternalId);
      },

      onBuildTypeNotFoundError: function(elem) {
        alert(elem.firstChild.nodeValue);
        BS.XMLResponse.processRedirect(elem.ownerDocument);
      },

      onCompleteSave: function(form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);

        if (!err) {
          BS.XMLResponse.processRedirect(responseXML);
        }
      }
    }));

    return false;
  }
});

BS.CopyTemplateForm = OO.extend(BS.AbstractCopyForm, {
  __baseId: 'copyTemplate',
  fetchParamName: 'templateId',
  inputId: 'newTemplateName',

  submitCopy: function() {
    var that = this;

    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onSaveProjectErrorError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },

      onProjectNotFoundError: function(elem) {
        $('error_projectId').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField(that.formElement().projectId);
      },

      onTemplateNotFoundError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },

      onInvalidNameError: function(elem) {
        $('error_newName').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField(that.formElement().newName);
      },

      onEmptyIdError: function(elem) {
        this.onInvalidIdError(elem);
      },

      onDuplicateIdError: function(elem) {
        this.onInvalidIdError(elem);
      },

      onInvalidIdError: function(elem) {
        $('error_newTemplateExternalId').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField(that.formElement().newTemplateExternalId);
      },

      onCompleteSave: function(form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);

        if (!err) {
          BS.XMLResponse.processRedirect(responseXML);
        }
      }
    }));

    return false;
  }
});

BS.RegenerateForm = OO.extend(BS.AbstractCopyForm, {
  __baseId: 'regenerate',
  fetchParamName: 'projectId',

  _onFetchDialogComplete: function () {
    this.showCentered();
    if ($("mapping")) {
      $("mapping").focus();
      this.bindCtrlEnterHandler(this.submit.bind(this));
    }
  },

  submit: function() {
    var that = this;
    BS.AdminActions.createHiddenMappingIfNecessary(that.getContainer());

    BS.FormSaver.save(this, window["base_uri"] + "/admin/regenerate.html", OO.extend(BS.ErrorsAwareListener, {
      onMappingError: function(elem) {
        $('error_mapping').innerHTML = fixErrorMessage(elem.firstChild.nodeValue);
        that.highlightErrorField($("mapping"));
      },

      onCompleteSave: function(form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);

        if (!err) {
          that.close();
          BS.XMLResponse.processRedirect(responseXML);
        }
      }
    }));

    return false;
  }
});
