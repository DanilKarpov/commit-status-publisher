BS.SaveConfigurationListener = OO.extend(BS.ErrorsAwareListener, {
  onSaveProjectErrorError: function(elem) {
    alert(elem.firstChild.nodeValue);
  },

  onProjectNotFoundError: function() {
    BS.reload(true);
  },

  onBuildTypeNotFoundError: function() {
    BS.reload(true);
  },

  onMaxNumberOfBuildTypesReachedError: function(elem) {
    alert(elem.firstChild.nodeValue);
  }
});

BS.DisablingTriggerDialog = OO.extend(BS.AbstractModalDialog, {

  options: {},

  getContainer: function () {
    return $('disablingTriggerFormDialog');
  },

  formElement: function () {
    return $('disablingTriggerForm');
  },

  show: function(options) {
    this.options = options;
    this.setTitle();
    this.setText();
    this.setButtonCaption();
    this.showCentered();
  },

  setTitle: function () {
    $j(this.getContainer()).find('.dialogTitle').text(this.options.title);
  },

  setText: function () {
    $j(this.getContainer()).find('.dialog_content').html(this.options.text);
  },

  setButtonCaption: function () {
    $j(this.getContainer()).find('#disableTriggerSubmit')[0].value = this.options.buttonCaption;
  },

  submitForm: function () {
    let removeQueued = this.formElement().removeQueued.checked;
    this.options.requestFunc(removeQueued);
    return false;
  }
});

