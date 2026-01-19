BS.UserListForm = OO.extend(BS.AbstractWebForm, {
  formElement: function() {
    return $('filterForm');
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
    this.doSearch();
  },

  doSearch: function() {
    var that = this;
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.SimpleListener, {
      onCompleteSave: function() {
        $('userTable').refresh($('saving'), that._advanced ? "advanced=true" : null);
      }
    }), false);
    return false;
  },

  toggleAdvanced: function(link) {
    $j('#advanced-fields').show();
    $j(link).hide();
    this._advanced = true;
    return false;
  },

  resetFilter: function() {
    this.formElement().keyword.value = '';
    $('groupCode').selectedIndex = 0;
    if ($('roleId')) {
      $('roleId').selectedIndex = 0;
    }
    if ($('projectId')) {
      $('projectId').selectedIndex = 0;
    }

    if ($('rolesConditionInverted')) {
      $('rolesConditionInverted').checked = false;
    }
  },

  getSelectedUsers: function () {
    return BS.Util.getSelectedValues($('filterForm'), "userId");
  },

  addSelected: function() {
    var that = this;
    BS.AttachToGroupsDialog.showAttachUsersDialog(this.getSelectedUsers(), function() {
      that.refreshAfterAction();
    });
    return false;
  },

  /**
   * Assign/unassign roles to/from the selected users
   * @param {boolean} assign action switcher
   * @returns {boolean}
   */
  toggleSelected: function (assign) {
    var id  = assign ? '#assignRole_projectId' : '#unassignRole_projectId';
    var dialog = assign ? BS.AssignRoleDialog : BS.UnassignRoleDialog;
    dialog.show(this.getSelectedUsers(), this.refreshAfterAction.bind(this));
    BS.expandMultiSelect($j(id));
    return false;
  },
  /** @deprecated */
  assignSelected: function() {
    return this.toggleSelected(true);
  },
  /** @deprecated */
  unassignSelected: function() {
    return this.toggleSelected(false);
  },

  removeSelected: function() {
    var selected = this.getSelectedUsers();
    if (selected.length == 0) return false;

    var that = this;
    BS.confirm("Are you sure you want to delete " + selected.length + " users?", function () {
      BS.AdminActions.deleteUsers(selected, function() {
        that.refreshAfterAction();
      });
    });

    return false;
  },

  showOrHideActionsOnSelect: function() {
    BS.AdminActions.showOrHideActions(".userList input", "#users-actions-docked");
  },

  refreshAfterAction: function() {
    $('userTable').refresh();
    $j("#users-actions-docked").hide();
  }
});
