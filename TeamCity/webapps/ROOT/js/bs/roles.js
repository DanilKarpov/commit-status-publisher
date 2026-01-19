BS.RolesForm = {
  removePermission: function (role, permission) {
    if (!confirm("Are you sure you want to remove this permission?")) return;
    BS.ajaxRequest(window['base_uri'] + "/admin/action.html?removeRolePermission=" + permission, {
      parameters: "fromRole=" + role,
      onSuccess: function() {
        BS.RolesForm.refreshRolesList();
        BS.RolesForm.refreshDialogs();
      }
    });
  },

  excludeIncludedRole: function (role, included) {
    if (!confirm("Are you sure you want to exclude this role?")) return;
    BS.ajaxRequest(window['base_uri'] + "/admin/action.html?excludeIncludedRole=" + included, {
      parameters: "fromRole=" + role,
      onSuccess: function () {
        BS.RolesForm.refreshRolesList();
        BS.RolesForm.refreshDialogs();
      }
    });
  },

  deleteRole: function (role) {
    if (!confirm("Are you sure you want to delete this role?")) return;

    BS.ajaxRequest(window['base_uri'] + "/admin/action.html?deleteRole=" + role, {
      onSuccess: function () {
        BS.RolesForm.refreshRolesList();
        BS.RolesForm.refreshDialogs();
      }
    });
  },

  refreshRolesList: function () {
    $('rolesList').refresh();
  },

  refreshDialogs: function () {
    $('addPermissionsDialogs').refresh();
  }
};

BS.AddPermissionsDialog = OO.extend(BS.AbstractModalDialog, {
  getContainer: function() {
    return $('addPermissionsDialog');
  },

  getFormElement: function() {
    return $('addPermissions');
  },

  show: function(roleId) {
    var filterField = $('permissionId_filter');

    this.roleId = roleId;
    this.fillPermissionsList(roleId);
    this.showCentered();
    this.bindCtrlEnterHandler(this.save.bind(this));
    filterField.value = '';
    BS.InPlaceFilter.applyFilter('permissionId', filterField);
    filterField.select();
    filterField.focus();
  },

  save: function() {
    BS.Util.show('addingPermissions');
    Form.disable(this.getFormElement());

    var params = BS.Util.serializeForm(this.getFormElement());

    var roleId = this.roleId;
    BS.ajaxRequest(this.getFormElement().action, {
      parameters: params + "&role=" + roleId,
      onComplete: function () {
        BS.Util.hide('addingPermissions');
        Form.enable(BS.AddPermissionsDialog.getFormElement());
        BS.AddPermissionsDialog.close();
        BS.RolesForm.refreshRolesList();
        BS.RolesForm.refreshDialogs();
      }
    });

    return false;
  }
});

BS.IncludeRoleDialog = OO.extend(BS.AbstractModalDialog, {
  getContainer: function() {
    return $('includeRoleDialog');
  },

  getFormElement: function() {
    return $('includeRole');
  },

  show: function(roleId) {
    this.roleId = roleId;
    this.fillRolesList(roleId);
    this.showCentered();
    this.bindCtrlEnterHandler(this.save.bind(this));
  },

  save: function() {
    BS.Util.show('includingRole');
    Form.disable(this.getFormElement());

    var params = BS.Util.serializeForm(this.getFormElement());

    var roleId = this.roleId;
    BS.ajaxRequest(this.getFormElement().action, {
      parameters: params + "&role=" + roleId,
      onComplete: function () {
        BS.Util.hide('includingRole');
        Form.enable(BS.IncludeRoleDialog.getFormElement());
        BS.IncludeRoleDialog.close();
        BS.RolesForm.refreshRolesList();
        BS.RolesForm.refreshDialogs();
      }
    });

    return false;
  }
});

BS.CreateRoleDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  getContainer: function() {
    return $('createRoleDialog');
  },

  getFormElement: function() {
    return $('createRole');
  },

  show: function() {
    var form = this.getFormElement();
    Form.reset(form);
    this.clearErrors();

    this.showCentered();
    this.bindCtrlEnterHandler(this.save.bind(this));
    form.roleName.focus();
  },

  save: function() {
    BS.Util.show('creatingRole');
    Form.disable(this.getFormElement());

    var roleName = this.getFormElement().roleName.value;

    BS.ajaxRequest(window['base_uri'] + "/admin/action.html?createNewRole=" + roleName, {
      onComplete: function (transport) {
        BS.Util.hide('creatingRole');
        Form.enable(BS.CreateRoleDialog.getFormElement());
        var errors = BS.XMLResponse.processErrors(transport.responseXML, {
          onDuplicateRoleError: function(elem) {
            BS.CreateRoleDialog.highlightRoleNameError(elem.firstChild.nodeValue);
          },
          onInvalidRoleNameError: function(elem) {
            BS.CreateRoleDialog.highlightRoleNameError(elem.firstChild.nodeValue);
          }
        });
        if (!errors) {
          BS.CreateRoleDialog.close();
          BS.RolesForm.refreshRolesList();
          BS.RolesForm.refreshDialogs();
        }
      }
    });
    
    return false;
  },

  highlightRoleNameError: function(message) {
    $("error_roleName").innerHTML = message;
    this.highlightErrorField($("roleName"));
  }
}));