BS.AdminActions = {
  url: window['base_uri'] + "/admin/action.html",

  _doDeleteAjaxRequest: function (requestParameters, errorHandlers) {
    BS.ajaxRequest(this.url, {
      parameters: requestParameters,
      onComplete: function (transport) {
        var errors = BS.XMLResponse.processErrors(transport.responseXML, errorHandlers);

        if (!errors) {
          BS.XMLResponse.processRedirect(transport.responseXML);
        }
      }
    });
  },

  _alertFirstChildValue: function (elem) { alert(elem.firstChild.nodeValue); },

  deleteBuildType: function (buildTypeId, buildTypeName, forceDelete, cameFromUrl) {
    if (!forceDelete && !confirm('Are you sure you want to delete "' + buildTypeName + '" build configuration and all related data?')) return false;

    this._doDeleteAjaxRequest("buildTypeId=" + buildTypeId + "&removeBuildType=1" + (forceDelete ? "&forceDelete=1" : "") +
                            (cameFromUrl ? "&cameFromUrl=" + encodeURIComponent(cameFromUrl) : ""), {
      onReferencesExistError: function (elem) {
        var confirmMessage = elem.firstChild.nodeValue + "\nAre you sure you want to delete \"" + buildTypeName + "\" build configuration?";
        if (confirm(confirmMessage)) {
          BS.AdminActions.deleteBuildType(buildTypeId, buildTypeName, true, cameFromUrl);
        }
      },
      onUndeletableReferencesExistError: this._alertFirstChildValue,
      onRunningBuildsExistError: this._alertFirstChildValue
    });

    return false;
  },

  deleteBuildTypeTemplate: function (buildTypeTemplateId, templateName) {
    BS.confirm('Are you sure you want to delete "' + templateName + '" template?', function () {
      this._doDeleteAjaxRequest("templateId=" + buildTypeTemplateId + "&removeTemplate=1", {
        cannotBeRemovedError: this._alertFirstChildValue
      });
    }.bind(this));

    return false;
  },

  deleteProject: function(projectExternalId, projectName, forceDelete) {
    var sanitizedProjectName = projectName.escapeHTML();
    var runDeleteOnServer = function() {
      this._doDeleteAjaxRequest("projectId=" + projectExternalId + "&removeProject=1" + (forceDelete ? "&forceDelete=1" : ""), {
        onProjectRemoveFailedError: this._alertFirstChildValue,

        onReferencesExistError: function(elem) {
          var confirmMessage = elem.firstChild.nodeValue + "\nAre you sure you want to delete \"" + sanitizedProjectName + "\" project?";
          if (confirm(confirmMessage)) {
            BS.AdminActions.deleteProject(projectExternalId, projectName, true);
          }
        },

        onUndeletableReferencesExistError: this._alertFirstChildValue,
        onRunningBuildsExistError: this._alertFirstChildValue
      });
    }.bind(this);

    if (forceDelete) {
      runDeleteOnServer();
    }
    else {

      var deleteWithConfirmation = function() {
        var hostnameConfirm;
        BS.confirmDialog.show({
          title: "Delete \"" + projectName + "\" Project",
          text: 'Are you sure you want to delete <strong>' + sanitizedProjectName + '</strong> project with subprojects and all related data (build history, artifacts, etc.)?' +
            '<div style="padding-top: 5px;">Please type <strong class="hostnamePlaceholder"></strong> to confirm.' +
            '  <input type="text" id="deleteProject__hostnameConfirmation" class="hostnameConfirmation" autocomplete="off">' +
            '</div>',

          actionButtonText: "Delete",
          action: runDeleteOnServer,
          onOpen: function(dialog) {
            dialog.disable();
            hostnameConfirm = BS.HostnameConfirm(
              $("deleteProject__hostnameConfirmation"),
              dialog.enable.bind(dialog));
          },
          onClose: function(dialog) {
            dialog.enable();
            hostnameConfirm.dispose();
          }
        });
      };

      BS.ajaxRequest(window.base_uri + "/app/rest/projects/id:" + projectExternalId, {
        method: "GET",
        parameters: "fields=buildTypes(count),projects(count),templates(count),vcsRoots(count),projectFeatures(count)",
        requestHeaders: {"Accept" : "application/json"},
        onComplete: function (response) {
          if (response.request.success()) {
            var json = response.responseJSON;
            var projectItemsCount = json.buildTypes.count + json.projects.count + json.templates.count + json.vcsRoots.count + json.projectFeatures.count;
            if (projectItemsCount > 0) {
              deleteWithConfirmation();
              return;
            }
            // no confirmation
            runDeleteOnServer();
          }
          else {
            // Some error obtaining project data? Ask for confirmation, just in case.
            deleteWithConfirmation();
          }
        }
      });
    }

    return false;
  },

  deleteVcsRoot: function(vcsRootId, vcsRootName, oncomplete) {
    BS.confirmDialog.show({
      title: "Delete VCS Root",
      text: 'Are you sure you want to delete "' + vcsRootName + '" VCS root?',
      actionButtonText: "Delete",
      action: function () {
        this._deleteVcsRoot(vcsRootId, oncomplete);
      }.bind(this)
    });
    
    return false;
  },

  _deleteVcsRoot: function(vcsRootId, oncomplete) {
    BS.Util.hideSuccessMessages();
    BS.Util.show('vcsRootProgress_' + vcsRootId);
    BS.ajaxRequest(this.url, {
      parameters: "removeVcsRoot=" + vcsRootId,
      onComplete: function(transport) {
        var errors = BS.XMLResponse.processErrors(transport.responseXML, {
          onReferencesExistError: function(elem) {
            alert(elem.firstChild.nodeValue);
          },
          onRemoveFailedError: function(elem) {
            alert(elem.firstChild.nodeValue);
          }
        });

        if (!errors) {
          if (oncomplete) {
            oncomplete();
          } else {
            BS.AdminActions._refreshAllRoots();
          }
        } else {
          BS.Util.hide('vcsRootProgress_' + vcsRootId);
        }
      }
    });

    return false;
  },

  detachVcsRoot: function(vcsRootId, settingsId, confirmMsg) {
    if (!confirm(confirmMsg ? confirmMsg : 'Are you sure you want to detach this VCS root?')) return;

    BS.Util.hideSuccessMessages();

    BS.ajaxRequest(this.url, {
      parameters: "detachVcsRoot=" + vcsRootId + "&settingsId=" + settingsId,
      onComplete: function() {
        BS.AdminActions._refreshVcsRoot(vcsRootId);
      }
    });
  },

  deleteBuildTrigger: function(triggerId, buildTypeExternalId, oncomplete) {
    if (!confirm('Are you sure you want to delete this trigger?')) return false;

    BS.Util.hideSuccessMessages();

    BS.ajaxRequest(this.url, {
      parameters: "removeBuildTrigger=" + triggerId + "&buildTypeExternalId=" + buildTypeExternalId,
      onComplete: function(transport) {
        var errors = BS.XMLResponse.processErrors(transport.responseXML, {
          onBuildTypeNotFoundError: function(elem) {
            alert(elem.firstChild.nodeValue);
          },

          onTriggerNotFoundError: function(elem) {
            alert(elem.firstChild.nodeValue);
          }
        });

        if (!errors) {
          oncomplete && oncomplete();
        }
      }
    });

    return false;
  },

  deleteUsers: function(userIds, oncomplete) {
    var userIdsParam = "";
    for (var i=0; i<userIds.length; i++) {
      userIdsParam += userIds[i] + ":";
    }
    BS.ajaxRequest(this.url, {
      parameters: "removeUsers=" + userIdsParam,
      onComplete: function() {
        if (oncomplete) {
          oncomplete();
        }
      }
    });

    return false;
  },

  toggleVcsRootUsages: function(link, vcsRootId) {
    $j('#' + vcsRootId + '_usages').toggle();
    var parent = $j(link).parent().toggleClass("usageHl");
    parent.parent().find(".vcsRoot").toggleClass("bold");
    return false;
  },

  _refreshVcsRoot: function(vcsRootId) {
    $('vcsRootContainer_' + vcsRootId).refresh('vcsRootProgress_' + vcsRootId);
  },

  _refreshAllRoots: function() {
    BS.reload(true);
  },

  deleteIssueProvider: function(providerId, projectExternalId) {
    if (!confirm('Are you sure you want to remove an issue tracker connection?')) return;

    BS.Util.hideSuccessMessages();

    BS.ajaxRequest(this.url, {
      parameters: "deleteIssueProvider=1&providerId=" + providerId + "&projectId=" + projectExternalId,
      onComplete: function() {
        BS.reload(true);
      }
    });
  },

  setParametersDescriptorEnabled: function(settingsId, descriptorId, enabled, descriptorName, oncomplete) {
    let url = this.url;
    var request = function (removeQueued) {
      BS.ajaxRequest(url, {
        parameters: "id=" + settingsId + "&setEnabled=" + descriptorId + "&enabled=" + enabled + "&descriptorName=" + descriptorName + "&removeQueued=" + removeQueued,
        onSuccess: function () {
          if (oncomplete) {
            oncomplete();
          } else {
            BS.reload(true);
          }
        }
      });
    };
    var isTriggerRequest = 'Trigger' === descriptorName;
    if (!enabled && isTriggerRequest) {
      BS.DisablingTriggerDialog.show({
        requestFunc: request,
        title: 'Disable Trigger',
        text: 'Are you sure you want to disable this trigger?',
        buttonCaption: 'Disable'
      });
    } else {
      request(false)
    }
  },

  setHealthItemVisibility: function(type, categoryId, itemId, visible, applyGlobally, oncomplete) {
    var url = this.url;
    var changeVisibilityFun = function () {
      BS.ajaxRequest(url, {
        parameters: "setVisible=" + visible + "&type=" + type + "&categoryId=" + categoryId + "&itemId=" + itemId + (applyGlobally ? "&applyGlobally=true" : ""),
        onComplete: function() {
          if (oncomplete) {
            oncomplete();
          }
        }
      });
    };

    if (!visible && applyGlobally) {
      BS.confirmDialog.show({
                              text: "Are you sure you want to hide this item for all users? It is possible to restore the visibility later under 'Administration > Server Health'.",
                              actionButtonText: "Hide",
                              cancelButtonText: 'Cancel',
                              title: "Hide Server Health item",
                              cancelAction: function(event) {
                                if (event) {
                                  event.stopPropagation();
                                  event.preventDefault();
                                }
                              },
                              action: changeVisibilityFun
      });
    } else {
      changeVisibilityFun();
    }

    return false;
  },

  hideHealthItemFromPopup: function(id, popupId) {
    var item = document.getElementById(id)
    item && (item.hidden = true);
    var popup = document.getElementById(popupId)
    if (popup && popup.querySelectorAll('.inplaceHealthStatusItem:not([hidden])').length === 0) {
      BS.Hider.hideDiv(popupId);
    }
    var button = document.querySelector('[id^="container_hi_"]');
    button && button.refresh();
  },

  regenerateAllIds: function(projectId) {
    BS.RegenerateForm.showDialog(projectId);
    return false;
  },

  // params: "buildTypeId=<id>", "templateId=<id>", "projectId=<id>"
  checkCanMove: function(targetProjectId, params, oncomplete) {
    BS.ajaxRequest(this.url, {
      parameters: "checkCanMove=true&targetId=" + targetProjectId + "&" + params,
      onComplete: function(transport) {
        var xml = transport.responseXML;

        var rootNames = [];
        var templateNames = [];
        var clashingCleanupRules = {
          clashingCleanupDisableRules: 0,
          clashingOverriddenRules: 0
        };
        var otherReasons = [];

        if (xml) {
          var vcsRootElems = xml.getElementsByTagName("vcsRoot");
          var templateElems = xml.getElementsByTagName("template");
          var clashingDisableRules = xml.getElementsByTagName("clashingDisableRules");
          var clashingOverriddenRules = xml.getElementsByTagName("clashingOverriddenRules");
          var reasons = xml.getElementsByTagName("reason");

          for (var i = 0; i < vcsRootElems.length; i ++) {
            var e = vcsRootElems[i];
            rootNames.push(e.getAttribute("name"));
          }

          for (i = 0; i < templateElems.length; i ++) {
            e = templateElems[i];
            templateNames.push(e.getAttribute("name"));
          }

          for (i = 0; i < clashingDisableRules.length; i ++) {
            e = clashingDisableRules[i];
            clashingCleanupRules.clashingCleanupDisableRules = e.getAttribute("total");
          }

          for (i = 0; i < clashingOverriddenRules.length; i ++) {
            e = clashingOverriddenRules[i];
            clashingCleanupRules.clashingOverriddenRules = e.getAttribute("total");
          }

          for (i = 0; i < reasons.length; i ++) {
            e = reasons[i];
            otherReasons.push(e.firstChild.nodeValue);
          }
        }

        if (oncomplete) {
          oncomplete(rootNames, templateNames, clashingCleanupRules, otherReasons);
        }
      }
    });
    return false;
  },

  listBranches: function(buildTypeId, oncomplete) {
    var internalId = buildTypeId.indexOf('internal:') == 0;

    BS.ajaxRequest(this.url, {
      parameters: "listBranches=true&" + (internalId ? "internalBuildTypeId=" + buildTypeId.substring('internal:'.length) : "buildTypeId=" + buildTypeId),
      onComplete: function(transport) {
        var xml = transport.responseXML;
        if (xml) {
          var branches = [];
          var nameElems = xml.getElementsByTagName("branch");
          for (var i = 0; i < nameElems.length; i ++) {
            var e = nameElems[i];
            branches.push({
              name: e.getAttribute('name'),
              is_default: "true" == e.getAttribute('is_default')
            });
          }

          if (oncomplete) {
            oncomplete(branches);
          }
        }
      }
    });
  },

  prepareProjectIdGenerator: function(idInput, nameInput, parentInput, editMode, warning) {
    this._doPrepare("project", idInput, nameInput, parentInput, editMode, warning);
  },

  prepareBuildTypeIdGenerator: function(idInput, nameInput, parentInput, editMode, warning) {
    this._doPrepare("buildType", idInput, nameInput, parentInput, editMode, warning);
  },

  prepareTemplateIdGenerator: function(idInput, nameInput, parentInput, editMode, warning) {
    this._doPrepare("template", idInput, nameInput, parentInput, editMode, warning);
  },

  prepareVcsRootIdGenerator: function(idInput, nameInput, parentInput, editMode, warning) {
    this._doPrepare("vcsRoot", idInput, nameInput, parentInput, editMode, warning);
  },

  prepareCustomIdGenerator: function(objectType, idInput, nameInput, parentInput, editMode, warning) {
    this._doPrepare(objectType, idInput, nameInput, parentInput, editMode, warning);
  },

  _doPrepare: function(obj, idInput, nameInput, parentInput, editMode, warning) {
    var that = this;
    idInput = $(idInput);
    if (!idInput) return;

    if (!editMode) {    // create mode (default)
      idInput.setAttribute("generated", idInput.value); // to support case when field already has some value
      that._prepareIdGenerator(obj, idInput, nameInput, parentInput);
    } else {
      that._prepareEdit(idInput, warning);
      that._createRegenerateLink(obj, idInput, nameInput, parentInput);
    }
  },

  _prepareEdit: function(idInput, warning) {
    warning = $(warning || "changeExternalIdWarning");
    warning = $j(warning || "");

    var originalValue = idInput.value;
    $j(idInput).on("keyup change", function() {
      if (this.value != originalValue) {
        warning.show();
      } else {
        warning.hide();
      }
    }).attr("originalId", originalValue);
  },

  _createRegenerateLink: function(obj, idInput, nameInput, parentInput) {
    var that = this,
        input = $j(idInput);

    $j("<a>", {
      href: "#",
      "class": "regenerate",
      title: "Regenerate the ID based on the current name and parent projects' names",
      click: function() {
        // Do not consider the original external ID for generation. It is possible that ID won't change.
        var currentValue = input.attr("originalId");
        that._prepareIdGenerator(obj, idInput, nameInput, parentInput, currentValue, true, function() {
          input.trigger("keyup").focus();
        });
        return false;
      },
      html: "Regenerate ID",
      insertAfter: input
    });
  },

  _prepareIdGenerator: function(obj, idInput, nameInput, parentInput, currentId, invokeGeneratorOnly, callback) {
    var requestId = 0,
        lastProcessedRequestId = 0;
    nameInput = $(nameInput);

    function isElement(obj) {
      try {
        // Using W3 DOM2 (works for FF, Opera and Chrome).
        return obj instanceof HTMLElement;
      } catch (e) {
        // Browsers not supporting W3 DOM2 don't have HTMLElement and
        // an exception is thrown and we end up here. Testing some
        // properties that all elements have. (works on IE7)
        return (typeof obj=== "object") &&
               (obj.nodeType === 1) && (typeof obj.style === "object") &&
               (typeof obj.ownerDocument === "object");
      }
    }

    function updateIfNeeded() {
      var currentValue = idInput.value,
          currentGenerated = idInput.getAttribute("generated"),
          nameValue = nameInput.value;

      if (!invokeGeneratorOnly) {
        // If nameValue is cleared, start again.
        if (currentValue && currentValue != currentGenerated) {
          return;
        }
      }

      function doSet(newValue) {
        // removed `currentValue == idInput.value` check because it is incorrect in case of
        // of receiving late response when more recent request have been already processed
        idInput.value = newValue;
        idInput.setAttribute("generated", newValue);
        $j(idInput).trigger("keyup");
      }

      if (nameValue) {
        (function (ownId) {
          var parentId = isElement(parentInput) ? parentInput.value : parentInput;
          BS.ajaxRequest(window["base_uri"] + "/generateId.html", {
            parameters: { object: obj, parentId: parentId, name: nameValue, currentId: currentId },
            onComplete: function(xhr) {
                if (ownId >= lastProcessedRequestId) {
                  lastProcessedRequestId = ownId;
                  doSet(xhr.responseText);
                  callback && callback();
                }
            }
          });
        })(requestId++);
      } else if (currentValue == currentGenerated) {
        doSet("");
      }
    }

    if (!invokeGeneratorOnly) {
      $j(nameInput).on("keyup", updateIfNeeded);
      if (isElement(parentInput)) {
        $j(parentInput).on("change", updateIfNeeded);
      }
    }

    // For the case if there also is a value.
    updateIfNeeded();
  },

  prepareSubstitutor: function(idInput, initialValue, textarea, inputEntries, toggleSubmission) {
    idInput = $(idInput);
    textarea = $(textarea);
    if (!idInput || !textarea) return;

    var that = this;
    that._setParsedData(idInput, initialValue, inputEntries, {});
    that._fillTextarea(idInput, textarea, null);

    $j(idInput).on("keyup", function() {
      that.regenerateAll(initialValue, textarea, idInput, true, toggleSubmission);
    });
  },

  _setParsedData: function(idInput, initialValue, inputEntries) {
    var parsedData = [],
        set_for_clash_check = {};
    this._parsedData = parsedData;
    parsedData.clash = false;

    _.each(inputEntries, function(entry) {
      if (!entry || !entry.length) return;

      var key = entry[0],
          id = entry[1],
          indent = entry[2];

      parsedData.push([key, id, indent]);

      if (set_for_clash_check[id]) {    // a clash between project/build type ids (should be a rare case).
        parsedData.clash = true;
      }
      set_for_clash_check[id] = true;
    });
  },

  // Possible speed-up is cache result in textarea.
  _parseTextarea: function(textarea) {
    var result = {},
        lines = textarea.value.split(/\n/);
    _.each(lines, function(line) {
      if (line && line[0] != "#") {
        var idx = line.indexOf("=>");
        if (idx >= 0) {
          var left = $j.trim(line.substr(0, idx)),
              right = $j.trim(line.substr(idx + 2));
          if (left.include(":")) left = left.replace(/:\s+/, ":");
          result[left] = right;
        }
      }
    });
    return result;
  },

  _fillTextarea: function(idInput, textarea, lines) {
    if (!lines) {
      this._prevFilled = {};
    }
    var previous = this._prevFilled,
        parsedData = this._parsedData;

    var visibleLines = [];
    _.each(parsedData, function(data) {
      var key = data[0],
          left = data[1],
          indent = data[2],
          right;

      var prevKey = key + ":" + left;
      var linesKey = parsedData.clash ? key + ":" + left : left;
      if (lines && previous[prevKey] != lines[linesKey]) {
        right = lines[linesKey];
      } else {
        right = left;
        previous[prevKey] = right;
      }

      visibleLines.push(indentString(indent) + (parsedData.clash ? key + ": " : "") + left + " => " + right);
    });
    textarea.value = visibleLines.join("\n");
  },

  createHiddenMappingIfNecessary: function(container) {
    container = $j(container);
    var textarea = $j("textarea", container);
    var parsedData = this._parsedData;

    if (!parsedData || parsedData.clash) {
      textarea.attr("name", "mapping");
      return;
    }

    var lines = this._parseTextarea(textarea[0]);
    var hiddenLines = [];
    _.each(parsedData, function(data) {
      var key = data[0],
          left = data[1],
          right = lines[left];
      if (right) {
        hiddenLines.push(key + ": " + left + " => " + right);
      }
    });

    $j("<input>", {
      type: "hidden",
      name: "mapping",
      value: hiddenLines.join("\n"),
      insertAfter: container
    });
  },

  regenerateAll: function(projectId, textarea, idInput, doNotOverwriteUserInput, toggleSubmission) {

    if (toggleSubmission)
      toggleSubmission(false);

    var previous = this._prevFilled,
        parsedData = this._parsedData;

    textarea = $(textarea);

    var userModifiedKeys = {};
    if (doNotOverwriteUserInput) {
      var linesBeforeRequest = this._parseTextarea(textarea);
      _.each(parsedData, function(data) {
        var key = data[0],
            left = data[1];

        var prevKey = key + ":" + left;
        var linesKey = parsedData.clash ? key + ":" + left : left;
        if (linesBeforeRequest && previous[prevKey] != linesBeforeRequest[linesKey]) {
          userModifiedKeys[linesKey] = true;
        }
      });
    }

    BS.ajaxRequest(window["base_uri"] + "/admin/regenerate.html", {
      method: "GET",
      parameters: { projectId: projectId, returnDefaults: "true", currentId: $(idInput).value, forCopy: doNotOverwriteUserInput },
      onComplete: function(xhr) {
        var json = JSON.parse(xhr.responseText),
            projects = json.project,
            vcsRoots = json.vcsRoot,
            buildTypes = json.buildType;

        if (json.error) {
          $j("#error_newProjectExternalId").html(json.error.escapeHTML());
          return;
        } else {
          $j("#error_newProjectExternalId").html("");
        }

        function determineRight(left) {
          if (userModifiedKeys[left.trim()]) {
            return null;
          }

          if (parsedData.clash) {
            var colon = left.indexOf(":"),
                obj = left.substr(0, colon).trim(),
                id = left.substr(colon + 1).trim();

            if (obj == "project") {
              return projects[id];
            }
            else if (obj == "vcsRoot") {
              return vcsRoots[id];
            }
            else {
              return buildTypes[id];
            }
          } else {
            id = left.trim();
            return projects[id] || buildTypes[id] || vcsRoots[id];
          }
        }

        var result = [];

        if (doNotOverwriteUserInput) {
          var lines = textarea.value.split(/\n/);
          _.each(lines, function(line) {
            var left, right;

            if (line && line[0] != "#") {
              var idx = line.indexOf("=>");
              if (idx >= 0) {
                left = line.substr(0, idx);
              }
            }

            if (left) {
              right = determineRight(left);
            }

            if (right) {
              result.push(left + "=> " + right);
            } else {
              result.push(line);
            }
          });
        } else {
          _.each(parsedData, function(data) {
            var key = data[0],
                left = data[1],
                indent = data[2],
                right = (key == "project") ? projects[left] : (key == "vcsRoot") ? vcsRoots[left] : buildTypes[left];

            result.push(indentString(indent) + (parsedData.clash ? key + ": " : "") + left + " => " + right);
          });
        }

        textarea.value = result.join("\n");

        _.each(parsedData, function(data) {
          var key = data[0],
              id = data[1];
          var newValue;
          if (data[0] == "project") {
            newValue = projects[id];
          } else if (data[0] == "vcsRoot") {
            newValue = vcsRoots[id];
          } else {
            newValue = buildTypes[id];
          }

          previous[key + ":" + id] = newValue;
        });
        if (toggleSubmission)
          toggleSubmission(true);
      }
    });
    return false;
  },

  showOrHideActions: function(selector, dock) {
    var checkboxes = $j(selector);
    checkboxes.change(function() {
      setTimeout(function() {
        if (checkboxes.filter(":checked").length > 0) {
          $j(dock).show();
        } else {
          $j(dock).hide();
        }
      }, 100);
    });
  },

  setProjectEditable: function(projectId, editable) {
    if (!editable) {
      if (!confirm("This will disable editing of the project and subprojects settings via the web interface. Are you sure?")) {
        return false;
      }
    }

    BS.ajaxRequest(window["base_uri"] + "/admin/action.html", {
      parameters: { projectId: projectId, editable: editable },
      onComplete: function() {
        BS.reload(true);
      }
    });

    return false;
  },

  setBuildTypeEditable: function(buildTypeId, editable) {
    if (!editable) {
      if (!confirm("This will disable editing of the configuration settings via the web interface. Are you sure?")) {
        return false;
      }
    }

    BS.ajaxRequest(window["base_uri"] + "/admin/action.html", {
      parameters: { buildTypeId: buildTypeId, editable: editable },
      onComplete: function() {
        BS.reload(true);
      }
    });

    return false;
  },

  setTemplateEditable: function(templateId, editable) {
    if (!editable) {
      if (!confirm("This will disable editing of the configuration template settings via the web interface. Are you sure?")) {
        return false;
      }
    }

    BS.ajaxRequest(window["base_uri"] + "/admin/action.html", {
      parameters: { templateId: templateId, editable: editable },
      onComplete: function() {
        BS.reload(true);
      }
    });

    return false;
  }
};

