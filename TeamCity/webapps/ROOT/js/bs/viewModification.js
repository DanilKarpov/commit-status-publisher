BS.buildTypeIdChanged = function(select) {
  var parameters = select.options[select.selectedIndex].value;
  $('viewModificationContainerId').refresh('changeBuildTypeProgress', parameters);
};


BS.EditModificationDescriptionDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  formElement: function() {
    return $('editModificationForm');
  },

  getContainer: function() {
    return $('editModificationFormDialog');
  },

  showDialog: function() {
    this.showAtFixed($(this.getContainer()));
    $(this.formElement().modificationDescription).activate();
    this.bindCtrlEnterHandler(this.submit.bind(this));
  },

  submit: function() {
    BS.FormSaver.save(BS.EditModificationDescriptionDialog, BS.EditModificationDescriptionDialog.formElement().action, OO.extend(BS.ErrorsAwareListener, {

      onCompleteSave: function(form, responseXML, err) {
        BS.reload(true);
      },

      onFailure: function() {
        alert("Problem accessing server");
      }
    }));

    return false;
  }
}));


$j(function() {
  var failedTestsSection = $('failedTestsSection');
  if (failedTestsSection) {
    BS.PeriodicalRefresh.start(15, function() {
      return failedTestsSection.refresh(null, '');
    });
  }
});
