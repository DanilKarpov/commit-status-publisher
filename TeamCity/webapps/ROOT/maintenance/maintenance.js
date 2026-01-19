/**
 * Created by Leonid Bushuev from JetBrains.
 */

var BS = BS || {};

// See TW-23168.
$.ajaxSetup({
  cache: false
});

BS.Maintenance = {

  webPrefix: "",

  stateRevision: 0,

  pageName: '',

  activeStage: true,

  refreshStopped: false,

  scheduleCheckAndRefresh: function() {
    setTimeout("BS.Maintenance.checkAndRefresh()", 3000);
  },

  checkAndRefresh: function() {

    $.ajax(this.webPrefix + "/mnt/get/stateRevision", {
      dataType: 'json',
      statusCode: {
        302: function () {
          BS.Maintenance.refreshPage();
        }
      },
      success: function (data) {
        if (data.error) {
          BS.Maintenance.log(data.error, 'error');
        }
        else {
          var actualRevision = parseInt(data);
          if (actualRevision != BS.Maintenance.stateRevision && !BS.Maintenance.refreshStopped && BS.Maintenance.activeStage) {
            BS.Maintenance.refreshStopped = true;
            BS.Maintenance.refreshPage();
          }
        }
      },
      complete: function() {
        if (!BS.Maintenance.refreshStopped) {
          BS.Maintenance.scheduleCheckAndRefresh();
        }
      }
    });
  },


  postCommand: function(cmd, data) {
    $.ajax(this.webPrefix + "/mnt/do/" + cmd, {
      type: 'POST',
      data: data
    });
  },

  postCommandAndRefresh: function(cmd, data) {
    var commandUrl = this.webPrefix + "/mnt/do/" + cmd;
    $(":input").prop("disabled", true);

    $.ajax(commandUrl, {
      type: 'POST',
      data: data,
      success: function(ajaxResult) {
        if (ajaxResult == 'OK') {
          BS.Maintenance.refreshPage();
        }
        else {
          alert(ajaxResult);
          $(":input").prop("disabled", false);
        }
      },
      timeout: function() {
        alert("Timeout when communicating with TeamCity server");
        $(":input").prop("disabled", false);
      }
    });
  },


  saveRedirectedFromAndGoToMaintenance: function() {
    var currLocation = window.location.href;
    $.ajax(BS.Maintenance.webPrefix + '/mnt/do/saveRedirectedFrom', {
      type: 'POST',
      data: {
        origURL: currLocation
      },
      success: function(ajaxResult) {
        window.location = BS.Maintenance.webPrefix + '/mnt';
      },
      error: function(xhr, status, error) { },
      timeout: function() { }
    });
  },


  refreshPage: function() {
    window.location.reload(true);
  },


  log: function(msg, level) {
    var wc = window.console;
    if (wc && wc[level]) {
      wc[level](msg);
      if (msg.stack) {
        wc[level](msg.stack);
      }
    }
  }

};