// Util function.
function indentString(indent) {
  return (new Array((parseInt(indent, 10) || 0) + 1)).join('  ');
}


BS.AttachBuildTypeForm = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  setSaving: function(saving) {
    if (saving) {
      BS.Util.show('attachBuildTypeProgress');
    } else {
      BS.Util.hide('attachBuildTypeProgress');
    }
  },

  getContainer: function() {
    return $('attachBuildTypeFormDialog');
  },

  formElement: function() {
    return $('attachBuildTypeForm');
  },

  showDialog: function(vcsRootId) {
    this.formElement().vcsRootId.value = vcsRootId;
    this.showCentered();
    this.bindCtrlEnterHandler(this.submit.bind(this));
    $('chooseBuildTypeSelector').fill(vcsRootId);
    BS.jQueryDropdown($('chooseBuildTypeSelector')).ufd("changeOptions");
  },

  submit: function() {
    var idx = this.formElement().buildTypeId.selectedIndex;
    var buildTypeId = this.formElement().buildTypeId.options[idx].value;
    var vcsRootId = this.formElement().vcsRootId.value;
    this.setSaving(true);

    BS.Util.hideSuccessMessages();

    BS.ajaxRequest(BS.AdminActions.url, {
      parameters: "attachVcsRoot=" + vcsRootId + "&buildTypeId=" + buildTypeId,
      onComplete: function() {
        BS.AdminActions._refreshVcsRoot(vcsRootId);
        BS.AttachBuildTypeForm.setSaving(false);
        BS.AttachBuildTypeForm.close();
      }
    });

    return false;
  }
}));

