BS.RunBuildDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.DialogWithProgress, OO.extend(BS.FileBrowse, {
  formId: "runBuild",
  tabs: ["general-tab", "dependencies-tab", "changes-tab", "properties-tab", "comment-tab"],

  /** section content tbody id -> section header id*/
  sectionContent2Header: {customConfigParams: 'configurationParametersHeader',
                          customBuildSystemProps: 'systemPropertiesHeader',
                          customBuildEnvVars: 'environmentVariablesHeader'},

  newParameterCounter: 0, //increment
  newParameterNumber : 0, //actual number of newParameters

  customControls : {},
  CustomControls : {},

  updateTimer : null,

  _parameterHighlightStatus : {},

  redirectToQueued: false,

  getRefreshUrl: function() {
    return window['base_uri'] + "/runCustomBuild.html";
  },

  _customParametersContainerId : 'properties-tab',

  serializeParameters: function(options) {
    options = OO.extend({
      tabsFilter: function(/*tabId*/) {
        return true;
      },
      customParameterFilter: function(/*paramId*/) {
        return true;
      },
      extra: {}
    }, options || {});

    var params = [];

    // Always include hidden parameters (buildTypeId, ...).
    params.push(BS.Util.serializeForm($("runCustomBuildHidden")));

    // Process tabs inputs.
    for (var i = 0; i < this.tabs.length; i++) {
      var tabId = this.tabs[i];
      if (!options.tabsFilter(tabId)) {
        continue;
      }

      var el = $(tabId);
      if (!el) continue;
      if (el.id == this._customParametersContainerId) {
        params.push(this.serializeCustomParameters(options.customParameterFilter));
      } else {
        params.push(BS.Util.serializeForm(el));
      }
    }

    // Process extra inputs.
    params.push(Object.toQueryString(options.extra));

    return params
      .filter(function(x){ return x && x.length > 0})
      .inject("", function(acc, v) { return acc + (acc.length > 0 ? '&' : '') + v; })
    ;
  },

  serializeCustomParameters: function(filter) {
    var containerId = this._customParametersContainerId;

    if (!$(containerId)) return "";
    var result = {};
    for(var id in this.customControls) {
      if (filter && !filter(id)) {
        continue;
      }

      var control = this.customControls[id];
      var objName = control.getFormSerializeName();
      try {
        var val = control.getControlValue();
        if (val) {
          result[objName] = val;
        }
      } catch(e) {
        BS.Log.error('Failed to get value of control: ' + objName + ". " + e);
      }
    }

    //handle user-provided parameters
    Form
    .getElements($(containerId))
        .filter(function (el) {
                      if (!el || !el.name) return false;
                      var n = el.name;
                      return ((!filter) || filter(n)) && (n == 'name'
                          || n == 'value'
                          || n.endsWith('.name')
                          || n.endsWith('.value')
                          || n == "customParameterNames"
                          || n.startsWith("marker_"));
                    })
        .each(function (el) {
                var element = $(el);
                if (!element) return;

                var key = element.name;
                if (!key) return;

                var value = element.getValue();
                if (value == null || value == undefined) return;

                var rValue = result[key];
                if (!rValue) rValue = [];
                rValue.push(value);
                result[key] = rValue;
              });

    return Object.toQueryString(result);
  },

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

    BS.RunBuildDialog.customControls[controlId] = o;

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

  getContainer: function() {
    return $('runBuildDialog');
  },

  formElement: function() {
    return $('runBuild');
  },

  savingIndicator: function() {
    return $('runBuildProgress');
  },

  eachCustomControl: function(action) {
    for(var id in this.customControls) {
      var value = this.customControls[id];
      action(value);
    }
  },

  setupEventHandlers: function() {
    var that = this;
    this.setUpdateStateHandlers({
      updateState: function() {
        that.updateParametersState();
      },

      saveState: function() {
        that.submit();
      }
    });
  },

  updateParametersState: function() {
    var that = this;
    var params = this.serializeCustomParameters();
    //skip updates if parameters form was not shown at all
    if (!params || params.length == 0) return;

    BS.ajaxRequest(this.formElement().action, {
      method: 'post',
      parameters : that.serializeParameters({
        extra: {
          checkChanged: "true"
        }
      }),
      onComplete: function(transport) {
        var xml = transport.responseXML;
        if (!xml) return;
        var changed = xml.getElementsByTagName('changes');
        if (changed && changed.length == 1 && changed[0]) {
          var names = changed[0].getElementsByTagName('change');
          var toHighlight = {};
          for(var i = 0; i < names.length; i++) {
            toHighlight[names[i].getAttribute('id')] = true;
          }

          for(var key in that.customControls) {
            that.setParameterHighlightStatus(that.customControls[key].containerId, !!toHighlight[key]);
          }

          that.showValidationErrors(xml);
        }
      }
    })
  },

  showValidationErrors: function (xml) {
    var xmlErrorsXml = BS.XMLResponse._xmlErrorsXml(xml);
    var parameterErrors = false;

    var updated = [];
    for (var i = 0; i < xmlErrorsXml.length; i++) {
      var key1 = xmlErrorsXml[i][0];
      var val = xmlErrorsXml[i][1];

      if (key1.indexOf("parameter_") == 0) {
        if (key1.indexOf('!') > 0) {
          parameterErrors = true;
          var kv = key1.split('!');
          if (kv == 2) {
            var baseError = kv[0];
            var customError = kv[1];

            var control = this.customControls[baseError];
            var handlerId = "on" + customError + "Error";
            if (control != null && control.errorsProcessor[handlerId]) {
              control.errorsProcessor[handlerId](val);
            } else if ($(control)) {
              updated.push($(control));
              BS.PluginPropertiesForm.showError(control, val);
            } else {
              updated.push($(control));
              BS.PluginPropertiesForm.showError(baseError, val);
            }
          }
        } else {
          updated.push($j(".error#error_" + key1)[0]);
          BS.PluginPropertiesForm.showError(key1, val);
          parameterErrors = true;
        }
      }
    }
    $j(this.formElement()).find('.error').each(function (i, item) {
      if (item.id.startsWith("error_") && updated.indexOf(item) < 0) {
        item.innerHTML = "";
      }
    });
    return parameterErrors;
  },

  submit: function() {
    var personalBuild = $j('#personal').length > 0 && $j('#personal')[0].checked;
    var personalPatchPath = $j('#runBuildDialog input[name="file:personalPatch"]').val();
    $j('input[name=personalPatchUploaded]').val('');

    if (personalPatchPath == '' || !personalBuild) {
      this.doSubmit();
    } else {
      // if personal patch file was selected then we need to first upload this file,
      // wait for upload to complete and only then submit custom build dialog form
      // to wait for upload complete we need to track 'load' event for the hidden iframe:
      // once upload finishes, iframe will get response and we'll see 'load' event
      $j('#personalPatchHiddenIframe').off('load');
      $j('#personalPatchHiddenIframe').on('load', function() {
        $j('input[name=personalPatchUploaded]').val('true');

        var hasErrors = BS.XMLResponse.processErrors($j('#personalPatchHiddenIframe')[0].contentWindow.document, {}, function(id, elem) {
          alert("Error uploading patch file: " + elem.firstChild.nodeValue);
        });

        if (!hasErrors) {
          BS.RunBuildDialog.doSubmit();
        }

      });

      $j('#personalPatchUploadForm')[0].submit();
    }

    return false;
  },

  doSubmit: function() {
    var that = this;

    if ($j("#customBuild-parameterName").val()) {        // TW-17139
      this.addParameter();
    }

    this.clearErrors();
    if (this.beforeTrigger) {
      this.beforeTrigger();
    }
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      no_build_type: function(elem) {
        alert(elem.firstChild.nodeValue);
      },
      invalid_agent: function(elem) {
        alert(elem.firstChild.nodeValue);
      },
      revisionsNotAvailable: function(elem) {
        alert(elem.firstChild.nodeValue);
      },
      addToQueueError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },
      illegalPersonalBuildError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },
      unknownError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },
      runExtensionError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },
      invalidSubmitParameters: function(elem) {
        alert(elem.firstChild.nodeValue);
      },
      autoGeneratedBranchName: function(elem) {
        if (confirm(elem.firstChild.nodeValue)) {
          that.formElement().forceAutoGeneratedBranch.value = 'true';
          that.submit();
        }
      },
      onCompleteSave: function(form, responseXML, hasErrors) {
        var parameterErrors = that.showValidationErrors(responseXML);

        hasErrors = hasErrors || parameterErrors;

        if (form.isVisible()) {
          form.setSaving(false);
          form.enable();
          if (!hasErrors) form.close();
        }

        if (parameterErrors) {
          BS.RunBuildDialog.showTab('properties-tab');
        }

        if (hasErrors) {
          BS.RunBuild.reject(new Error('An error occurred in attempt to trigger build'));
          return;
        }

        BS.Hider.hideAll();

        var parentElement = responseXML.documentElement;
        if (parentElement != null) {
          var buildsNodes = parentElement.getElementsByTagName("queuedBuilds");
          if (buildsNodes && buildsNodes.length > 0) {
            var buildNodes = buildsNodes.item(0).getElementsByTagName("queuedBuild");
            if (buildNodes && buildNodes.length == 1) {
              var itemId = BS.RunBuild.fixItemId(buildNodes.item(0).getAttribute("itemId"));
            }
          }
        }

        BS.RunBuild.resolve(itemId);

        if (itemId && that.redirectToQueued) {
          document.location.href = window['base_uri'] + "/viewQueued.html?itemId=" + itemId;
        } else if (form.formElement().redirectTo.value != '') {
          document.location.href = form.formElement().redirectTo.value;
        }
      }
    }));
  },

  addParameter: function() {
    var type = $j('#customBuild-paramType').val(),
        name = $j('#customBuild-parameterName').val(),
        value = $j('#customBuild-parameterValue').val(),
        paramsTbody,
        header;

    if (type === 'system') {
      paramsTbody = $('customBuildSystemProps');
    } else if (type === 'env') {
      paramsTbody = $('customBuildEnvVars');
    } else {
      paramsTbody = $('customConfigParams');
      type = 'config';
    }

    header = $j(BS.Util.escapeId(this.sectionContent2Header[paramsTbody.id]));

    var content = $('newParamTemplate').firstChild.nodeValue;
    content = this._replacePattern(content, { "\\[prefix\\]": type + "."} );
    content = this._replacePattern(content, { "\\[id\\]": this.newParameterCounter++} );
    paramsTbody.insert({bottom: content});
    this.getTabByElement(paramsTbody).addClass("modifiedParam");

    header.show();

    var children = this._childElements(paramsTbody);
    var lastTr = children[children.length - 1];
    var trCells = this._childElements(lastTr);
    var nameField = $(trCells[0]).firstDescendant();
    var valueField = $(trCells[1]).firstDescendant().firstDescendant();
    nameField.value = name;
    valueField.value = value;
    var escapeHandler = function(event) {
      if (event.keyCode == Event.KEY_RETURN) {
        Event.stop(event);
      }
    };
    nameField.on("keypress", escapeHandler.bindAsEventListener(this));

    BS.VisibilityHandlers.attachTo(valueField.id, {
      updateVisibility: function() {
        jQuery(valueField).textAreaExpander(0, 100, 'updateVisibility');
      }
    });

    $j('#customBuild-paramType').val('conf');
    $j('#customBuild-parameterName').val('').focus();
    $j('#customBuild-parameterValue').val('');

    this.newParameterNumber++;
    BS.AvailableParams.attachPopupsTo('settingsId=buildType:' + this.formElement().buildTypeId.value, $j(valueField));
    BS.VisibilityHandlers.updateVisibility(this.formElement());
  },

  _replacePattern: function(content, patterns) {
    var result = content;
    for (var key in patterns) {
      result = result.replace(new RegExp(key, "g"), patterns[key]);
    }
    return result;
  },

  removeParameter: function(paramTr) {
    var tbody = paramTr.parentNode;
    tbody.removeChild(paramTr);
    if (!$j(tbody).children().size()) {
      $j(BS.Util.escapeId(this.sectionContent2Header[tbody.id])).hide();
    }
    this.newParameterNumber--;
    this._parameterHighlightStatus = {};
    BS.VisibilityHandlers.updateVisibility(this.formElement());
  },

  resetParameter: function(id) {
    var control = this.customControls[id];
    if (!control) return;

    this.flipParameter(id);

    this.setParameterHighlightStatus(control.containerId, false);
  },

  resetAllParameters: function() {
    $j('#properties-tab tr.modifiedParam td.edit a').click();
    $j('#customBuild-parameterName').val('');
    $j('#customBuild-parameterValue').val('');
  },


  flipParameter: function(id) {
    var control = this.customControls[id];
    if (!control) return;

    var that = this;
    var paramsString = this.serializeParameters({
      tabsFilter: function(tabId) {
        return tabId == that._customParametersContainerId;
      },
      customParameterFilter: function(paramId) {
        return false;
      },
      extra : {
        reset: 1,
        flipControl: id
      }
    });

    var autocompleteRequired = $(id).hasClassName('__popupAttached');
    $('refresh_container_' + id + '_div').refresh(
      null, // progress
      paramsString,
      function () {
        if (autocompleteRequired) {
          BS.VisibilityHandlers.updateVisibility(that.formElement());
          BS.AvailableParams.attachPopupsTo('settingsId=buildType:' + that.formElement().buildTypeId.value, BS.Util.escapeId(id));
        }
      }
    );
  },

  disableSubmit: function() {
    $j('#runCustomBuildButton').prop('disabled', true);
  },

  enableSubmit: function() {
    $j('#runCustomBuildButton').prop('disabled', false);
  },

  setParameterHighlightStatus: function(containerId, changed) {
    if (!containerId) return;
    if (this._parameterHighlightStatus[containerId] == changed) return;
    this._parameterHighlightStatus[containerId] = changed;

    var tr = $(containerId).up('tr');
    if (changed) {
      tr.addClassName('modifiedParam');
    } else {
      tr.removeClassName('modifiedParam');
    }

    changed |= this.newParameterNumber > 0;
    if (!changed) {
      for(var key in this._parameterHighlightStatus) {
        if (this._parameterHighlightStatus[key]) {
          changed = true;
          break;
        }
      }
    }

    if (changed) {
      this.getTabByElement(tr).addClass("modifiedParam");
    } else {
      this.getTabByElement(tr).removeClass("modifiedParam");
    }
  },

  _childElements: function(parentNode) {
    var elems = [];
    for (var i=0; i<parentNode.childNodes.length; i++) {
      var node = parentNode.childNodes[i];
      if (node.nodeType == 1) {
        elems.push(node);
      }
    }
    return elems;
  },

  updateChangesContainer: function(containerId, userAction) {
    BS.RunBuildDialog.disable();

    var postParams = this.serializeParameters({
      extra: {
        updateChanges: "true",
        userAction: userAction || ""
      }
    });

    return new Promise(function(resolve) {
      BS.ajaxRequest(this.formElement().action, {
        parameters: postParams,
        onComplete: function () {
          $(containerId).refresh($("changesProgress"), null, function () {
            ReactUI.getSandbox(BS.RunBuildDialog.getContainer()).mutate(function () {
              BS.RunBuildDialog.enable();
              resolve();
            });
          });
        }
      });
    }.bind(this));
  },

  highlightSettingRevisions: function() {
    var buildSettingsMode = $j('#buildSettingsMode').val();
    if (buildSettingsMode === 'vcs') {
      $j('.customDialogSettingsRevision').removeClass('notFixedSettingsRevision');
    } else {
      $j('.customDialogSettingsRevision').addClass('notFixedSettingsRevision');
    }
    var buildSettingsRow = $j('#buildSettingsMode').parents("tr");
    this._toggleHighlight(buildSettingsRow, buildSettingsMode !== 'default');
  },

  verifyRevision: function(buildTypeId, vcsRootId, revision, vcsBranchName, errorCallback) {
    BS.ajaxRequest(this.formElement().action, {
      method: 'post',
      parameters: "verifyRevision=" + encodeURIComponent(revision) + "&buildTypeId=" + buildTypeId + "&vcsRootId=" + vcsRootId + "&vcsBranchName=" + encodeURIComponent(vcsBranchName),
      onComplete: function(transport) {
        var handled = BS.XMLResponse.processErrors(transport.responseXML, {
          revisionCantBeVerified: function (elem) {
            errorCallback('revisionCantBeVerified', elem.firstChild.nodeValue);
          },
          revisionIsNotReachable: function (elem) {
            errorCallback('revisionIsNotReachable', elem.firstChild.nodeValue);
          },
          revisionIsInvalid: function (elem) {
            errorCallback('revisionIsInvalid', elem.firstChild.nodeValue);
          }
        });

        if (!handled) {
          errorCallback('revisionVerified', '');
        }
      }
    })
  },

  updateComment: function(comment) {
    if (comment != null && comment.length > 0) {
      this.formElement().buildComment.value = comment;
    }
  },

  appendTag: function(tag) {
    BS.Util.addWordToTextArea(this.formElement().buildTagsInfo, tag);
  },

  show: function() {
    this.propertiesTabInited = false;
    this._parameterHighlightStatus = {};
    this.newParameterNumber = 0;
    this.showCentered();
    this.bindCtrlEnterHandler(this.submit.bind(this));

    $j("#customBuild-parameterName").unbind("keyup").on("keyup", BS.EditParameterDialog.createParamNameChangeHandler($j("#customBuild-parameterName"), $j("#customBuild-paramType")));

    $j('#customBuild-parameterName').placeholder({text: '&lt;Name>'});
    $j('#customBuild-parameterValue').placeholder({text: '&lt;Value>'});
    BS.VisibilityHandlers.attachTo('customBuild-parameterName', {
      updateVisibility: function() {
        $j('#customBuild-parameterName').placeholder('refresh');
      }
    });
    BS.VisibilityHandlers.attachTo('customBuild-parameterValue', {
      updateVisibility: function() {
        $j('#customBuild-parameterValue').placeholder('refresh');
      }
    });

    var typeChangeHandler = BS.EditParameterDialog.createParamTypeChangeHandler($j("#customBuild-paramType"), $j("#customBuild-parameterName"));
    var customTypeChangeHandler = function () {
      typeChangeHandler();
      $j('#customBuild-parameterName').placeholder('refresh');
    };
    $j("#customBuild-paramType")
        .off("change").on("change", customTypeChangeHandler)
        .off("keyup").on("keyup", function(event) {
           if (BS.EditParameterDialog.canChangeSelectValue(event)) {
             customTypeChangeHandler();
           }
         });

    this.setupEventHandlers();

    BS.VisibilityHandlers.updateVisibility(this.formElement());
  },

  highlightCustomAgent: function(element) {
    var td = jQuery(element).parents("td");
    this._toggleHighlight(td, true);
  },

  highlightDependency: function(element, defValue) {
    var changed = element.options[element.selectedIndex].value != defValue;
    var tr = jQuery(element).closest("tr");
    this._toggleHighlight(tr, changed);
  },

  highlightChanges: function(element) {
    var td = jQuery(element).parents("td");
    this._toggleHighlight(td, true);
  },

  _toggleHighlight: function(elem, highlight) {
    if (highlight) {
      elem.addClass("modifiedParam");
    } else {
      elem.removeClass("modifiedParam");
    }
    this.highlightModifiedTabs();
  },

  afterClose: function() {
    this._detachVisibilityHandlers();
    if (this.updateTimer) {
      clearTimeout(this.updateTimer);
    }
    this.customControls = {};
    ReactUI.unmountContainer('runBranchSelector_container');
  },

  _detachVisibilityHandlers: function() {
    BS.VisibilityHandlers._collectElements($('runCustomBuildDiv'))
      .forEach(function (elem) { BS.VisibilityHandlers.detachFrom(elem.id);});
  },

  showTab: function(tabId) {
    var idx = this.tabs.indexOf(tabId);
    if (idx < 0 || !$(this.tabs[idx])) return false; // do nothing, tab does not exist

    for (var i = 0; i < this.tabs.length; ++i) {
      if (this.tabs[i] != tabId) {
        jQuery(BS.Util.escapeId(this.tabs[i])).hide();
      }
    }
    jQuery(BS.Util.escapeId(tabId)).show();

    jQuery("#runCustomBuildDiv ul li").removeClass("selected");
    jQuery("#runCustomBuildDiv ul li#tab-" + idx).addClass("selected");
    if (tabId != 'properties-tab' || jQuery("#properties-tab .paramName").length <= 500) {
      BS.VisibilityHandlers.updateVisibility('runCustomBuildDiv');
    }

    this.recenterDialog();

    // Init field autocompletes "asynchronously" when the tab is first shown
    var self = this;
    window.setTimeout(function() {
      if (tabId == 'properties-tab' && !self.propertiesTabInited) {
        BS.AvailableParams.attachPopups('settingsId=buildType:' + self.formElement().buildTypeId.value);
        self.propertiesTabInited = true;
      }
    }, 0);

    return false;
  },

  getTabByElement: function(element) {
    var containerDiv = jQuery(element).closest("#runCustomBuildContentDiv .tabContent");
    var id = containerDiv.attr("id");
    var tabId = {
      "general-tab": "#tab-0",
      "dependencies-tab": "#tab-1",
      "changes-tab": "#tab-2",
      "properties-tab": "#tab-3",
      "comment-tab": "#tab-4"
    }[id];
    return jQuery(tabId);
  },

  highlightModifiedTabs: function() {
    var that = this;
    jQuery("#runCustomBuildDiv .modifiedParam").each(function() {
      that.getTabByElement(this).addClass("modifiedParam");
    });
  }
})));

