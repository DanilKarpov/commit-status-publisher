BS.TeamCityUpdater = {

  refreshers: {},

  checkForUpdates: function() {
    $('checkForUpdatesProgress').show();
    $j('#checkForUpdatesBtn').attr("disabled", "disabled");

    var that = this;
    BS.ajaxRequest(window["base_uri"] + "/admin/update.html", {
      method: 'post',
      parameters: {checkForUpdates: 1},
      onComplete: function () {
        for (var refresher in that.refreshers) {
          if (that.refreshers.hasOwnProperty(refresher)) {
            clearTimeout(that.refreshers[refresher]);
          }
        }
        that._updateOptionsList();
        $('checkForUpdatesProgress').hide();
        $j('#checkForUpdatesBtn').removeAttr("disabled");
      }
    });
    return false;
  },

  _updateOptionsList: function () {
    $('updateOptionsList').refresh();
  },

  prepareForUpdate: function (version) {
    $j(BS.Util.escapeId('prepareBtn_' + version)).attr("disabled", "disabled");
    $j(BS.Util.escapeId('prepareBtnProgress_' + version)).show();

    BS.ajaxRequest(window["base_uri"] + "/admin/update.html", {
      method: 'post',
      parameters: {prepare: 1, version: version},
      onComplete: function () {
        $('updateState_' + version).refresh();
        $j(BS.Util.escapeId('prepareBtnProgress_' + version)).hide();
        $j(BS.Util.escapeId('prepareBtn_' + version)).removeAttr("disabled");
      }
    });
    return false;
  },

  openUpdateDialog: function (version, fullVersion, helpLink) {
    BS.RestartDialog.show(
        {
          url: window["base_uri"] + "/admin/update.html",
          parameters: {start: 1, version: version},

          title: "Update to TeamCity " + fullVersion,

          text: "<div>" +
                  "The server will be stopped and the script will be run to update the installation to the new version, then the updated server will start. " + helpLink +
                  "<p>The update process will be logged to the teamcity-update.log file.</p>" +
                  "<p>Proceed?</p>" +
                "</div>",

          inProgressText: 'TeamCity is updating, the page will be reloaded when the updated server starts.',

          submitButtonText: "Update",

          timeoutSeconds: internalProps['teamcity.ui.serverUpdate.warningDelay'],

          getTimeoutMessage: function() {
            if (BS.ServerLink.isConnectionAvailable()) {
              return "Server didn't stop in " + internalProps['teamcity.ui.serverUpdate.warningDelay'] + " seconds, see logs/teamcity-server.log for details.";
            } else {
              return "Server was stopped to update, but didn't start in " + internalProps['teamcity.ui.serverUpdate.warningDelay'] + " seconds, see logs/teamcity-update.log for details.";
            }
          }
        });
    return false;
  },

  scheduleRefresh: function (version) {
    var timeout = window.setTimeout(function () {
      $('updateState_' + version).refresh();
    }, 3000);
    this.refreshers[version] = timeout;
  },

  saveSecurityPatchesMode: function(checkbox){
    $('saveSecurityPatchesMode').show();
    $j(checkbox).attr("disabled", "disabled");

    const that = this;
    BS.ajaxRequest(window["base_uri"] + "/admin/update.html", {
      method: 'post',
      parameters: {securityPatchesMode: checkbox.checked ? 'NOTIFY' : 'IGNORE'},
      onComplete: function () {
        $('saveSecurityPatchesMode').hide();
        $j(checkbox).removeAttr("disabled");
        that._updateOptionsList();
      }
    });

    return false;
  },

  downloadPlugins: function(button) {

    const that = this;
    $j(button).attr("disabled", "disabled");
    BS.ajaxRequest(window["base_uri"] + "/admin/update.html", {
      method: 'post',
      parameters: { downloadSecurityUpdates: "1" },
      onComplete: function () {
        $j(button).removeAttr("disabled");
        that._delayedUpdateOptionsList();
      }
    });
  },

  _delayedUpdateOptionsList: function () {
    const that = this;
    setTimeout(() => that._updateOptionsList(), 3000);
  },

  installDownloadedPlugin: function(pluginName) {

    const progressId = "progressInstall_" + pluginName;

    $(progressId).show();
    const that = this;

    BS.confirmDialog.show({
      title: "Update Installation",
      text: 'Install security update without server restart?',
      actionButtonText:  "Install",
      cancelButtonText: 'Cancel',

      action: () => {
        BS.ajaxRequest(window["base_uri"] + "/admin/update.html", {
          method: 'post',
          parameters: { installSecurityPatch: pluginName },
          onComplete: function (transport) {
            const responseXmlElement = transport?.responseXML?.documentElement;
            $(progressId).hide();

            if (responseXmlElement && responseXmlElement.querySelector("error")) {
              if ($('error_plugin_install')) {
                $('error_plugin_install').innerText = responseXmlElement.querySelector("error").innerHTML;
              }
            }
            else {
              that._delayedUpdateOptionsList();
            }
          }
        });

        $(progressId).hide();
      },
      cancelAction: () => {
        $(progressId).hide();
      }
    });
  }
};