BS.BaseAssignRoleDialog = OO.extend(BS.AbstractModalDialog, {
  getFormElement: function() {},

  getTitle: function() {},

  show: function(rolesHolderIds, oncompletefunction) {
    this.showCentered();
    this.bindCtrlEnterHandler(this.save.bind(this));
    this.getFormElement().role.onchange();
    this._rolesHolderIds = rolesHolderIds;
    this._oncompletefunction = oncompletefunction;

    $(this.getFormElement().id + 'Title').innerHTML = this.getTitle();
  },

  _clearAll: function() {
    var form = this.getFormElement();
    var selector = $j(form.projectId);
    var $input = $j(form).find(".inplaceFilterDiv").find("input");
    selector.children().remove();
    this._prevValue = $input.val();
    $input.val("");
  },

  save: function() {
    BS.Util.hideSuccessMessages();

    if ($j(this.getFormElement).find(".projectsRow").is(":visible")) {
      var selected = false;
      var options = this.getFormElement().projectId.options;
      for (var i=0; i<options.length; i++) {
        if (options[i].selected) {
          selected = true;
        }
      }

      if (!selected) {
        alert("Please select at least one project.");
        return false;
      }
    }

    if (this.getFormElement().replaceRoles &&
        this.getFormElement().replaceRoles.checked &&
        !confirm("Are you sure you want to completely replace all of the current roles with newly selected roles?")) return false;

    Form.disable(this.getFormElement());
    BS.Util.show('savingRole');

    var additionalParams = "";
    for (i=0; i<this._rolesHolderIds.length; i++) {
      additionalParams += "&rolesHolderId=" + this._rolesHolderIds[i];
    }

    var that = this;
    BS.ajaxRequest(this.getFormElement().action, {
      parameters: BS.Util.serializeForm(this.getFormElement()) + additionalParams,

      onComplete: function() {
        BS.Util.hide(that.getFormElement().id + '_savingRole');
        that._oncompletefunction();
        Form.enable(that.getFormElement());
        that.close();
      }
    });

    return false;
  },

  _roles: {},
  _projects: [],

  clearAll: function() {
    this._roles = {};
    this._projects = [];
  },

  addProject: function(id, externalId, name, fullName, level) {
    this._projects.push({
      id: id,
      externalId: externalId,
      name: name,
      fullName: fullName,
      level: level
    });
  },

  addRole: function(id, name, isProjectBased) {
    this._roles[id] = {
      name: name,
      isProjectBased: isProjectBased,
      visibleProjects: {},
      disabledProjects: {}
    };
  },

  isProjectBased: function(roleId) {
    return this._roles[roleId].isProjectBased;
  },

  setVisible: function(roleId, projectId) {
    this._roles[roleId].visibleProjects[projectId] = true;
  },

  setVisibleDisabled: function(roleId, projectId) {
    this.setVisible(roleId, projectId);
    this._roles[roleId].disabledProjects[projectId] = true;
  },

  isVisible: function(roleId, projectId) {
    var role = this._roles[roleId];
    return role.visibleProjects[projectId];
  },

  isDisabled: function(roleId, projectId) {
    return this._roles[roleId].disabledProjects[projectId];
  },

  roleChanged: function() {
    var selector = this.getFormElement().role;
    var idx = selector.selectedIndex;
    var roleId = selector.options[idx].value;
    this.loadProjects(roleId, this.isProjectBased(roleId));

    $(this.getFormElement().id + '_roleName').innerText = selector.options[idx].text;
  },

  loadProjects: function(roleId, projectBasedRole) {
    var selected = {};
    var selector = this.getFormElement().projectId;
    var $form = $j(this.getFormElement());
    while (selector.options.length > 0) {
      var wasSelected = selector.options[0].selected;
      if (wasSelected) {
        selected[selector.options[0].value] = true;
      }
      selector.options[0] = null;
    }

    if (roleId == "SYSTEM_ADMIN") {
      $form.find(".globalText").html("<b>&lt;Root&gt;</b> project");
    } else {
      $form.find(".globalText").html("Global (cannot be associated with any project)");
    }

    if (!projectBasedRole) {
      $form.find(".globalScopeRow").show();
      $form.find(".projectsRow").hide();
      $form.find(".roleScopeInput").val("global");
      return;
    } else {
      $form.find(".globalScopeRow").hide();
      $form.find(".projectsRow").show();
      $form.find(".roleScopeInput").val("perProject");
    }

    this._clearAll();
    var projects = this._projects;

    var _newSelectorDF = document.createDocumentFragment();
    var includedProjects = [];
    var disabledProjects = [];
    for (var i=0; i<projects.length; i++) {
      var project = projects[i];
      if (!this.isVisible(roleId, project.id)) {
        continue;
      }

      var option = new Option(project.name, project.externalId, false, selected[project.externalId]);
      option.setAttribute("data-filter-data", project.level);
      option.setAttribute("data-title", project.fullName);
      option.setAttribute("title", project.fullName);
      option.className = 'inplaceFiltered';
      if (this.isDisabled(roleId, project.id)) {
        option.disabled = "disabled";
        disabledProjects.push(project.externalId);
      }
      _newSelectorDF.appendChild(option);
      includedProjects.push(project.externalId);
    }
    selector.appendChild(_newSelectorDF);
    _newSelectorDF = null;

    ReactUI.renderConnected(this.getFormElement().querySelector('.projectIdSelect'), ReactUI.ProjectBuildTypeSelect, {
      containerClassName: 'userRoleScopeSelect',
      multiselect: true,
      propagateCheck: false,
      expandAll: true,
      projectsSelectable: true,
      buildTypesSelectable: false,
      includedProjects,
      includeRoot: includedProjects.includes('_Root'),
      disabledProjects,
      checked: Object.keys(selected).map(id => ({id, nodeType: 'project'})),
      onCheck(items) {
        selector.value = null;
        items.forEach(item => {
          selector.querySelector(`option[value="${item.id}"]`).selected = true;
        })
      }
    });
  },

  showRolesDescription: function() {
    var roleSelector = this.getFormElement().role;
    var selectedId = roleSelector.options[roleSelector.selectedIndex].value;
    var url = window['base_uri'] + '/rolesDescription.html?';
    for (var i=0; i<roleSelector.options.length; i++) {
      url += 'role=' + roleSelector.options[i].value + '&';
    }
    url += '#' + selectedId;
    BS.Util.popupWindow(url, "_blank", {width: 550, height: 600});
  }
});

