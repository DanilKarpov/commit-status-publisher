(function($) {
  BS.AdminAuth = OO.extend(BS.AbstractWebForm, {
    ACTION_URL: window["base_uri"] + "/admin/authAction.html",

    formElement: function() {
      return $('#generalSettings').get(0);
    },

    init: function() {
      var that = this;

      this.removeUpdateStateHandlers();
      this.doSetUpdateStateHandlers({
        updateState: function() {
          that.storeInSession();
        },
        saveState: function() {
          that.saveAll();
        }
      });

      // Do not show any confirm dialogs for inner links.
      $("#authModules").find("a").not(".external").click(function(e) {
        e.stopPropagation();
      });
    },

    refresh: function() {
      $("#authModules").get(0).refresh("authProgress");
    },

    storeInSession: function() {
      var url = this.ACTION_URL + "?action=storeInSession";
      BS.FormSaver.save(this, url, BS.StoreInSessionListener);
      return false;
    },

    saveAll: function() {
      if (!this._validate()) {
        return false;
      }

      var progress = $("#authProgress").show();
      var parameters = BS.Util.serializeForm($("#generalSettings").get(0));
      BS.ajaxRequest(this.ACTION_URL + "?action=save", {
        method: "post",
        parameters: parameters,
        onComplete: function() {
          BS.reload(true);
          progress.hide();
        }
      });
      return false;
    },

    _validate: function() {
      var result = true;

      if ($("#guestLoginAllowed").is(":checked") && !$("#guestUsername").val()) {
        $("#invalidGuestUsername").show();
        result = false;
      } else {
        $("#invalidGuestUsername").hide();
      }

      if ($("#rootLoginAllowed").is(":checked") && !$("#rootUsername").val()) {
        $("#invalidRootUsername").show();
        result = false;
      } else {
        $("#invalidRootUsername").hide();
      }

      return result;
    },

    cancelAll: function() {
      var progress = $("#authProgress").show();
      BS.ajaxRequest(this.ACTION_URL + "?action=cancel", {
        method: "post",
        onComplete: function() {
          BS.AdminAuth.refresh();
          progress.hide();
        }
      });
      return false;
    },

    remove: function(id) {
      if (confirm("Are you sure you want to delete this authentication module?")) {
        BS.ajaxRequest(this.ACTION_URL + "?action=remove&authModuleId=" + id, {
          method: "post",
          onComplete: function() {
            BS.AdminAuth.refresh();
          }
        });
      }
      return false;
    },

    logoutAllUsers: function () {
      var progress = $("#authProgress").show();
      if (confirm("Are you sure you want to log out all TeamCity users?")) {
        BS.ajaxRequest(this.ACTION_URL + "?action=logoutAllUsers", {
          method: "post",
          onComplete: function () {
            BS.AdminAuth.refresh();
            progress.hide();
          }
        });
      } else {
        $("#authProgress").hide();
      }
      return false;
    },

    deleteAllAccessTokens: function () {
      var progress = $("#authProgress").show();
      if (confirm("Are you sure you want to delete access tokens for all TeamCity users?")) {
        BS.ajaxRequest(this.ACTION_URL + "?action=deleteAllAccessTokens", {
          method: "post",
          onComplete: function () {
            BS.AdminAuth.refresh();
            progress.hide();
          }
        });
      } else {
        $("#authProgress").hide();
      }
      return false;
    }
  });

  BS.AdminAuthPresetsDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
    URL: BS.AdminAuth.ACTION_URL + "?action=applyPreset",
    _descriptions: {},

    formElement: function() {
      return $('#authPresetsForm').get(0);
    },

    getContainer: function() {
      return $("#authPresetsFormDialog").get(0);
    },

    presetSelected: function() {
      var index = $("#presetFileName").get(0).selectedIndex;
      $("#presetDescription").text(this._descriptions[index] || "");
      $("#authPresetsSubmitButton").prop("disabled", index == 0);
    },

    applyPreset: function() {
      var that = this;
      var progress = $("#authPresetsFormProgress").show();
      BS.FormSaver.save(this, that.URL, OO.extend(BS.ErrorsAwareListener, {
        onCompleteSave: function() {
          progress.hide();
          BS.AdminAuth.refresh();
          that.close();
        }
      }));
      return false;
    },

    show: function() {
      this.showCentered();
      return false;
    },

    cancel: function() {
      return this.close();
    }
  }));

  BS.AdminAuthDialogCommon = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
    URL: "",

    doShow: function(edit, params) {
      this.doReloadEditee(edit, params, true);
      // For some mysterious reason, "submit" can be called twice on Ctrl-Enter,
      // even though only key processor is invoked only once (TW-33381).
      // The problem is currently solved on server side.
      // Reproduces only in FF, and only for "Add" dialog.
      this.bindCtrlEnterHandler(this.submit.bind(this));
      return false;
    },

    doReloadEditee: function(notEmptyEditee, params, show) {
      var that = this;
      var dialog = $(that.getContainer());
      dialog.find(".content").removeClass('red-text');

      var submitButton = dialog.find(".submitButton");
      submitButton.prop("disabled", true);

      if (notEmptyEditee) {
        that.showCenteredOrRecenter(show);

        var progress = submitButton.siblings(".progressRing").show();
        dialog.find(".content").load(this.URL, params, function(response, status) {
          if (status !== "error") {
            progress.hide();
            submitButton.prop("disabled", false);
          } else {
            dialog.find(".content").addClass('red-text').text("Something went wrong");
          }
          that.recenterDialog();
        });
      } else {
        that.showCenteredOrRecenter(show);
      }
    },

    showCenteredOrRecenter: function(show) {
      if (show) {
        this.showCentered();
      } else {
        this.recenterDialog();
      }
    },

    closeDialog: function() {
      $(this.getContainer()).find(".content").html("");
      this.close();
      return false;
    },

    cancel: function() {
      return this.closeDialog();
    },

    doSubmit: function(progress) {
      var that = this;
      var params = this.serializeParameters();

      progress.show();
      BS.ajaxRequest(this.URL, {
        method: "post",
        parameters: params,
        onComplete: function() {
          progress.hide();
          BS.reload(true);
          BS.AdminAuth.refresh();
          that.closeDialog();
        }
      });
      return false;
    }
  }));

  BS.AdminAuthAddDialog = OO.extend(BS.AdminAuthDialogCommon, {
    URL: "authAdd.html",

    getContainer: function() {
      return $("#addAuthModuleDialog").get(0);
    },

    formElement: function() {
      return $("#addAuthModule").get(0);
    },

    showAdd: function() {
      var chooser = $("#addAuthModuleType").get(0);
      chooser.selectedIndex = 0;
      chooser.value = chooser.options[0].value;
      return this.doShow();
    },

    reloadEditee: function() {
      var chooser = $("#addAuthModuleType").get(0);
      this.doReloadEditee(chooser.selectedIndex != 0, "authModuleType=" + encodeURIComponent(chooser.value), false);
    },

    submit: function() {
      return this.doSubmit($("#addAuthProgress"));
    }
  });

  BS.AdminAuthEditDialog = OO.extend(BS.AdminAuthDialogCommon, {
    URL: "authEdit.html",

    getContainer: function() {
      return $("#editAuthModuleDialog").get(0);
    },

    formElement: function() {
      return $("#editAuthModule").get(0);
    },

    showEdit: function(authModuleId) {
      $("#authModuleId").val(authModuleId);
      return this.doShow(true, "authModuleId=" + authModuleId);
    },

    submit: function() {
      return this.doSubmit($("#editAuthProgress"));
    }
  });
})(jQuery);
