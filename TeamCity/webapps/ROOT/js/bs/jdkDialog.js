BS.AddJdkDialog = OO.extend(BS.AbstractModalDialog, {
  aThis: null,

  getContainer: function () {
    return $('AddJdkDialogFormDialog');
  },

  formElement: function () {
    return $('AddJdkDialogForm');
  },

  showDialog: function (caption, submitCaption, runningCount) {
    this.showCentered();
    this.bindCtrlEnterHandler(this.submit.bind(this));
  },

  beforeShow: function () {
    $j("#jdkUrl").val('');
    $j("#error_jdkUrl").empty();
  },

  refreshContainer: function () {
    return $('includedJdks').refresh();
  },

  scheduleRefresh: function () {
    window.setTimeout(() => {
      this.refreshContainer();
    }, 3000);
  },

  submitJdk: function (osValue, archValue, urlValue, that, restPath) {
    let url = window['base_uri'] + restPath;
    BS.ajaxRequest(url, {
      method: 'post',
      evalScripts: true,
      parameters: {
        action: 'addJdk',
        os: osValue,
        arch: archValue,
        url: encodeURI(btoa(urlValue))
      },
      onComplete: (response) => {
        let $errors = response.responseXML.documentElement.getElementsByTagName("error");
        if (!!$errors.length) {
          $j.each($errors, function (i, error) {
            var $error = $j(error);
            $("error_jdkUrl").innerHTML = $error.text().escapeHTML();
          });
        } else {
          that.close();
          this.refreshContainer();
        }
      }
    });
  },

  submit: function (restPath) {
    var that = this;

    const osValue = $j('#jdkOS').val();
    const archValue = $j('#jdkArch').val();
    const urlValue = $j('#jdkUrl').val();

    let alreadyExists = $j('#addedJdkList tr > td:contains(' + osValue + ') + td:contains(' + archValue + ')').length > 0;

    if (alreadyExists) {
      BS.confirm("Adding this JDK bundle will override existing " + osValue + " (" + archValue + ") bundle. Do you want to proceed?",
        () => this.submitJdk(osValue, archValue, urlValue, that, restPath)
      );
      return false;
    } else {
      this.submitJdk(osValue, archValue, urlValue, that, restPath);
      return false;
    }
  },

  removeJdk: function (os, arch, restPath) {
    BS.confirm("Are you sure you want to delete this JDK bundle?", () => {
      let url = window['base_uri'] + restPath;
      BS.ajaxRequest(url, {
        method: 'post',
        evalScripts: true,
        parameters: {
          action: 'removeJdk',
          os: os,
          arch: arch
        },
        onComplete: () => {
          this.refreshContainer();
        }
      });
      return false;
    });
  }
});