/*
 * Copyright (c) 2006, JetBrains, s.r.o. All Rights Reserved.
 */

BS.Label = OO.extend(BS.AbstractModalDialog, {

  getContainer: function() {
    return $('setLabelFormDialog');
  },

  showEditDialog: function(buildId) {
    var form = $('setLabelForm');
    form.elements.setLabelForBuild.value = buildId;
    this.showCentered();
    $('labelName').focus();

    this.bindCtrlEnterHandler(this.setLabel.bind(this));
  },

  setLabel: function() {
    var f = $('setLabelForm');

    var checkboxes = Form.getInputs(f, "checkbox");
    var checked = false;
    for (var i=0; i<checkboxes.length; i++) {
      if (checkboxes[i].name.indexOf('labelingRootsManual[') != -1) {
        if (checkboxes[i].checked) {
          checked = true;
          break;
        }
      }
    }

    if (!checked) {
      alert("Please choose at least one VCS root to label.");
      return false;
    }

    Form.disable(f);
    BS.Util.show('setLabel');
    BS.ajaxRequest(f.action, {
      parameters: BS.Util.serializeForm(f),
      onComplete: function(transport) {
        BS.Util.hide('setLabel');
        Form.enable(f);
        BS.Label.close();
        if ($('buildLabels')) {
          $('buildLabels').refresh();
        }
        let response = transport["responseText"].stripTags().escapeHTML();
        if (transport["status"] >= 200 && transport["status"] <= 299) {
          TeamCityAPI.Services.AlertService.addAlert(response, "success")
        } else {
          TeamCityAPI.Services.AlertService.addAlert(response, "error")
        }
      }
    });

    return false;
  }
});
