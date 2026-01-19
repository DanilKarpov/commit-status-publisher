
BS.CreateGroupDialog = OO.extend(BS.AbstractModalDialog, {
  getContainer: function() {
    return $('addGroupDialog');
  },

  showDialog: function() {
    BS.CreateGroupForm.reset();
    this.showCentered();
    BS.CreateGroupForm.focusFirstElement();
  }

});

BS.AttachToGroupsDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  getContainer: function() {
    return $('attachToGroupsDialog');
  },

  formElement: function() {
    return $('attachToGroups');
  },

  savingIndicator: function() {
    return $('attachProgress');
  },

  showAttachGroupDialog: function(groupCode) {
    $('attachToGroupsContainer').refresh(null, "groupCode=" + encodeURIComponent(groupCode), function() {
      BS.AttachToGroupsDialog.showCentered();
      BS.AttachToGroupsDialog.bindCtrlEnterHandler(BS.AttachToGroupsDialog.submit.bind(BS.AttachToGroupsDialog));
      BS.AttachToGroupsDialog._onSuccess = function() {
        BS.GroupActions.refreshGroupList();
        this.enable();
        this.close();
      }
    });
  },

  showAttachUserDialog: function(userId) {
    $('attachToGroupsContainer') ? $('attachToGroupsContainer').refresh(null, "userId=" + userId, function() {
      BS.AttachToGroupsDialog.showCentered();
      BS.AttachToGroupsDialog.bindCtrlEnterHandler(BS.AttachToGroupsDialog.submit.bind(BS.AttachToGroupsDialog));
      BS.AttachToGroupsDialog._onSuccess = function() {
        BS.reload(true);
      }
    }) : BS.Log.warn('Cannot refresh attachToGroupsContainer');
  },

  showAttachUsersDialog: function(userIds, afterSubmit) {
    var params = "";
    for (var i=0; i<userIds.length; i++) {
      params += "userId=" + userIds[i] + "&";
    }

    $('attachToGroupsContainer').refresh(null, params, function() {
      BS.AttachToGroupsDialog.showCentered();
      BS.AttachToGroupsDialog._onSuccess = function() {
        this.enable();
        this.close();
        afterSubmit();
      }
    });
  },

  _onSuccess: function() {},

  submit: function() {
    var that = this;
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onAttachToGroupsError: function(elem) {
        $("error_attachToGroups_" + that.formElement().id).innerHTML = elem.firstChild.nodeValue;
      },

      onSuccessfulSave: function() {
        that._onSuccess();
      }
    }));
    return false;
  }
}));

BS.GroupActions = {
  refreshGroupList: function() {
    $('groupList').refresh();
  },

  deleteGroup: function(groupCode, numAffectedUsers, afterFinish) {
    var msg = "Are you sure you want to delete group?";
    if (numAffectedUsers > 0) {
      msg += "<br/>This operation will affect " + numAffectedUsers + " user(s).";
    } else {
      msg += "<br/>This operation will not affect any user.";
    }

    BS.confirmDialog.show({
                            text: msg,
                            actionButtonText: "Delete",
                            cancelButtonText: 'Cancel',
                            title: "Delete group",
                            action: function () {
                              BS.ajaxRequest(window['base_uri'] + "/admin/action.html?deleteGroup=true", {
                                parameters: "groupCode=" + encodeURIComponent(groupCode),
                                onSuccess: function() {
                                  if (afterFinish) {
                                    afterFinish();
                                  } else {
                                    BS.reload(true);
                                  }
                                }
                              });
                            }
                          });
  }
};

BS.CreateGroupForm = OO.extend(BS.AbstractWebForm, {
  formElement: function() {
    return $('addGroup');
  },

  reset: function() {
    Form.reset(this.formElement());
    this.clearErrors();
  },

  focusFirstElement: function() {
    setTimeout(function () {
      Form.focusFirstElement(this.formElement())
    }.bind(this), 250);
  },

  savingIndicator: function() {
    return $('addGroupProgress');
  },

  submit: function() {
    var that = this;
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onCreateGroupError: function(elem) {
        $("error_createError").innerHTML = elem.firstChild.nodeValue;
      },

      onGroupCodeError: function(elem) {
        $("error_groupCode").innerHTML = elem.firstChild.nodeValue;
        that.highlightErrorField($("groupCode"));
      },

      onGroupNameError: function(elem) {
        $("error_groupName").innerHTML = elem.firstChild.nodeValue;
        that.highlightErrorField($("groupName"));
      },

      onAttachGroupsError: function(elem) {
        $("error_attachToGroups_" + that.formElement().id).innerHTML = elem.firstChild.nodeValue;
      },

      onSuccessfulSave: function() {
        BS.GroupActions.refreshGroupList();
        that.enable();
        BS.CreateGroupDialog.close();
      }
    }));
    return false;
  }
});

