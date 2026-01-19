BS.Plugins = {};

(function (o) {
  o.Problems = {};
  o.OverwriteCandidates = [];
  o.NameToRoots = {};

  o.registerProblem = function (id) {
    o.Problems[id] = new BS.Popup(id, {delay: 0, hideDelay: -1});
    return o.Problems[id];
  };

  o.toggleProblem = function (id, el) {
    if (!o.Problems.hasOwnProperty(id)) {
      o.registerProblem(id)
    }
    var problem = o.Problems[id];
    if (problem.isShown()) {
      problem.hidePopup()
    } else {
      problem.showPopupNearElement(el);
    }
  };

  o.focus = function(pluginPath) {
    $j(".focusedPlugin").removeClass("focusedPlugin");
    $j(BS.Util.escapeId("plugin_" + pluginPath)).addClass("focusedPlugin");
    setTimeout(function() {
      $j(".focusedPlugin").removeClass("focusedPlugin");
    }, 2000);
    $j('html, body').animate({
      scrollTop: $j(BS.Util.escapeId("plugin_" + pluginPath)).offset().top - 200
    }, 500);
  };

  o.addOverwriteCandidate = function(name) {
    o.OverwriteCandidates.push(name)
  };

  o.registerPlugin = function (name, root, isLatestVersion, version, uuid) {
    var roots = o.NameToRoots[name];
    if (roots === undefined) {
      o.NameToRoots[name] = [{root: root, latest: isLatestVersion, version: version, uuid: uuid}];
    } else {
      roots.push({root: root, latest: isLatestVersion, version: version, uuid: uuid});
    }
  };

  o.deletePlugin = function(name, uuid) {
    BS.confirmDialog.show({
                            text: "Are you sure you want to delete the '" + name.escapeHTML() + "' plugin?",
                            actionButtonText: "Delete",
                            cancelButtonText: 'Cancel',
                            title: "Delete '" + name + "' plugin",
                            action: function () {
                              var completed = $j.Deferred();
                              BS.ajaxRequest(window["base_uri"] + "/admin/plugins.html", {
                                parameters: {uuid: uuid, action: "delete"},
                                onComplete: function (transport) {
                                  completed.resolve();
                                  BS.reload(true);
                                }
                              });
                              return completed;
                            }
                          });
    return false;
  };

  o.reloadPluginToNewVersion = function (name, displayName, uuid, newVersionPath) {
    var text = '<p>This plugin can be updated without server restart. Plugin will be loaded from ' + newVersionPath.escapeHTML() + '</p>';

    BS.confirmDialog.show({
      text: text,
      actionButtonText: 'Reload',
      cancelButtonText: 'Cancel',
      title: 'Reload plugin',
      action: function () {
        var completed = $j.Deferred();
        BS.ajaxRequest(window["base_uri"] + "/admin/plugins.html", {
          parameters: {uuid: uuid, reload: true, action: "setEnabled"},
          onComplete: function (transport) {
            completed.resolve();
            BS.reload(true);
          }
        });
        return completed;
      }
    });

    return false;
  };

  o.loadAllPlugins = function (pluginsArr) {
    BS.confirmDialog.show({
      text: 'Enable all uploaded plugins <strong>without server restart</strong>?',
      actionButtonText: 'Enable',
      cancelButtonText: 'Cancel',
      title: 'Enable uploaded plugins',
      action: function () {
        var completed = $j.Deferred();
        BS.ajaxRequest(window["base_uri"] + "/admin/plugins.html", {
          parameters: {action: "loadAll", plugins: pluginsArr},
          onComplete: function (transport) {
            completed.resolve();
            BS.reload(true);
          }
        });
        return completed;
      }
    });

    return false;
  };

  o.reloadAllPlugins = function (pluginsArr) {
    BS.confirmDialog.show({
      text: 'Apply all plugins updates without server restart?',
      actionButtonText: 'Apply',
      cancelButtonText: 'Cancel',
      title: 'Apply updates',
      action: function () {
        var completed = $j.Deferred();
        BS.ajaxRequest(window["base_uri"] + "/admin/plugins.html", {
          parameters: {action: "reloadAll", plugins: pluginsArr},
          onComplete: function (transport) {
            completed.resolve();
            BS.reload(true);
          }
        });
        return completed;
      }
    });

    return false;
  };

  o.toggleEnabledStatus = function (name, displayName, uuid, enabled, runtimeAction) {
    var affectedPlugins = BS.Plugins.NameToRoots[name];

    if (!enabled) {
      var text = '';
      if (runtimeAction) {
        text += '<div>Disable the plugin without server restart?</div>';
      } else {
        text += '<div>Disable the plugin and do not load it during the next server startup?</div>';
      }
      text += '<p>Note: this can break some TeamCity functionality if it depended on the plugin presence.</p>';

      BS.confirmDialog.show({
        text: text,
        actionButtonText: 'Disable',
        cancelButtonText: 'Cancel',
        title: "Disable '" + displayName + "' plugin",
        action: function () {
          var completed = $j.Deferred();
          BS.ajaxRequest(window["base_uri"] + "/admin/plugins.html", {
            parameters: o.createParametersForRequest(name, uuid, enabled),
            onComplete: function (transport) {
              completed.resolve();
              BS.reload(true);
            }
          });
          return completed;
        }
      })
    } else {
      var enableText = '';
      if (runtimeAction) {
        enableText += '<div>Enable the plugin <strong>without server restart</strong>?</div>';
      } else {
        enableText += '<div>Enable the plugin and load it during the next server startup?</div>';
      }
      var latestVersion;
      if (affectedPlugins && affectedPlugins.length > 1) {
        enableText += '<div>You have ' + affectedPlugins.length + ' different versions of this plugin installed on your server: </div>';
        enableText += "<ul>";
        for (var j = 0; j < affectedPlugins.length; j++) {
          if (affectedPlugins[j].latest) {
            latestVersion = affectedPlugins[j];
          }
          enableText += "<li>Version '" + affectedPlugins[j].version.escapeHTML() + '\' in ' + affectedPlugins[j].root.escapeHTML() + "</li>";
        }
        enableText += "</ul>";
        enableText += "<div>The latest version of the plugin will be loaded.</div>";
      }

      BS.confirmDialog.show({
        text: enableText,
        actionButtonText: 'Enable',
        cancelButtonText: 'Cancel',
        title: 'Enable \'' + displayName + '\' plugin',
        action: function () {
          var completed = $j.Deferred();
          BS.ajaxRequest(window["base_uri"] + "/admin/plugins.html", {
            parameters: o.createParametersForRequest(name, latestVersion ? latestVersion.uuid : uuid, enabled),
            onComplete: function (transport) {
              completed.resolve();
              BS.reload(true);
            }
          });
          return completed;
        }
      })
    }

    return false;
  };

  o.createParametersForRequest = function(name, uuid, enabled) {
    var res = {enabled: enabled, action: "setEnabled"};
    if (uuid) {
      res['uuid'] = uuid;
    } else {
      //request for disable/enable all plugins
      res['allPluginsAction'] = name;
    }
    return res;
  };

  o.openPluginsRepository = function() {
    BS.confirmDialog.show({
      text: "The current server URL, version, and unique server id will be passed to the JetBrains Plugins Repository to allow one-click plugin installation.",
      actionButtonText: "Proceed",
      cancelButtonText: 'Cancel',
      title: "Open TeamCity Plugins Repository",
      action: function () {
        $j('#openPluginsForm').submit();
      }
    });

    return false;
  };

  o.checkUpdates = function () {
    BS.ajaxRequest(window["base_uri"] + "/admin/plugins.html", {
      parameters: {action: "checkUpdates"},
      onComplete: function () {
        BS.reload(true);
      }
    });
    return false;
  },

  o.toggleCheckUpdates = function (checkUpdates) {
    BS.ajaxRequest(window["base_uri"] + "/admin/plugins.html", {
      parameters: {enabled: checkUpdates, action: "toggleCheckUpdates"},
      onComplete: function () {
      }
    });
    return false;
  },

  o.updatePlugin = function (displayName, version, oldVersion, downloadUrl) {
    var text = "<p>Update the '" + displayName + "' plugin from version " + oldVersion + " to version " + version + "?</p>";
    BS.confirmDialog.show({
      text: text,
      actionButtonText: "Update",
      cancelButtonText: 'Cancel',
      title: "Update '" + displayName + "' plugin",
      action: function () {
        var $modalDialogBody = $j(BS.confirmDialog.getContainer()).find(".modalDialogBody");
        var updateError = $modalDialogBody.find(".updatePluginError");
        if (!updateError || updateError.length == 0) {
          updateError = $j("<div class='updatePluginError attentionComment attentionRed'></div>");
          $modalDialogBody.find("div:nth-child(1)").after(updateError);
        }
        updateError.hide();
        var completed = $j.Deferred();
        BS.ajaxRequest(window["base_uri"] + "/admin/plugins.html", {
          parameters: {downloadUrl: downloadUrl, action: "installPlugin"},
          onComplete: function (response) {
            var $info = $j(response.responseXML).find('installPlugin');
            var error = $info.attr('error');
            if (error) {
              updateError.text(error).show();
              completed.reject();
              BS.Util.hide('confirmProgress');
            } else {
              BS.reload(true);
              completed.resolve();
            }
          }
        });
        return completed;
      }
    });

    return false;
  }
})(BS.Plugins);