BS.AssignRoleDialog = OO.extend(BS.BaseAssignRoleDialog, {
  getContainer: function() {
    return $('assignRoleDialog');
  },

  getFormElement: function() {
    return $('assignRole');
  },

  getProgressIndicator: function() {
    return $('assignRole_saving');
  },

  getTitle: function() {
    if (this._rolesHolderIds.length > 1) {
      return "Assign roles to " + this._rolesHolderIds.length + " users";
    }
    return "Assign roles";
  },

  show: function (rolesHolderIds, oncompletefunction) {
    BS.BaseAssignRoleDialog.show.call(this, rolesHolderIds, oncompletefunction);
    this.expandMultiSelect();
  },

  roleChanged: function () {
    BS.BaseAssignRoleDialog.roleChanged.call(this);
    this.expandMultiSelect();
  },

  expandMultiSelect: function () {
    parseInt($j('#assignRole_projectId').attr('size'), 10) > 0 || BS.expandMultiSelect($j('#assignRole_projectId'));
  }
});

BS.UnassignRoleDialog = OO.extend(BS.BaseAssignRoleDialog, {
  getContainer: function() {
    return $('unassignRoleDialog');
  },

  getFormElement: function() {
    return $('unassignRole');
  },

  getProgressIndicator: function() {
    return $('unassignRole_saving');
  },

  getTitle: function() {
    if (this._rolesHolderIds.length > 1) {
      return "Unassign roles from " + this._rolesHolderIds.length + " users";
    }
    return "Unassign roles";
  }
});

