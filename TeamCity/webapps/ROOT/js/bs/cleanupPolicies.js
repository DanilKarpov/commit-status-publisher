BS.CleanupDisableForm = OO.extend(BS.AbstractWebForm, {
  formElement: function() {
    return $('cleanupDisableForm');
  },

  setSaving: function(saving) {
    if (saving) {
      BS.Util.show('savingSettings');
    } else {
      BS.Util.hide('savingSettings');
    }
  },

  submit: function() {
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onCompleteSave: function(form, responseXML, err) {
        if (err) {
          form.enable();
          form.setSaving(false);
        }

        if (!err) {
          BS.reload(true);
        }
      }
    }));
    return false;
  }
});

BS.CleanupPoliciesForm = OO.extend(BS.AbstractWebForm, {
  formElement: function() {
    return $('cleanupTimeForm');
  },

  setSaving: function(saving) {
    if (saving) {
      BS.Util.show('savingSettings');
    } else {
      BS.Util.hide('savingSettings');
    }
  },

  startingCleanup: function(starting) {
    if (starting) {
      BS.Util.show('startingCleanup');
    } else {
      BS.Util.hide('startingCleanup');
    }
  },

  submitCleanupStartTime: function() {
    var that = this;
    $('cleanupPageAction0').value = 'storeSettings';

    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onSaveServerConfigError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },

      onWrongCronFieldMinError: function (elem) {
        $('cron_error_minutes').innerHTML = 'Illegal value';
      },

      onWrongCronFieldHourError: function (elem) {
        $('cron_error_hours').innerHTML = 'Illegal value';
      },

      onWrongCronFieldDmError: function (elem) {
        $('cron_error_dayOfMonth').innerHTML = 'Illegal value';
      },

      onWrongCronFieldMonthError: function (elem) {
        $('cron_error_month').innerHTML = 'Illegal value';
      },

      onWrongCronFieldDwError: function (elem) {
        $('cron_error_dayOfWeek').innerHTML = 'Illegal value';
      },

      onWrongCronFieldCommonError: function (elem) {
        $('cron_error_common').innerHTML = elem.firstChild.nodeValue;
      },

      onSaveCleanupTimeError: function(elem) {
        $('error_cleanupTime').innerHTML = elem.firstChild.nodeValue;
        that.highlightErrorField('hour');
        that.highlightErrorField('minute');
      },

      onCompleteSave: function(form, responseXML, err) {
        if (err) {
          form.enable();
          form.setSaving(false);
        }

        if (!err) {
          BS.reload(true);
        }
      }
    }));
    return false;
  },

  submitStartCleanup: function() {
    if (!confirm("This operation may require significant time, and the server will be less performant during the clean-up.\n" +
      "Are you sure you want to start clean-up process now?")) return false;

    $('cleanupPageAction0').value = 'startCleanup';

    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.SimpleListener, {
      onCannotStartCleanupError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },

      onBeginSave: function(form) {
        form.startingCleanup(true);
        form.disable();
      },

      onCompleteSave: function() {
        setTimeout(function() {
          BS.reload(true);
        }, 1500);
      }
    }));

    return false;
  },

  submitStopCleanup: function() {
    if (!confirm("Are you sure you want to stop clean-up process now?")) return false;

    this.formElement()['cleanupPageAction'].value = 'stopCleanup';
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.SimpleListener, {
      onBeginSave: function(form) {
        form.disable();
      },

      onCompleteSave: function() {
        BS.reload(true);
      }
    }));

    return false;
  }
});

BS.Cleanup = {
  updateOverallDiskUsage: function() {
    BS.ajaxRequest(window["base_uri"] + "/diskUsage.html", {
      method: "POST",
      parameters: {
        action: "getOverallData"
      },
      onComplete: function (transport) {
        if (transport.responseXML && transport.responseXML.firstChild) {
          var response = transport.responseXML.firstChild;
          var elements = response.getElementsByTagName("diskUsage");
          if (elements.length > 0) {
            var data = elements[0];
            var artFreeSpace = data.getElementsByTagName("totalArtifactsFreeSpace")[0].firstChild.nodeValue;
            var logsFreeSpace = data.getElementsByTagName("totalLogsFreeSpace")[0].firstChild.nodeValue;
            var artTotalSize = data.getElementsByTagName("totalArtifactsSize")[0].firstChild.nodeValue;
            var isUpdating = data.getElementsByTagName("totalArtifactsSize")[0].attributes["updating"].value === "true";
            var logsTotalSize = data.getElementsByTagName("totalLogsSize")[0].firstChild.nodeValue;

            var text;
            if (artFreeSpace == logsFreeSpace) {
              text = "Free space: <strong>" + artFreeSpace + "</strong>, ";
            } else {
              text = "Free space in artifacts directory: <strong>" + artFreeSpace + "</strong>, Free space in logs directory: <strong>" + logsFreeSpace + "</strong>, ";
            }
            text += "total artifacts" + (isUpdating ? " (updating)" : "") + ": <strong>" + artTotalSize + "</strong>, ";
            text += "total logs" + (isUpdating ? " (updating)" : "") + ": <strong>" + logsTotalSize + "</strong>.";
            $j("#freeSpaceHolder").html(text);
          }
        }
      }
    });
  }
};