BS.Plugins.UploadPluginDialog =  OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, OO.extend(BS.FileBrowse, {
  onFileChanged: function(filename) {
    if (BS.Plugins.OverwriteCandidates.indexOf(filename) >= 0) {
      BS.Util.show('overwriteWarning');
    } else {
      BS.Util.hide('overwriteWarning');
    }
  },

  getContainer: function () {
    return $('uploadPluginDialog');
  },

  formElement: function () {
    return $('uploadPluginForm');
  },

  refresh: function() {
    BS.reload(true);
  },

  savingIndicator: function() {
    return $j('#uploadingProgress');
  },

  /**
   * Will validate on server
   */
  validate: function() {
    this.setSaving(true);
    return true;
  },

  open: function() {
    BS.Util.hide('overwriteWarning');
    this.show();
    return false;
  }

})));

BS.Plugins.InstallPluginDialog =  OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  pluginsUrl: function() {
    return window["base_uri"] + "/admin/admin.html?item=plugins";
  },

  getContainer: function () {
    return $('installPluginDialog');
  },

  open: function(pluginId, updateId) {
    BS.Util.show('pluginInfoProgress');
    BS.Util.hide('installPluginInfo');
    this.showCentered();
    BS.Util.disableInputTemp($("installPluginDialogSubmit"));
    BS.ajaxRequest(window["base_uri"] + "/admin/plugins.html", {
      parameters: {pluginId: pluginId, updateId: updateId, action: "info"},
      onComplete: function (response) {
        var $info = $j(response.responseXML).find('pluginInfo');
        var error = $info.attr('error');
        if (error) {
          $j('#installPluginError').show().children('.jsErrorText').text(error);
        } else {
          var link = "<a href='" + $info.attr('viewUrl') + "' target='_blank' rel='noreferrer'>" + $info.attr('name') + "</a>";
          $j('#installPluginName').html(link);
          $j('#installPluginVersion').text($info.attr('version'));
          var description = $info.attr('description');
          if (description) {
            $j('#installPluginDescription').show().find('td').html(description);
          }
          var vendor = $info.attr('vendor');
          if (vendor) {
            $j('#installPluginVendor').show().find('td').html(vendor);
          }
          var warning = $info.attr('warning');
          if (warning) {
            $j('#installPluginWarning').text(warning).show();
          }
          BS.Util.reenableInput($("installPluginDialogSubmit"));
        }
        BS.Plugins.InstallPluginDialog.downloadUrl = $info.attr('downloadUrl');
        BS.Util.hide('pluginInfoProgress');
        BS.Util.show('installPluginInfo');
      }
    });
    return false;
  },

  install: function() {
    var downloadUrl = BS.Plugins.InstallPluginDialog.downloadUrl;
    if (!downloadUrl) {
      document.location.href = self.pluginsUrl();
      return false;
    }

    var self = this;
    BS.Util.show('installingProgress');
    BS.Util.disableInputTemp($("installPluginDialogSubmit"));
    BS.ajaxRequest(window["base_uri"] + "/admin/plugins.html", {
      parameters: {downloadUrl: downloadUrl, action: "installPlugin"},
      onComplete: function (response) {
        BS.Util.hide('installingProgress');
        BS.Util.reenableInput($("installPluginDialogSubmit"));
        var $info = $j(response.responseXML).find('installPlugin');
        var error = $info.attr('error');
        let isSignatureError = $info.attr('isSignatureError');
        if (error || isSignatureError) {
          if (isSignatureError) {
            error = 'TeamCity is not able to verify that the plugin is downloaded from JetBrains Marketplace and thus cannot install it. ' +
              'Each plugin published to JetBrains Marketplace is signed by the JetBrains Marketplace certificate, ' +
              'but the signature of this plugin is either missing or incorrect.';
          }
          $j('#installPluginError').show().children('.jsErrorText').text(error);
        } else {
          document.location.href = self.pluginsUrl();
        }
      }
    });
    return false;
  },

  afterClose: function () {
    document.location.href = this.pluginsUrl();
    return false;
  }

}));

