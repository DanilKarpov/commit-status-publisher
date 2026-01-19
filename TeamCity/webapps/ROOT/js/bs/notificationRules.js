
BS.NotifierPropertiesForm = OO.extend(BS.AbstractWebForm, {
  formElement: function() {
    return $('notifierSettingsForm');
  },

  setOrderSaving: function(saving) {
    if (saving) {
      BS.Util.show('saving_settings');
    } else {
      BS.Util.hide('saving_settings');
    }
  },

  submitSettings: function () {
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onCompleteSave: function (form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
        BS.reload(true);
      }
    }), false);

    return false;
  },

  createSourceFunction: function (baseUrl, id, parameterIds) {
    return function (request, response) {
      var term = request.term;

      var url = "?term=" + encodeURIComponent(term);

      for (var i = 0; i < parameterIds.length; i++) {
        var parameterId = parameterIds[i];
        var elem = $j(document.getElementById(parameterId));
        if (elem != null) {
          var value = elem.val();
          url += "&" + encodeURIComponent(parameterId) + "=" + encodeURIComponent(value);
        }
      }

      $j.getJSON(baseUrl + url, function (data) {
        response(data);
        $j(document.getElementById("saving_" + id)).hide();
      });
    };
  },

  createSearchFunction: function (id) {
    return function () {
      $j(document.getElementById("saving_" + id)).show();
    };
  }
});


