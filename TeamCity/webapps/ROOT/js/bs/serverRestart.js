BS.ServerRestarter = {

  restartServer: function () {
    BS.RestartDialog.show(window["base_uri"] + "/admin/serverRestart.html", {start: 1});
    return false;
  }
};

BS.RestartDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {

  formElement: function () {
    return $('restartServerForm');
  },

  getContainer: function () {
    return $('restartServerFormDialog');
  },

  enableDialog: function() {
    this.enable();
    BS.Util.show("restartCancelButton");
  },

  disableDialog: function() {
    this.disable();
    BS.Util.hide("restartCancelButton");
  },

  show: function (options) {
    this.options = OO.extend({
                               url: window["base_uri"] + "/admin/serverRestart.html",
                               parameters: {start: 1},
                               text: 'The TeamCity server will be restarted, which may take some time.',
                               title: 'Restart TeamCity Server',
                               inProgressText: 'TeamCity is restarting, the page will be reloaded when the server starts.',
                               submitButtonText: 'Restart',
                               timeoutSeconds: internalProps['teamcity.ui.serverRestart.warningDelay'],
                               getTimeoutMessage: function() {
                                 if (BS.ServerLink.isConnectionAvailable()) {
                                   return "Server didn't stop in " + internalProps['teamcity.ui.serverRestart.warningDelay'] + " seconds, see logs/teamcity-server.log for details.";
                                 } else {
                                   return "Server was stopped, but didn't start in " + internalProps['teamcity.ui.serverRestart.warningDelay'] + " seconds, see logs/teamcity-wrapper.log for details.";
                                 }
                               }
                             }, options || {});


    BS.Util.hide('restartStarted');
    BS.Util.hide('restartError');
    BS.Util.hide('restartTooLongWarning');

    $j(this.getContainer()).find('.restartDialog__content').html(this.options.text);
    $j(this.getContainer()).find('.restartStartedText').html(this.options.inProgressText);
    $j(this.getContainer()).find('.submitButton').val(this.options.submitButtonText);
    $j(this.getContainer()).find('.dialogTitle').text(this.options.title);

    this.disableDialog();

    this._hostnameConfirm = BS.HostnameConfirm(
      this.getContainer().querySelector(".restartDialog__hostnameConfirmation"),
      this.enableDialog.bind(this));

    this.showCentered();
  },

  afterClose: function() {
    this._hostnameConfirm.dispose();
  },

  showInProgress: function () {
    BS.Util.show('restartStarted');
    BS.Util.hide('restartError');
    BS.Util.hide('restartTooLongWarning');
  },

  displayError: function (msg) {
    $j(this.getContainer()).find('#restartError').text(msg);
    BS.Log.info(msg);
    BS.Util.hide('restartStarted');
    BS.Util.show('restartError');
    this.enableDialog();
  },

  submitAndWatchProgress: function (url, options) {
    BS.Util.show('restartDialogSavingProgress');
    this.disableDialog();

    var that = this;

    options.onComplete = function (transport) {
      if (!BS.XMLResponse.processRedirect(transport.responseXML)) {
        BS.Util.hide('restartDialogSavingProgress');
        if (!BS.Util.documentRoot(transport)) {
          BS.RestartDialog.displayError("Failed to submit: unexpected response");

        } else if (!BS.Util.documentRoot(transport).getElementsByTagName('result')) {
          BS.RestartDialog.displayError("Failed to submit: unexpected response");

        } else if (BS.Util.documentRoot(transport).getElementsByTagName('result')[0].getAttribute("error")) {
          BS.RestartDialog.displayError(BS.Util.documentRoot(transport).getElementsByTagName('result')[0].getAttribute("error"));

        } else {
          that.showInProgress();
          BS.ServerUnavailableModalDialog.disable();
          BS.ServerLink.subscribeOnMaintenanceMode(function () {
            BS.Log.info("Server restarted - reload the page");
            BS.reload(true);
          });

          var failedToRestart = false;
          var timeout = setTimeout(function () {
            if (!failedToRestart) {
              var msg = that.options.getTimeoutMessage();
              $j(BS.RestartDialog.getContainer()).find('#restartTooLongWarning').html(msg);
              BS.Log.info(msg);
              BS.Util.show('restartTooLongWarning');
            }
          }, 1000 * that.options.timeoutSeconds);

          var progressTracker = new BS.PeriodicalUpdater(null, url + "?getProgress=1", {
            frequency: 1,
            evalScripts: false,
            method: 'post',
            onSuccess: function (transport) {
              if (!BS.Util.documentRoot(transport)) {
                BS.RestartDialog.displayError("Failed to submit: unexpected response");

              } else if (!BS.Util.documentRoot(transport).getElementsByTagName('result')) {
                BS.RestartDialog.displayError("Failed to submit: unexpected response");

              } else if (BS.Util.documentRoot(transport).getElementsByTagName('result')[0].getAttribute("error")) {
                BS.RestartDialog.displayError(BS.Util.documentRoot(transport).getElementsByTagName('result')[0].getAttribute("error"));
                BS.ServerUnavailableModalDialog.enable();
                BS.ServerLink.unsubscribeOnMaintenanceMode();
                progressTracker.stop();
                failedToRestart = true;
                clearTimeout(timeout);

              } else if (BS.Util.documentRoot(transport).getElementsByTagName('result')[0].getAttribute("done") === "true") {
                progressTracker.stop();
              }
            }
          });
        }
      }
    };

    BS.ajaxRequest(url, options);
  },

  submit: function () {
    this.submitAndWatchProgress(this.options.url, {
      parameters: this.options.parameters,
      method: 'post'
    });
    return false;
  }
}));
