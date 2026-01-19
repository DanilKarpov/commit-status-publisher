BS.Merge = OO.extend(BS.AbstractModalDialog, {

  branchesDropDownInitialized: false,

  getContainer: function() {
    return $('mergeSourcesFormDialog');
  },

  showEditDialog: function(buildId, branchName, noReload) {
    this.noReload = noReload;
    this._clearErrors();
    this._initBranchesDropDown();
    var form = document.getElementById('mergeSourcesForm');
    form.elements.mergeSourcesForBuild.value = buildId;
    this.showCentered();
    $('message').value = "Merge branch '" + branchName + "'";

    return new Promise(function (resolve, reject) {
      this._resolve = resolve;
      this._reject = reject;
    }.bind(this));
  },

  _initBranchesDropDown: function () {
    if (!this.branchesDropDownInitialized) {
      BS.enableJQueryDropDownFilter('dstBranch', '{}');
      this.branchesDropDownInitialized = true;
    }
  },

  _clearErrors: function() {
    $("error_dstBranch").innerHTML = '';
    $("error_message").innerHTML = '';
  },

  merge: function() {
    var f = $('mergeSourcesForm');
    Form.disable(f);
    BS.Util.show('mergingSources');
    BS.ajaxRequest(f.action, {
      parameters: BS.Util.serializeForm(f),
      onComplete: function(transport) {
        BS.Merge._clearErrors();
        var errors = BS.XMLResponse.processErrors(transport.responseXML, {
          onDstBranchError: function(elem) {
            $("error_dstBranch").innerHTML = elem.firstChild.nodeValue;
            BS.Util.hide('mergingSources');
            Form.enable(f);
          },

          onMessageError: function(elem) {
            $("error_message").innerHTML = elem.firstChild.nodeValue;
            BS.Util.hide('mergingSources');
            Form.enable(f);
          }
        });

        if (!errors) {
          BS.Util.hide('mergingSources');
          Form.enable(f);
          BS.Merge.close();
          if ($('buildLabels')) {
            $('buildLabels').refresh();
          }
        }
        if (!BS.Merge.noReload) {
          BS.reload(true);
        }
        if (BS.Merge._resolve != null) {
          BS.Merge._resolve();
        }
      }
    });
    return false;
  }
});