BS.NotificationRuleForm = OO.extend(BS.QueueLikeSorter, OO.extend(BS.AbstractWebForm, {
  notificatorType: "",
  holderId: "",
  filterType: "",
  filter: "",
  buildsWatchType: "",
  systemWatchType: "",

  initPage: function(buildsWatchType, systemWatchType) {
    this.buildsWatchType = buildsWatchType;
    this.systemWatchType = systemWatchType;
    var watchTypeSystemWide = $('watchTypeSystemWide');
    if (watchTypeSystemWide && watchTypeSystemWide.checked) {
      BS.NotificationRuleForm.switchRightPanel(true);
    }

    $j("#userChangesFilterCB").click(function (e) {
      var $filter = $j("[id*=BUILD_FINISHED_NEW_FAILURE]");

      if (e.currentTarget.checked) {
        $j("#buildTypeBranchFilter").attr("placeholder", "+:*");
        $filter.removeAttr("disabled");
      } else {
        $j("#buildTypeBranchFilter").attr("placeholder", "+:<default>");
        $filter.removeAttr("checked");
        $filter.attr("disabled", "disabled");
      }
    });
  },

  enableSaving: function () {
    if ($j('#notificationRulesRows .draggable').length > 1) {
      Sortable.create('notificationRulesRows', {
        tag: "div",
        onUpdate: function (el) {
          BS.NotificationRuleForm.scheduleUpdate(el);
        },
        onChange: function(el) {
        }
      });
    }
  },

  updateDisabledChildren: function() {
    $j("#configurations").find("input.group:checked")
  },

  updateWatchType: function() {
    try {
      $('watchType').value = '';
      if ($('watchTypeBuildConfigurations').checked) {
        $('watchType').value = this.buildsWatchType;
        $('watchTypeBuildTypeSettings').show();
        return;
      }

      if ($('watchTypeSystemWide').checked) {
        $('watchType').value = this.systemWatchType;
        $('watchTypeBuildTypeSettings').hide();
      }
    } finally {
      BS.MultilineProperties.updateVisible();
    }
  },

  setOrderSaving: function(saving) {
    this.hideSuccessMessages();
    BS.QueueLikeSorter.setOrderSaving(saving);
  },

  setNotificatorType: function(type) {
    this.notificatorType = type;
  },

  setHolderId: function(holderId) {
    this.holderId = holderId;
  },

  setFilter: function(filterType, filter) {
    this.filterType = filterType;
    this.filter = filter;
  },

  containerId: 'notificationRulesRows',

  afterOrderSaving: function() {
    BS.NotificationRuleForm.requestNewIds();
  },

  updateIdsFromData: function () {
    for(var oldId in BS.NotificationRuleIds._ids) {
      var newId = BS.NotificationRuleIds._ids[oldId];
      var element = $('rule_' + oldId);
      if (element && newId != null) {
        element.setAttribute('id', 'rule_' + newId);
      }
    }
  },

  _parameters: function() {
    return "&holderId=" + this.holderId + "&notificatorType=" + this.notificatorType + "&filterType=" + this.filterType + "&filter=" + this.filter;
  },

  requestNewIds: function() {
    BS.ajaxRequest(window['base_uri'] + "/notificationRules.html", {
      parameters: "idsRequest=1" + BS.NotificationRuleForm._parameters(),
      onSuccess: function(transport, object) {
        transport.responseText.evalScripts();
        BS.NotificationRuleForm.updateIdsFromData();
      },
      method: "get"
    });
  },

  getActionUrl: function() {
    return window['base_uri'] + "/notificationRules.html";
  },

  getActionParameters: function(node) {
    return "newOrder=" + this.computeOrder(node, "rule_") + this._parameters();
  },

  _draggableTagName: "div",
  _rulePrefix: "rule_",

  getRuleIdFromNodeId: function(nodeId, tagNameInLowerCase, prefix) {
    var node = $(nodeId);
    while (node != null) {
      if (node.tagName.toLowerCase() == tagNameInLowerCase) {
        var id = node.getAttribute('id');
        if (id.startsWith(prefix)) {
          return id.substring(prefix.length);
        }
      }
      node = node.parentNode;
    }
    return null;
  },

  _getRuleIdFromNodeId: function(nodeId) {
    return BS.NotificationRuleForm.getRuleIdFromNodeId(nodeId, BS.NotificationRuleForm._draggableTagName, BS.NotificationRuleForm._rulePrefix);
  },

  editRule: function(url, nodeId) {
    var ruleId = nodeId == null ? -1 : BS.NotificationRuleForm._getRuleIdFromNodeId(nodeId);

    BS.ajaxRequest(url, {
      parameters: "editRule=true&ruleId=" + ruleId + BS.NotificationRuleForm._parameters(),
      onComplete: function(transport, object) {
        document.location.href =
          document.location.origin +
          document.location.pathname +
          document.location.search +
          "#ruleEditingForm";
        BS.reload(true);
      }
    });
  },

  // addUnsubscribeRule: function(url) {
  //   BS.ajaxRequest(url, {
  //     parameters: "addUnsubscribeRule=true" + BS.NotificationRuleForm._parameters(),
  //     onComplete: function(transport, object) {
  //       document.location.hash = 'ruleEditingForm';
  //       BS.reload(true);
  //     }
  //   });
  // },

  moveToTop: function(nodeId) {
    var ruleId = BS.NotificationRuleForm._getRuleIdFromNodeId(nodeId);
    var node = BS.NotificationRuleForm._rulePrefix + ruleId;
    var elem = $(node);
    var parent = elem.parentNode;
    if (parent.firstChild.id == elem.id) return; // do not move first item
    parent.removeChild(elem);
    parent.insertBefore(elem, parent.firstChild);
    this.scheduleUpdate(parent);
  },

  removeRule: function(url, nodeId) {
    var ruleId = BS.NotificationRuleForm._getRuleIdFromNodeId(nodeId);

    if (!confirm("Are you sure you want to remove this rule?")) return;

    BS.ajaxRequest(url, {
      parameters: "deleteRule=" + ruleId + BS.NotificationRuleForm._parameters(),
      onComplete: function(transport, object) {
        BS.reload(true);
      }
    });
  },

  cancelEditing: function() {
    BS.ajaxRequest(this.formElement().action, {
      parameters: "cancelEditing=true" + BS.NotificationRuleForm._parameters(),
      onComplete: function(transport, object) {
        var href = document.location.href;
        var pos = href.indexOf("#");
        if (pos != -1) {
          href = href.substring(0, pos);
        }
        document.location.replace(href);
      }
    });
  },

  formElement: function() {
    return $('notificationRuleForm');
  },

  submitRule: function(overwrite) {
    var that = this;

    if ($('watchTypeBuildConfigurations').checked) {
      this.formElement().branchFilter.value = $('buildTypeBranchFilter').value;
      if (this.formElement().localRuleFilter) this.formElement().localRuleFilter.value = !$('applyToChildren').checked;
      if (this.formElement().unsubscribeRule) this.formElement().unsubscribeRule.value = !!$('unsubscribeRuleControl').checked;
      this.formElement().favoriteBuildsFilter.value = !!$('buildTypeFavoriteBuildsFilter').checked;
      this.formElement().userChangesFilter.value = !!$('userChangesFilterCB').checked;
    }

    var url = this.formElement().action;
    if (overwrite) {
      url += "?overwriteRule=1";
    }

    BS.FormSaver.save(this, url, OO.extend(BS.ErrorsAwareListener, {
      onProjectNotFoundError: function(elem) {
        $("errorProject").innerHTML = elem.firstChild.nodeValue;
      },

      onBuildTypeNotFoundError: function(elem) {
        $("errorBuildType").innerHTML = elem.firstChild.nodeValue;
      },

      onDuplicateRuleError: function(elem) {
        var systemRule = $('watchTypeSystemWide').checked;
        var message;

        if (systemRule) {
          message = "Rule for system events already exists.\n\n" +
                    "Click \"Ok\" to overwrite the existing rule.\n";
        } else {
          message = "One or more rules with selected build configuration(s) already exist.\n\n" +
                    "Click \"Ok\" to save this rule and remove conflicting configurations from the existing rules.\n" +
                    "Click \"Cancel\" to continue editing."
        }

        if (confirm(message)) {
          that.submitRule(true);
        }
      },

      onMyChangesWrongBranchFilterError: function(elem) {
        $("myChangesBranchFilterError").innerHTML = elem.firstChild.nodeValue;
      },

      onSpecificBuildTypesWrongBranchFilterError: function(elem) {
        $("buildTypeBranchFilterError").innerHTML = elem.firstChild.nodeValue;
      },

      onAllProjectsWrongBranchFilterError: function(elem) {
        $("projectBranchFilterError").innerHTML = elem.firstChild.nodeValue;
      },

      onSpecificProjectsWrongBranchFilterError: function(elem) {
        $("projectBranchFilterError").innerHTML = elem.firstChild.nodeValue;
      },

      onCompleteSave: function(form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
        if (!err) {
          BS.reload(true);
        }
      }
    }), false);

    return false;
  }
}));

