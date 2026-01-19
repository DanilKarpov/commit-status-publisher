BS.IssueLog = OO.extend(BS.AbstractWebForm, {
  formElement: function() {
    return $('issueLogFilter');
  },

  submitFilter: function(reset) {
    if (reset) {
      $j("#from, #to").val("");
    }

    var that = this;
    this.setSaving(true);
    this.disable();
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.SimpleListener, {
      onCompleteSave: function() {
        $('issueLogTable').refresh(that.savingIndicator(), null, function() {
          that.enable();
          that.setSaving(false);
        });
      }
    }));

    return false;
  }
});