BS.UnassignRolesForm = OO.extend(BS.AbstractWebForm, {
  getFormElement: function() {
    return $('unassignRolesForm');
  },

  selectAll: function(select) {
    if (select) {
      BS.Util.selectAll(this.getFormElement(), "unassign");
    } else {
      BS.Util.unselectAll(this.getFormElement(), "unassign");
    }
  },

  selected: function() {
    var checkboxes = Form.getInputs(this.getFormElement(), "checkbox", "unassign");
    for (var i=0; i<checkboxes.length; i++) {
      if (checkboxes[i].checked) {
        return true;
      }
    }

    return false;
  },

  setSaving: function(saving) {
    if (saving) {
      BS.Util.show('unassignInProgress');
    } else {
      BS.Util.hide('unassignInProgress');
    }
  },

  submit: function() {
    if (!this.selected()) {
      alert("Please select at least one role.");
      return false;
    }

    BS.confirm("Are you sure you want to unassign selected roles?", function () {
      BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
        onCompleteSave: function () {
          $('authorityRolesContainer').refresh();
        }
      }));
    }.bind(this));

    return false;
  }
});

BS.AvailableParams = {
  url: window['base_uri'] + "/admin/parameterAutocompletion.html",

  attachPopups: function(editableObjId, classNames) {
    var classes = [],
        i;

    for (i = 1; i < arguments.length; i++) {
      classes.push(arguments[i]);
    }
    if ($j.inArray('buildTypeParams', classes) === -1) {
      classes.push('buildTypeParams');
    }

    $j(document).ready(function() {
      $j(classes).each(function(index, className) {
        var selector = '.' + className + ':not(.disableBuildTypeParams):not([type=password])';
        BS.AvailableParams.attachPopupsTo(editableObjId, selector);
      });
    });
  },

  buildSourceUrl: function (editableObjId) {
    return editableObjId && this.url + '?' + editableObjId;
  },

  /**
   * Updates element's autocompletion request parameters,
   * requires element to have `js_dynamicSource` class
   *
   * @param {String|jQuery|DomElement} element - selector or (jquery) element
   * @param {String} editableObjectId - request parameters string, as in `attachPopups`
   */
  setElementCompletionObjId: function(element, editableObjectId) {
    var elem = $j(element);
    if (!elem.hasClass('js_dynamicSource')) {
      BS.Log.warn('The element has no js_dynamicSource class required to update completion parameters');
    }
    $j(element).data('editableObjId', editableObjectId);
  },

  autocompleteCM: function(inputField, from, skipFirstChar) {
    BS.AvailableParams.initAutocomplete(inputField.get(0));
    var dynamic = inputField.hasClass('js_dynamicSource');
    var cm = inputField.data('cm');
    var autocompleteUrl = BS.AvailableParams.buildSourceUrl(inputField.data('editableObjId')) || this.url;
    var hint = function(_, callback) {
      if (dynamic) {
        autocompleteUrl = BS.AvailableParams.buildSourceUrl(inputField.data('editableObjId')) || autocompleteUrl;
      }

      var cursor = cm.getCursor();
      var term = cm.getRange(from, cursor);
      if (skipFirstChar) {
        term = term.slice(1);
      }

      if (term.indexOf('%') >= 0) {
        callback({
          list: [],
          from: from,
          to: cursor
        });
        return;
      }

      if (term) {
        var urlObject = new URL(autocompleteUrl);
        urlObject.searchParams.set('term', term);
        autocompleteUrl = urlObject.toString();
      }

      return $j.getJSON(autocompleteUrl).then(function (items) {
        var list = [];
        var separator = null;
        items.forEach(function (item) {
          if (!item.selectable) {
            separator = item;
            return;
          }
          var prevSeparator = separator;
          separator = null;
          var span = document.createElement('span');
          span.innerHTML = item.label;
          list.push({
            text: '%' + span.textContent + '%',
            render: function (element) {
              element.innerHTML =
                (prevSeparator
                 ? '<div class="codemirror-autocomplete-separator">' + prevSeparator.label + '</div>'
                 : '') +
                '<div class="codemirror-autocomplete-item">' +
                item.label +
                '<span class="ui-autocomplete-meta-info">' + item.meta + '</span>' +
                '</div>';
            }
          });
        });
        if (list.length === 0) {
          list = [{
            text: cm.getRange(from, cursor),
            displayText: 'No suggestions found',
            className: 'codemirror-autocomplete-nothing'
          }];
        }
        callback({
          list: list,
          from: from,
          to: cursor
        });
      });
    };

    hint.async = true;

    cm.showHint({
      hint: hint,
      completeOnSingleClick: true,
      completeSingle:  false
    });
  },

  /**
   * @param {DOMNode} inputField
   */
  initAutocomplete: function(inputField) {
    if (inputField._autocompleteInited) {
      return;
    }
    inputField._autocompleteInited = true;

    inputField = $j(inputField);
    var dynamic = inputField.hasClass('js_dynamicSource');
    var cm = inputField.data('cm');
    if (cm) {
      cm.on('changes', function() {
        if (inputField.data('autoCompletingPercent')) {
          return;
        }
        var cursor =  cm.getCursor();
        var beforeText = cm.getRange({line: cursor.line, ch: 0}, cursor);
        var termStart = BS.AvailableParams.getTermStart(beforeText, beforeText.length);
        if (termStart != null) {
          BS.AvailableParams.autocompleteCM(inputField, {line: cursor.line, ch: termStart}, true);
          inputField.data('autoCompletingPercent', true);
          cm.on('endCompletion', function() {
            inputField.data('autoCompletingPercent', false);
          });
        }
      });

      cm.addKeyMap({
        'Ctrl-Space': function() {
          var cursor =  cm.getCursor();
          var beforeText = cm.getRange({line: cursor.line, ch: 0}, cursor);
          var match = beforeText.match(/\S*$/);
          var term = match ? match[0] : '';
          BS.AvailableParams.autocompleteCM(inputField, {line: cursor.line, ch: cursor.ch - term.length});
        }
      });
    } else {
      var editableObjId = inputField.data('editableObjId');
      inputField.autocomplete({
        minLength: 0,
        insertItemWithFocus: false,
        source: BS.AvailableParams.sourceForElement(inputField, BS.AvailableParams.buildSourceUrl(editableObjId) || url, dynamic),
        select: BS.AvailableParams.selectForElement(inputField),
        more: BS.AvailableParams.moreForElement(inputField, BS.AvailableParams.buildSourceUrl(editableObjId) || url, dynamic),
        completeOnCtrlSpace: true
      });
    }
  },

  initAutocompleteOnCMFocus: function(inputField) {
    var cm = $j(inputField).data('cm');
    if (cm) {
      if (cm.hasFocus()) {
        BS.AvailableParams.initAutocomplete(inputField);
      } else {
        cm.on('focus', function () {
          BS.AvailableParams.initAutocomplete(inputField);
        });
      }
    }
  },

  attachPopupsTo: function(editableObjId, jQuerySelector) {
    var inputFields = $j(jQuerySelector);
    inputFields.data('editableObjId', editableObjId);

    inputFields.each(function() {
      var parentClass = this.parentNode.className;
      if (parentClass.indexOf('completionIconWrapper') == -1 && parentClass.indexOf('posRel') == -1) {
        var inputField = $j(this);
        var wrapper = BS.Util.wrapRelative(inputField);

        if (inputField.hasClass('js_max-width') || inputField.prop('style').width == '100%') {
          wrapper.css('display', 'block');
        }
      }

      BS.AvailableParams.showCompletionAvailableImage(this);

      if (internalProps['teamcity.ui.editSettings.showResolveValueIcon'] && $j(this).val().search(/%[^%]+%/m) != -1) {
        // value contains parameter reference => add resolve icon
        var resolveValueIcon = $j('<i class="icon-eye-open resolveValue" title="Click to see evaluated value"></i>');
        resolveValueIcon.appendTo(this.parentNode);

        var inputElem = this;
        resolveValueIcon.on('click', function() {
          var value = $j(inputElem).val();

          var resolvedValuePopup = new BS.Popup("resolvedValues", {
            url: window['base_uri'] + '/admin/resolveValue.html',
            parameters: editableObjId + "&value=" + encodeURIComponent(value),
            method: "get"
          });
          resolvedValuePopup.showPopupNearElement($j(inputElem)[0], { delay: 0, hideOnMouseClickOutside: true, hideOnMouseOut: false, shift: { x: 0, y: $j(inputElem).outerHeight(true) } });
        });
      } else {
        $j(this).parent().find('.resolveValue').remove();
      }
    });

    inputFields.each(function() {
      BS.AvailableParams.initAutocompleteOnCMFocus(this);
    });
    inputFields.on('focus', function() {
      // Init the autocomplete component when the field is first focused
      BS.AvailableParams.initAutocomplete(this);
    });
  },

  /**
   * @param {jQueryNodeset} element
   * @param {String} autocompletionUrl
   * @param {Boolean} [dynamicUrl]
   * @returns {Function}
   */
  sourceForElement: function(element, autocompletionUrl, dynamicUrl) {
    return function(request, response) {
      if (dynamicUrl) {
        autocompletionUrl = BS.AvailableParams.buildSourceUrl(element.data('editableObjId')) || autocompletionUrl;
      }
      var sliced = BS.AvailableParams.sliceForCompletion(element);
      if (sliced) {
        element.data("ctrlSpace", false);
      } else if (element.data("ctrlSpace")) {
        sliced = BS.AvailableParams.sliceForCtrlSpaceCompletion(element);
      } else if (element.data("showAll")) {
        sliced = BS.AvailableParams.sliceForShowAllCompletion(element);
      }
      element.data("sliced_text", sliced);

      if (sliced !== null) {
        var img = BS.AvailableParams.showLoadingImage(element);
        $j.getJSON(autocompletionUrl + (autocompletionUrl.indexOf('?') < 0 ? '?' : '&') + "term=" + encodeURIComponent(sliced.term), null, function(data) {
          BS.Util.fadeOutAndDelete(img);
          response(data);
        });
      } else {
        response(null);
      }
    };
  },

  /**
   * @param {jQueryNodeset} element
   * @param {String} autocompletionUrl
   * @returns {Function}
   */
  selectForElement: function(element) {
    return function(event, ui) {
      var sliced = element.data("sliced_text");
      var position;
      if (sliced !== null) {
        position = sliced.before_length + ui.item.value.length + 1;
        this.value = sliced.before + ui.item.value + '%' + sliced.after;
        BS.AvailableParams.setCursorPosition(element[0], position);
      }
      return false;
    };
  },

  /**
   * @param {jQueryNodeset} element
   * @param {String} autocompletionUrl
   * @param {Boolean} [dynamicUrl]
   * @returns {Function}
   */
  moreForElement: function(element, autocompletionUrl, dynamicUrl) {
    return function(from, response) {
      if (dynamicUrl) {
        autocompletionUrl = BS.AvailableParams.buildSourceUrl(element.data('editableObjId')) || autocompletionUrl;
      }
      var sliced = element.data("sliced_text");
      if (sliced !== null) {
        var img = BS.AvailableParams.showLoadingImage(element);
        $j.getJSON(autocompletionUrl + (autocompletionUrl.indexOf('?') < 0 ? '?' : '&') + "term=" + encodeURIComponent(sliced.term) + "&from=" + encodeURIComponent(from), null, function(data) {
          BS.Util.fadeOutAndDelete(img);
          response(data);
        });
      } else {
        response(null);
      }
    }
  },

  showCompletionAvailableImage: function(elem) {
    if (elem.className && elem.className.indexOf('__popupAttached') != -1) return;

    var elemId = elem.id;
    elem.className += ' __popupAttached';

    var img = this.appendCompletionImageTo(elem.parentNode);

    var handler = {
      updateVisibility: function() {
        var control = $(elemId);
        img.style.visibility = (control.disabled || control.readOnly) ? 'hidden' :'visible';
      }
    };
    handler.updateVisibility();
    BS.VisibilityHandlers.attachTo(elemId, handler);
  },

  _completionImage: null,
  appendCompletionImageTo: function(elem) {
    function createCompletionImage() {
      var icon = $j('<span class="tc-icon icon16 tc-icon_params paramsPopupHandle" title="Parameter references are supported in this field, type % to see available parameters"></span>');

      icon.on('click', function() {
        $j(this)
            .prevAll('input, textarea')
            .each(function() {
              var $el =  $j(this);
              var cm = $el.data('cm');
              if (cm) {
                cm.focus();
                BS.AvailableParams.autocompleteCM($el, cm.getCursor());
              } else {
                $el
                  .focus()
                  .data('showAll', true)
                  .autocomplete('search');
              }
            });
      });

      return icon;
    }

    this._completionImage = this._completionImage || createCompletionImage();

    var imageClone = this._completionImage.clone(true);
    imageClone.appendTo(elem);
    return imageClone[0];
  },

  showLoadingImage: function(element) {
    element = $j(element);
    var position = element.position();
    var spinnerId = element.attr('id') + '_completion_img';
    return $j("<i>")
        .attr({
          id: spinnerId,
          className: "icon-refresh icon-spin ring-loader-inline"
        })
        .css({
          width: 16,
          height: 16,
          position: 'absolute',
          left: position.left + element.outerWidth(true) - 40, // 20px of right margin plus 20px of offset
          top: position.top + 2
        })
        .insertAfter(element);
  },

  /* Use elementId instead of element or jQuery wrapper because sometimes IE throw exception
  * when range.moveToElement() is called with DOM element not from rendered DOM tree. So we
  * always get element using document.getElementById()*/
  getCursorPosition: function(elementId) {
    var element = document.getElementById(elementId);
    var start = element.selectionStart;
    var range, stored_range, newline_counter = 0;
    if (start || start === 0) {
      return start;
    } else if (document.selection && document.selection.createRangeCollection) {//IE
      range = document.selection.createRange();
      if (range === null) {
        return 0;
      } else {
        stored_range = range.duplicate();
        if (element.tagName.toLowerCase() === "textarea") {
          stored_range.moveToElementText(element);
          stored_range.setEndPoint('EndToEnd', range);
          var result = stored_range.text.length - range.text.length;
          var text = element.value;
          //IE does not take newline character into account
          for (var i = 0; i < result; i++) {
            if (text.charAt(i) === '\n') {
              newline_counter++;
            }
          }
          return result - newline_counter;
        } else {
          start = 0 - stored_range.moveStart('character', -100000);
          return start + range.text.length;
        }
      }
    } else {
      return 0;
    }
  },

  /**
   * @param {DOMNode} element
   * @param {int} position
   */
  setCursorPosition: function(element, position) {
    if (element.setSelectionRange) {
      element.focus();
      element.setSelectionRange(position,position);
    } else if (element.createTextRange) {
      var range = element.createTextRange();
      range.collapse(true);
      range.moveEnd('character', position);
      range.moveStart('character', position);
      range.select();
    }
  },

  getTermStart: function(text, cursor) {
    var last_percent, percent_count;

    percent_count = 0;
    last_percent = -1;
    for (var i = 0; i < cursor; i++) {
      if (text.charAt(i) === '%') {
        last_percent = i;
        percent_count++;
      }
    }
    if (percent_count % 2 === 0) {
      //all opened references already closed, nothing to complete
      return null;
    } else if (last_percent === -1) {
      //no '%' found
      return null;
    } else {
      return last_percent;
    }
  },

  /* returns {before: //text before term for completion or empty string
                    before_length: //length of the prefix - to not calculate it twice
                    term: //term for completion
                    after: //text after term for completion or empty string
                   } or null if cursor is not in the completion position*/
  sliceForCompletion: function(element) {
    element = $j(element);

    var text = element.val(),
        cursor = BS.AvailableParams.getCursorPosition(element.attr('id')),
        term_start = BS.AvailableParams.getTermStart(text, cursor);

    return term_start != null ? {
      before: text.slice(0, term_start+1),
      before_length: term_start+1,
      term: text.slice(term_start+1, cursor),
      after: text.slice(cursor, text.length)
    } : null;
  },

  sliceForCtrlSpaceCompletion: function(element) {
    element = $j(element);

    var text = element.val(),
        cursor = BS.AvailableParams.getCursorPosition(element.attr('id')),
        i, c;

    for (i = cursor-1; i >= 0; i--) {
      c = text.charAt(i);
      if (c === ' ' || c === '\n' || c === '\t') {
        i++;
        break;
      }
    }
    if (i === -1) {
      i = 0;
    }

    return {before: text.slice(0, i) + '%',
            before_length: i + 1,
            term: text.slice(i, cursor),
            after: text.slice(cursor, text.length)};
  },

  sliceForShowAllCompletion: function(element) {
    element = $j(element);

    var text = element.val(),
        cursor = BS.AvailableParams.getCursorPosition(element.attr('id'));

    return {before: text.slice(0, cursor) + '%',
            before_length: cursor,
            term: '',
            after: text.slice(cursor, text.length)};
  }
};

