BS.EditCheckoutRulesForm = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {

  setSaving: function(saving) {
    if (saving) {
      BS.Util.show('saveRulesProgress');
    } else {
      BS.Util.hide('saveRulesProgress');
    }
  },

  getContainer: function() {
    return $('editCheckoutRulesFormDialog');
  },

  formElement: function() {
    return $('editCheckoutRulesForm');
  },

  showDialog: function(vcsRootId, vcsRootName, checkoutRules, readOnly) {
    $('editCheckoutRulesFormTitle').innerHTML = (readOnly ? "View" : "Edit") + " Checkout Rules";
    if (readOnly) {
      BS.Util.hide('editCheckoutRulesFormSaveBlock');
      $('checkoutRules').readOnly = "readonly";
    } else {
      BS.Util.show('editCheckoutRulesFormSaveBlock');
      $('checkoutRules').readOnly = "";
    }

    this.formElement().vcsRootId.value = vcsRootId;
    this.formElement().checkoutRules.value = checkoutRules;
    $('vcsRootName').innerHTML = vcsRootName.escapeHTML().replace(/\//g, "/<wbr>");

    if (!readOnly) {
      this._attachVcsTreeControl();
    }

    this.showCentered();
    this.formElement().checkoutRules.focus();
    this.bindCtrlEnterHandler(this.submit.bind(this));

    BS.AvailableParams.attachPopups($('editableObjectId').value, 'buildTypeParams');
  },

  _attachVcsTreeControl: function() {
    var vcsRootId = this.formElement().vcsRootId.value;

    var treeControl = $('vcsTreeControl_vcsTree_' + vcsRootId);
    if (treeControl) {
      treeControl.parentNode.removeChild(treeControl);
      $('checkoutRulesVcsTree').appendChild(treeControl);
    }
  },

  _detachVcsTreeControl: function() {
    var vcsRootId = this.formElement().vcsRootId.value;

    var treeControl = $('vcsTreeControl_vcsTree_' + vcsRootId);
    if (treeControl) {
      treeControl.parentNode.removeChild(treeControl);
      $('vcsTreeSource_' + vcsRootId).appendChild(treeControl);
    }
  },

  cancelDialog: function() {
    this.close();
  },

  afterClose: function() {
    this.clearErrors();
    this._detachVcsTreeControl();
  },

  submit: function() {
    var that = this;

    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onInvalidCheckoutRuleError: function(elem) {
        $('errorCheckoutRules').innerHTML = elem.firstChild.nodeValue;
        that.highlightErrorField($('checkoutRules'));
      },

      onCompleteSave: function(form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);

        if (!err) {
          that.enable();
          that.close();
          BS.EditVcsRootsForm.update();
        }
      }
    }));

    return false;
  },

  insertRule: function(file, vcsTreeId, treeElement) {
    var includeRule = '+:' + file;
    var rules = $('checkoutRules').value;
    if (rules.indexOf(includeRule) == -1) {
      if (/=>\s*\./.test(rules)) {
        includeRule += ' => ' + file;
      } else {
        includeRule += ' => .';
      }

      var dotOccupied = rules.match();

      if (rules.length > 0) {
        rules = rules + '\n';
      }
      rules = rules + includeRule;
      $('checkoutRules').value = rules;
    }
  }
}));
