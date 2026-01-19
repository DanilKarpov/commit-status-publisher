BS.LicensesForm = {

  showEmptyForm: function() {
    BS.Util.show("licensesForm");
    $("licenseKeys").focus();
    $("newLicense").hide();
    BS.LicensesForm.clearMessages();
  },

  hideEmptyForm: function() {
    BS.Util.hide("licensesForm");
    $("licenseKeys").value = '';
    $("newLicense").show();
    BS.LicensesForm.clearMessages();
  },

  clearMessages: function() {
    $("verificationStatus").innerHTML = "";
    $j("#message_licenseKeyRemoved").hide();
    $j("#message_licenseKeysAdded").hide();
  },

  submitLicenses: function() {
    this.clearMessages();
    var that = this;
    var form = $("licensesForm");
    Form.disable(form);
    $("submitKeys").value = "Save";

    BS.ajaxRequest(form.action, {
      method: "post",

      parameters: BS.Util.serializeForm(form),

      onComplete: function(transport) {
        try {
          var doc = transport.responseXML;

          var verificationResult = doc.getElementsByTagName("verificationResult")[0];
          if (verificationResult) {
            var html = "<table class='verificationResults' width='100%'>";
            var licenses = verificationResult.getElementsByTagName("licenseKey");
            var invalid = false;
            if (licenses.length > 0) {
              for (var i=0; i<licenses.length; i++) {
                var key = licenses[i].getElementsByTagName("key")[0].firstChild.nodeValue;
                var valid = "true" == licenses[i].getAttribute("valid");
                html += "<tr><td valign='top' width='50%'>" + key + ":</td>";
                if (valid) {
                  html += "<td valign='top'><span class='validKey'>License key added</span>";
                } else {
                  invalid = true;
                  var reason = licenses[i].getElementsByTagName("invalidReason")[0].firstChild.nodeValue;
                  html += "<td valign='top'><span class='invalidKey'>" + reason + "</span></td>";
                }
              }

              var selected = $j("input:checkbox:checked");
              $('licensePage').refresh({licenseKeys: $("licenseKeys").value}, "enterKeys=true", function() {
                if (invalid) {
                  $("verificationStatus").innerHTML = html;
                  var added = verificationResult.getElementsByTagName("addedLicenseKeys");
                  if (added.length > 0) {
                    var message = $("message_licenseKeysAdded");
                    message.innerHTML = added[0].firstChild.nodeValue;
                    message.show();
                  }
                } else {
                  BS.LicensesForm.hideEmptyForm();
                }
                selected.each(function() {
                  $j("input#" + this.id + "[value='" + this.value + "']").attr("checked", "true");
                });
              });
            } else {
              var noLicensesMessage = verificationResult.getElementsByTagName("noLicensesFound");
              if (noLicensesMessage.length > 0) {
                $("verificationStatus").innerHTML = "<tr><td>" + noLicensesMessage[0].firstChild.nodeValue + "</td></tr>";
              }
            }
          }

          that.handleErrors(doc);

          Form.enable(form);
          $("licenseKeys").focus();
        } catch(ex) {
          BS.reload(true);
        }
      },

      onException: function(obj, e) {
        BS.Util.processError(e);
      },

      onFailure: function() {
        alert("Error accessing server");
      }
    })
  },

  removeLicenseKeys: function(keys) {
    if (keys == null || keys.length == 0) {
      alert("Please select at least one license.");
      return;
    }

    var that = this;

    BS.confirm("Are you sure you want to remove selected license keys?", function () {
      var keysComposed = keys.join(":");

      BS.ajaxRequest('licenses.html', {
        parameters: "removeKey=" + keysComposed,
        onComplete: function(transport) {
          if (that.handleErrors(transport.responseXML)) return;

          var textArea = $('licenseKeys');
          var data = null;
          if (textArea) {
            data = textArea.value;
          }
          BS.LocationHash.replaceHash("");
          $('licensePage').refresh(null, $j("#licensesForm").is(":visible") ? "enterKeys=true" : "", function() {
            if (data != null) {
              $('licenseKeys').value = data;
            }
          });
        }
      })
    });
  },

  handleErrors: function(responseXml) {
    return BS.XMLResponse.processErrors(responseXml, {
      "licenseKeysError": function(elem) {
        var txt = elem.firstChild.nodeValue;
        $j('div.error').text(txt);
      }
    });
  },

  toggleIncompatibleWith: function(notCompatibleWith) {
    var all = $j('#availableLicensesList tr');
    BS.Util.show(all);
    all.find(":checkbox").prop('disabled', false).prop('checked', false);
    if (notCompatibleWith) {
      var hidden = $j('#availableLicensesList tr').not(':first').not('.notCompatibleWith_' + notCompatibleWith);
      hidden.find(":checkbox").prop('disabled', true);
      BS.Util.hide(hidden);
      BS.LocationHash.setHash("notCompatibleWith=" + notCompatibleWith);
    } else {
      BS.LocationHash.replaceHash("");
    }
  },

  initFromHash: function() {
    var notCompatibleWith = BS.LocationHash.getHashParameter("notCompatibleWith");
    if (notCompatibleWith) {
      $j('#notCompatibleWithMode_' + notCompatibleWith).prop('checked', true);
      this.toggleIncompatibleWith(notCompatibleWith);
    }
  },

  togglePerUsageDataPreview: function() {
    $j('#perUsageCollectedData').toggle();
  },

  initPerUsage: function() {
    $j("#perUsageSentFailedDetailsToggle").on("click", function() {
      $j('#perUsageSentFailedDetails').toggle();
    });
    $j("#perUsageCollectedDataToggle").on("click", function() {
      $j('#perUsageCollectedData').toggle();
    });
  }
};