BS.EditGroupForm = OO.extend(BS.AbstractWebForm, {
  formElement: function() {
    return $('editGroup');
  },

  storeInSession: function() {
    this.formElement().submitGroup.value = 'storeInSession';
    BS.FormSaver.save(this, this.formElement().action, BS.StoreInSessionListener);
  },

  submit: function() {
    this.formElement().submitGroup.value = '';
    var that = this;
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onGroupNameError: function(elem) {
        $("error_groupName").innerHTML = elem.firstChild.nodeValue;
        that.highlightErrorField($("groupName"));
      },

      onAttachGroupsError: function(elem) {
        $("error_attachToGroups_" + that.formElement().id).innerHTML = elem.firstChild.nodeValue;
      },

      onEditGroupError: function(elem) {
        $("error_editGroup").innerHTML = elem.firstChild.nodeValue;
      },

      onGroupNotFoundError: function() {
        BS.reload(true);
      },

      onUserPropertyError: function(element) {
        BS.UserProfile.onUserPropertyError(element, that);
      },

      onSuccessfulSave: function() {
        BS.reload(true);
      }
    }));
    return false;
  }
});

BS.UnassignUsersForm = OO.extend(BS.AbstractWebForm, {
  getFormElement: function() {
    return $('unassignUsersForm');
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
      alert("Please select at least one user.");
      return false;
    }

    BS.confirm("Are you sure you want to unassign selected users?", function () {
      BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
        onCompleteSave: function() {
          $('groupUsersContainer').refresh();
        }
      }));
    }.bind(this));

    return false;
  },

  reSort: function(event) {
    var element = Event.element(event);
    var sortBy = element.id;
    if (!sortBy) {
      element = element.firstChild;
      sortBy = element.id;
    }
    var sortAsc = element.className.indexOf('sortedDesc') != -1;
    this.formElement().sortBy.value = sortBy;
    this.formElement().sortAsc.value = sortAsc;

    BS.FormSaver.save(this, "editGroup.html?submitGroup=storeInSession", OO.extend(BS.ErrorsAwareListener, {
      onCompleteSave: function() {
        $('groupUsersContainer').refresh();
      }
    }));
  }
});

BS.AttachUsersToGroupDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  getContainer: function() {
    return $('attachUsersToGroupDialog');
  },

  selectAll: function(select) {
    if (select) {
      BS.Util.selectAll(this.formElement(), "userId");
    } else {
      BS.Util.unselectAll(this.formElement(), "userId");
    }
  },

  showAttachDialog: function(groupCode) {
    var that = BS.AttachUsersToGroupDialog;
    this.groupCode = groupCode;
    $('attachUsersToGroupContainer').refresh(null, "groupCode=" + encodeURIComponent(groupCode), function() {
      that.showCentered();
      that.focusFirstElement();
    });
  },

  findUsers: function() {
    var that = BS.AttachUsersToGroupDialog;
    var findProgress = $('findProgress');

    findProgress.show();
    var groupCode = this.groupCode;
    var form = this.formElement();

    BS.ajaxRequest(form.action, {
      parameters: "groupCode=" + encodeURIComponent(groupCode) + "&keyword=" + encodeURIComponent(form.keyword.value) + "&filterSubmitted=true",
      onSuccess: function() {
        $('userListRefreshable').refresh(null, "groupCode=" + encodeURIComponent(groupCode), function() {
          findProgress.hide();
          that.focusFirstElement();
        });
      }
    });
    return false;
  },

  resetFilter: function() {
    $j("#keyword").val("");
    this.findUsers();
    return false;
  },

  _onSuccess: function() {
    $('groupUsersContainer').refresh();
    this.enable();
    this.close();
  },

  formElement: function() {
    return $('attachUsersToGroup');
  },

  savingIndicator: function() {
    return $('attachProgress');
  },

  focusFirstElement: function() {
    setTimeout(function () {
      Form.focusFirstElement(this.formElement())
    }.bind(this), 250);
  },

  submit: function() {
    this.formElement().submitAction.value='assignUsers';
    var that = this;
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onAttachToGroupsError: function(elem) {
        $("error_attachToGroups_" + that.formElement().id).innerHTML = elem.firstChild.nodeValue;
      },

      onSuccessfulSave: function() {
        that._onSuccess();
      }
    }));
    return false;
  }
}));
