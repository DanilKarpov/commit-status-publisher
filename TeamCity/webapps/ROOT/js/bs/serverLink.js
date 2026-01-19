BS.ServerUnavailableModalDialog = OO.extend(BS.AbstractModalDialog, {
  zIndex: 1000,
  _wasClosed: false,
  _disabled: false,

  _getCurrentDate: function() {
    var current = new Date();
    var h = (current.getHours() < 10) ? ("0" + current.getHours()) : current.getHours();
    var m = (current.getMinutes() < 10) ? ("0" + current.getMinutes()) : current.getMinutes();
    return $j.datepicker.formatDate("dd M yy", current) + " " + h + ":" + m;
  },

  getContainer: function() {
    return $('shutdownDialog');
  },

  available: function() {
    return $('shutdownDialog');
  },

  displayShutdownNote: function() {
    if (this._shutdownNoteIsDisplayed || this._wasClosed || this._disabled || !$('shutdownDialog')) return;

    this._shutdownNoteIsDisplayed = true;
    BS.Util.hide('onCommunicationFailure');
    BS.Util.hide('onAuthFailure');
    BS.Util.show('onServerShutdown');
    $('shutdownDetails').innerHTML = "Server is unavailable since " + this._getCurrentDate();
    this.showCentered();
  },

  displayFailureNote: function() {
    if (this._failureNoteIsDisplayed || this._wasClosed || this._disabled || !$('shutdownDialog')) return;

    this._failureNoteIsDisplayed = true;
    BS.Util.hide('onServerShutdown');
    BS.Util.hide('onAuthFailure');
    BS.Util.show('onCommunicationFailure');
    $('shutdownDetails').innerHTML = "Server is unavailable since " + this._getCurrentDate();
    this.showCentered();
  },

  displayAuthFailureNote: function() {
    if (this._authFailureNoteIsDisplayed || this._wasClosed || this._disabled || !$('shutdownDialog')) return;

    this._authFailureNoteIsDisplayed = true;
    BS.Util.hide('onServerShutdown');
    BS.Util.hide('onCommunicationFailure');
    BS.Util.show('onAuthFailure');
    $('shutdownDetails').innerHTML = "You are logged out since " + this._getCurrentDate();
    this.showCentered();
  },

  afterClose: function() {
    //we are using afterClose instead of overriding close() function because close() is not invoked when dialog is closed by ESC keypress.
    this._wasClosed = true;
  },

  reset: function() {
    this._wasClosed = false;
    this._shutdownNoteIsDisplayed = false;
    this._failureNoteIsDisplayed = false;
    this._authFailureNoteIsDisplayed = false;
  },

  disable: function() {
    this._disabled = true;
  },

  enable: function() {
    this._disabled = false;
  }
});