BS.ArchiveProjectDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {

  formElement: function () {
    return $('archiveProjectForm');
  },

  getContainer: function () {
    return $('archiveProjectFormDialog');
  },

  archiveText: "Archive",
  unarchiveText: "Dearchive",

  showArchiveProjectDialog: function(projectId, archive) {
    var titleText = this.archiveText;
    var messageText = 'Are you sure you want to archive this project (and its subprojects, if any)?';
    if (archive) {
      BS.Util.show('removeFromQueueDiv');
      this.formElement().archiveAction.value = "archive";
    } else {
      BS.Util.hide('removeFromQueueDiv');
      this.formElement().archiveAction.value = "unarchive";
      messageText =  'Are you sure you want to unarchive this project (and its subprojects, if any)?';
      titleText = this.unarchiveText;
    }
    this.formElement().projectId.value = projectId;
    this.formElement().ArchiveSubmitButton.value = titleText;
    $('archiveProjectFormTitle').innerHTML = titleText + ' project';
    $('message').innerHTML = messageText;


    this.showCentered();
    this.bindCtrlEnterHandler(this.submit.bind(this));
  },

  submit: function () {
    BS.Util.show('archiveProgressIcon');

    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onCompleteSave: function () {
        BS.Util.hide('archiveProgressIcon');
        BS.reload(true);
      },

      onFailure: function () {
        BS.Util.hide('archiveProgressIcon');
        alert("Problem accessing server");
      }
    }));
    return false;
  }
}));
