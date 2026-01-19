BS.AuditLogFilterForm = OO.extend(BS.AbstractWebForm, {
  formElement: function() {
    return $('auditLogFilterForm');
  },

  submit: function() {
    BS.AuditLogFilterForm.doSubmit(false);
  },

  clearFilter: function() {
    BS.AuditLogFilterForm.doSubmit(true);
  },

  doSubmit: function(reset) {
    $("reset").value = reset;

    BS.Util.hide("reset_link");
    BS.Util.show("auditLogFilterApplyingProgressIcon");

    BS.FormSaver.save(BS.AuditLogFilterForm, BS.AuditLogFilterForm.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onCompleteSave: function(form, responseXML, err) {
        if (!err && $("auditLogContainer") != null) {
          $("auditLogContainer").refresh("", "", function() {
            BS.Util.hide("auditLogFilterApplyingProgressIcon");
            BS.Util.show("reset_link");
            form.enable();
          });
        }
        else {
          BS.Util.hide("auditLogFilterApplyingProgressIcon");
          BS.Util.show("reset_link");
          form.enable();
        }
      },

      onFailure: function() {
        BS.Util.hide("auditLogFilterApplyingProgressIcon");
        BS.Util.show("reset_link");
        alert("Problem accessing server");
      }
    }));
  }
});