BS.ServerLink = OO.extend(BS.AbstractModalDialog, {
  _shutdown: false,
  _failuresNum: 0,
  _authFailureNums: 0,
  _onMaintenanceMode: null,

  /**
   * We don't want to reload all pages at the same time and immediately after server start,
   * because it just increases server load without any effect - pages will not be returned until jsp are compiled.
   */

  _scheduleReloadAfterServerRestart: function (messagePrefix) {
    if (!this._reloadTimeout)  {

      //reload after 30-90 seconds
      var reloadTimeoutInSeconds = Math.floor((Math.random() * 60) + 30);
      BS.Log.info(messagePrefix + ", page will be reloaded in " + reloadTimeoutInSeconds + " seconds.");

      this._reloadTimeout = setTimeout(function() {
        BS.reload(true);
      }, reloadTimeoutInSeconds * 1000)
    }
  },

  _onFailure: function() {
    if (++this._failuresNum > 1) { //don't show it immediately, only after second failure
      if (this._shutdown) {
        BS.ServerUnavailableModalDialog.displayShutdownNote();
      } else {
        BS.ServerUnavailableModalDialog.displayFailureNote();
      }
    }
  },

  _onAuthFailure: function() {
    this._authFailureNums++;

    if (this._authFailureNums > 3) {
      BS.ServerUnavailableModalDialog.displayAuthFailureNote();
    }

    // In case of hub plugin we can try to authenticate by navigating user to the some page in a hidden iframe:
    // user will be redirected to hub and then back to teamcity if authenticated.
    // After it user session will become authenticated and the following ajax request will be successful.
    if (!this._tryToAuthenticateIframe) {
      BS.Log.info('Opening iframe');
      this._tryToAuthenticateIframe = document.createElement("iframe");
      this._tryToAuthenticateIframe.setAttribute("src", window['base_uri'] + "/authenticationTest.html");
      this._tryToAuthenticateIframe.setAttribute("style", "width:0;height:0;border:0; border:none; visibility:hidden; position:absolute");
      document.body.appendChild(this._tryToAuthenticateIframe);
    } else {
      if (this._authFailureNums % 5 === 0) {
        //if we tried to authenticate using iframe more than 5 iterations before - then close the frame and try again on next iteration.
        document.body.removeChild(this._tryToAuthenticateIframe);
        this._tryToAuthenticateIframe = null;
      }
    }
  },

  _onSuccess: function() {
    this._shutdown = false;
    this._failuresNum = 0;
    this._authFailureNums = 0;
    BS.Log.info("The server is available again");

    if (this._tryToAuthenticateIframe) {
      document.body.removeChild(this._tryToAuthenticateIframe);
      this._tryToAuthenticateIframe = null;

      // After re-authentication via a hidden frame, we need to refresh CSRF token on the current page
      BS.CSRF.refreshCSRFToken();
    }

    if (BS.ServerUnavailableModalDialog.available()) {
      BS.Log.info("Closing 'Server Unavailable' dialog");
      BS.ServerUnavailableModalDialog.close();
      BS.ServerUnavailableModalDialog.reset();
    }
  },

  onShutdown: function() {
    this._shutdown = true;
  },

  isConnectionAvailable: function() {
    return this._failuresNum == 0 && this._authFailureNums == 0
  },

  getTotalFailuresNum: function() {
    return this._failuresNum + this._authFailureNums
  },

  subscribeOnMaintenanceMode: function (onMaintenance) {
    this._onMaintenanceMode = onMaintenance;
  },

  unsubscribeOnMaintenanceMode: function () {
    this._onMaintenanceMode = null;
  },

  waitUntilServerIsAvailable: function (callback) {

    var that = this;

    var poller = BS.periodicalExecutor(function () {
      var deferred = $j.Deferred();
      that.getServerInfo(function(response) {
        if (response.status == 200) {

          var serverElement = response.responseXML.documentElement;

          if (!serverElement) {
            BS.Log.error("Successful connection from the server with unknown version");
            deferred.resolve();
            return;
          }

          var buildNumber = serverElement.getAttribute("buildNumber");
          var startTime = serverElement.getAttribute("startTime");

          if (buildNumber != that._buildNumber) {
            poller.stop();
            return;
          }

          if (startTime != that._serverStartTime) {
            BS.Log.info("Server was restarted (" + that._serverStartTime + " -> " + startTime + ")");
            BS.CSRF.refreshCSRFToken();
          }

          that._onSuccess();

          poller.stop();
          callback();

        } else {
          if ((response.status == 503 || response.status == 502) && that._onMaintenanceMode) {
            that._onMaintenanceMode();
          }
          if (response.status == 401) {
            that._onAuthFailure();
          } else {
            that._onFailure();
          }

          deferred.resolve();
        }
      });
      return deferred;
    }, BS.internalProperty('teamcity.ui.serverAvailability.pollInterval') * 1000);

    setTimeout(poller.start.bind(poller), BS.internalProperty('teamcity.ui.serverAvailability.pollInterval') * 1000);
  },

  getServerInfo: function (onComplete) {
    BS.ajaxRequest(window['base_uri'] + '/app/rest/ui/server?fields=startTime,buildNumber', {
      method: 'GET',
      onComplete: function(response) {
        if (response.status == 200) {
          var serverElement = response.responseXML.documentElement;

          if (!serverElement) {
            return;
          }

          var buildNumber = serverElement.getAttribute("buildNumber");

          if (BS.ServerLink._buildNumber != null && buildNumber != BS.ServerLink._buildNumber) {
            BS.ServerLink._scheduleReloadAfterServerRestart("Server was upgraded (" + BS.ServerLink._buildNumber + " -> " + buildNumber + ")");
            if (window.ReactUI) {
              window.ReactUI.requestSWUpdate()
            }
          }
        }
        if (onComplete != null) {
          onComplete(response);
        }
      }
    });
  },

  init: function () {
    var that = this;
    this.getServerInfo(function (response) {
      if (response.status == 200 && response.responseXML) {
        var serverElement = response.responseXML.documentElement;
        that._buildNumber = serverElement.getAttribute("buildNumber");
        that._serverStartTime = serverElement.getAttribute("startTime");
        BS.Log.info("Server version: " + response.responseText)
      }
    });
  }
});

$j(document).ready(function() {
  /* Request server info once in 25 minutes to keep user authorized */
  setInterval(BS.ServerLink.getServerInfo, 25 * 60 * 1000);
  BS.ServerLink.init();
});