BS.TagsEditingMixin.init(BS.RunBuildDialog);

BS.RunBuild = {
  progressMessage: 'Adding to queue...',
  lastRequestID: 0,

  _options: function(options) {
    var defOpts = {
      buildTypeId: null,
      redirectTo: '',
      redirectToQueuedBuild: false,
      branchName: null,
      afterTrigger: null,
      beforeTrigger: null,
      onError: null,
      onSuccess: null,
      modificationId: null,
      dependOnPromotionIds: null, // comma separated promotion ids
      isCustomRunDialogForRunButton : false,
      init : false,
      stateKey : '',
      initFromBuild : null, // id of a build from where settings should be loaded

      queryString: function() {
        var params = "";
        if (this.redirectTo != null) {
          params += "&redirectTo=" + encodeURIComponent(this.redirectTo);
        }
        if (this.modificationId != null) {
          params += "&modificationId=" + this.modificationId;
        }
        if (this.branchName != null) {
          params += "&branchName=" + encodeURIComponent(this.branchName);
          if (this.branchName != '<default>') {
            this.stateKey =  this.stateKey + '_' + encodeURIComponent(this.branchName); // maintain separate state for each branch
          }
        }
        if (this.dependOnPromotionIds != null) {
          params += "&dependOnPromotionIds=" + this.dependOnPromotionIds;
        }
        if (this.initFromBuild != null) {
          params += "&initFromBuild=" + this.initFromBuild;
        }
        if (this.isCustomRunDialogForRunButton) {
          params += "&customRunDialogForRunButton=true";
        }
        if (this.init) {
          params += "&init=true";
        }
        if (this.stateKey != '') {
          params += "&stateKey=" + this.stateKey;
        }
        return params;
      },

      afterShowDialog: function() {
        if (this.modificationId != null && this.modificationId > 0) {    // See TW-15946.
          BS.RunBuildDialog.showTab('changes-tab');
        } else {
          BS.RunBuildDialog.showTab('properties-tab');
        }
      }
    };

    return OO.extend(defOpts, options || {});
  },

  // TODO remove when https://youtrack.jetbrains.com/issue/TW-64812 is fixed
  fixItemId(itemId) {
    return itemId ? itemId.split(/:/g)[0] : null
  },

  createPromise: function() {
    const promise = new Promise(function (resolve, reject) {
      this._resolve = resolve;
      this._reject = reject;
    }.bind(this));
    this._promise = promise;
    return promise;
  },

  resolve: function(itemId) {
    if (this._resolve != null) {
      this._resolve(itemId);
    }
    if (BS.RunBuildDialog.onSuccess != null) {
      BS.RunBuildDialog.onSuccess(itemId);
    }
  },

  reject: function(error) {
    if (this._reject != null) {
      this._reject(error);
    }
    if (BS.RunBuildDialog.onError != null) {
      BS.RunBuildDialog.onError(error);
    }
  },

  runOnAgent: function(nearestElement, buildTypeExternalId, options) {
    var opts = this._options(options);

    BS.ProgressPopup.showProgress(nearestElement, this.progressMessage, {shift: {x: -65, y: 20}});
    BS.ajaxRequest(window['base_uri'] + "/ajax.html", {
      parameters: "add2Queue=" + buildTypeExternalId + "&validate=true" + opts.queryString(),
      onComplete: function(transport) {
        BS.RunBuild.onComplete(nearestElement, buildTypeExternalId, opts, transport);
      }
    });
    return this.createPromise();
  },

  runCustomBuild: function(buildTypeExternalId, options) {
    var opts = this._options(options);
    opts.afterShowDialog = options.afterShowDialog || function() {};
    return this._runCustomBuildImpl(buildTypeExternalId, opts);
  },

  onComplete: function(nearestElement, buildTypeExternalId, options, transport) {
    var showHtmlWarning = function(htmlMessage) {
      BS.WarningPopup.showWarning(nearestElement, {x: -250, y: 20}, '', {
        innerHTML: htmlMessage
      });
    };

    BS.ProgressPopup.hidePopup(0, true);
    if (BS.EventTracker) {
      BS.EventTracker.checkEvents();
    }
    var that = this;
    var errors = BS.XMLResponse.processErrors(transport.responseXML, {
        action_showRunCustomBuildDialog: function() {
          var newOptions = that._options(options);
          newOptions.isCustomRunDialogForRunButton = true;
          newOptions.afterShowDialog = that._options().afterShowDialog;
          newOptions.stateKey = newOptions.stateKey || 'prompt';
          newOptions.init = true;
          newOptions.preservePromise = true;
          BS.RunBuild._runCustomBuildImpl(buildTypeExternalId, newOptions);
        },
        onNo_agents_can_editError: function(elem) {
          var message = elem.firstChild.nodeValue.replaceAll(/\n/g, "<br>");
          var editRequirementsUrl = base_uri + "/admin/editRequirements.html?id=buildType:" + buildTypeExternalId;
          message = message.replace("tweak build configuration requirements.",
            "<a href='" + editRequirementsUrl + "'>tweak build configuration requirements</a>.");
          showHtmlWarning(message);
        },
        onNo_agentsError: function(elem) {
          var message = elem.firstChild.nodeValue.replaceAll(/\n/g, "<br>");
          message = message.replace("tweak build configuration requirements.",
            "ask admin to tweak build configuration requirements.");
          showHtmlWarning(message);
        }
      }, function(id, elem) {
        BS.WarningPopup.showWarning(nearestElement, {x: -250, y: 20}, elem.firstChild.nodeValue);
      }
    );

    var parentElement = transport.responseXML.documentElement;
    if (parentElement != null) {
      var buildsNodes = parentElement.getElementsByTagName("queuedBuilds");
      if (buildsNodes && buildsNodes.length > 0) {
        var buildNodes = buildsNodes.item(0).getElementsByTagName("queuedBuild");
        if (buildNodes && buildNodes.length == 1) {
          var itemId = BS.RunBuild.fixItemId(buildNodes.item(0).getAttribute("itemId"));
        }
      }
    }

    if (!errors) {
      this.resolve(itemId);
      if (options.redirectToQueuedBuild && itemId) {
          document.location.href = window['base_uri'] + "/viewQueued.html?itemId=" + itemId;
      } else if (options.redirectTo && options.redirectTo.length > 0) {
          document.location.href = options.redirectTo;
      } else if (options.afterTrigger) {
        options.afterTrigger();
      }
    }
  },

  _runCustomBuildImpl: function(buildTypeExternalId, opts) {
    var dialogBody = $j("#runBuild .modalDialogBody");
    var dlg = BS.RunBuildDialog;
    dlg.showProgress("Run Custom Build");

    dlg.redirectToQueued = opts.redirectToQueuedBuild || false;
    dlg.beforeTrigger = opts.beforeTrigger;
    dlg.onError = opts.onError;
    dlg.onSuccess = opts.onSuccess;

    var requestID = ++this.lastRequestID;
    BS.ajaxUpdater(dialogBody[0], dlg.getRefreshUrl(), {
      method: "get",
      evalScripts: true,
      parameters: "buildTypeId=" + buildTypeExternalId + opts.queryString(),
      onComplete: function() {
        if (requestID !== this.lastRequestID) {
          return;
        }
        dlg.showCentered();
        if ($(dlg.formId + '_availableTags')) {
          dlg.showTags($j('#comment-tab .tagsContainer').attr('id'), false, buildTypeExternalId);
        }
        dlg.show();
        opts.afterShowDialog();
      }.bind(this)
    });
    if (!opts.preservePromise) {
      this.createPromise();
    }
    return this._promise;
  },

  setTitleSuffix: function(suffix) {
    if (this.initialTitle === undefined) {
      this.initialTitle = $('runBuildTitle').textContent;
    }
    $('runBuildTitle').textContent = this.initialTitle + suffix;
  }
};

BS.PromoteBuildDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  getContainer: function() {
    return $('promoteBuildDialog');
  },

  formElement: function() {
    return $('promoteBuild');
  },

  resolve: function(payload) {
    if (this._resolve != null) {
      this._resolve(payload);
    }
    this.close();
  },

  showDialog: function(buildId, isNewUI) {
    $('promoteBuildDialogContent').innerHTML = '';

    this.showCentered();
    BS.Util.show('promoteBuildDialogContentProgress');
    BS.ajaxUpdater('promoteBuildDialogContent', window['base_uri'] + "/promoteBuildDialog.html", {
      method: "get",
      evalScripts: true,
      parameters: "buildId=" + buildId,
      onComplete: function() {
        BS.Util.hide('promoteBuildDialogContentProgress');
        BS.PromoteBuildDialog.recenterDialog();
      }
    });
    this.isNewUI = isNewUI;
    return new Promise(function(resolve, reject) {
      this._resolve = resolve;
      this._reject = reject;
    }.bind(this));
  }
}));