_.extend(BS.NotificationRuleForm, {
  _getEventElement: function(eventName) {
    return $("editingEvents['" + eventName + "']");
  },
  _setEventElementProperty: function(eventName, property, value) {
    var element = this._getEventElement(eventName);
    if (element) {
      element[property] = value;
    }
  },
  uncheckEvent: function(eventName) {
    this._setEventElementProperty(eventName, 'checked', false);
  },

  checkEvent: function(eventName) {
    this._setEventElementProperty(eventName, 'checked', true);
  },

  enableEvent: function(eventName) {
    this._setEventElementProperty(eventName, 'disabled', false);
  },

  disableEvent: function(eventName) {
    this._setEventElementProperty(eventName, 'disabled', true);
  },

  isSystemEventsShown: function() {
    return BS.Util.visible('system-wide-events');
  },

  isUserChangesWatched: function() {
    return $("userChangesFilterCB").checked;
  },

  checkFailureEvents: function () {
    this.checkEvent('BUILD_FAILED_TO_START');
  },

  uncheckFailureEvents: function () {
    [ 'BUILD_FINISHED_NEW_FAILURE',
      'BUILD_FAILED_TO_START',
      'NEW_BUILD_PROBLEM_OCCURRED',
      'FIRST_FAILURE_AFTER_SUCCESS' ]
    .forEach(this.uncheckEvent.bind(this));
  },

  uncheckNonSystemEvents: function() {
    [ 'BUILD_FINISHED_FAILURE',
      //'BUILD_FINISHED_NEW_FAILURE',
      'NEW_BUILD_PROBLEM_OCCURRED',
      'FIRST_FAILURE_AFTER_SUCCESS',
      'BUILD_FINISHED_SUCCESS',
      'FIRST_SUCCESS_AFTER_FAILURE',
      'BUILD_FAILING',
      'BUILD_STARTED',
      'BUILD_PROBABLY_HANGING',
      'RESPONSIBILITY_CHANGES',
      'MUTE_UPDATED',
      'BUILD_FAILED_TO_START' ]
      .forEach(this.uncheckEvent.bind(this));
  },

  uncheckSystemEvents: function() {
    this.uncheckEvent('RESPONSIBILITY_ASSIGNED');
  },

  switchRightPanel: function(showSystemEvents) {
    var currentState = this.isSystemEventsShown();
    if (currentState == showSystemEvents) {
      return;
    }

    if (currentState) {
      this.uncheckSystemEvents();
      BS.Util.hide('system-wide-events');
      BS.Util.show('non-system-events');
      if (this.isUserChangesWatched()) {
        this.enableEvent('BUILD_FINISHED_NEW_FAILURE');
      } else {
        this.disableEvent('BUILD_FINISHED_NEW_FAILURE');
      }
    } else {
      this.uncheckNonSystemEvents();
      BS.Util.show('system-wide-events');
      BS.Util.hide('non-system-events');
    }
  },

  switchToWatchFavoriteBuilds: function() {
    this.enableEvent('BUILD_FINISHED_NEW_FAILURE');
    this.disableEvent('MUTE_UPDATED');
    this.uncheckEvent('MUTE_UPDATED');
    this.switchRightPanel(false);
    this.updateWatchType();
  },

  switchToWatchTypeCommitter: function() {
    this.enableEvent('BUILD_FINISHED_NEW_FAILURE');
    this.disableEvent('MUTE_UPDATED');
    this.uncheckEvent('MUTE_UPDATED');
    this.switchRightPanel(false);
    this.updateWatchType();
  },

  switchToWatchTypeProject: function() {
    this.disableEvent('BUILD_FINISHED_NEW_FAILURE');
    this.uncheckEvent('BUILD_FINISHED_NEW_FAILURE');
    this.enableEvent('MUTE_UPDATED');
    this.switchRightPanel(false);
    this.updateWatchType();
  },

  switchToWatchTypeBuildConfigurations: function() {
    this.disableEvent('BUILD_FINISHED_NEW_FAILURE');
    this.uncheckEvent('BUILD_FINISHED_NEW_FAILURE');
    this.enableEvent('MUTE_UPDATED');
    this.switchRightPanel(false);
    this.updateWatchType();
    var multiselect = document.querySelector('project-buildtype-multiselect');
    if (multiselect != undefined) {
      multiselect.loadData();
    }
  },

  switchToWatchTypeSystemWide: function() {
    this.switchRightPanel(true);
    this.updateWatchType();
  }
});

