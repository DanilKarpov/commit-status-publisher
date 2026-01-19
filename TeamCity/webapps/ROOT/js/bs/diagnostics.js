BS.Log4Config = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, OO.extend(BS.FileBrowse, {
  getContainer: function() {
    return $('addLog4jConfig');
  },

  formElement: function() {
    return $('addLog4jConfigForm');
  },

  refresh: function() {
    $("log4jConfig").refresh();
  }
})));
