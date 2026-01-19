BS.ExportProjectDialog = {

  startExport: function (token) {
    if (this.disabled) return false;

    var cookieName = "exportProject" + token;
    var btn = $j('#startExportBtn');

    this.disable_btn = new BS.DelayedAction(function() {
      btn.attr("disabled", "disabled");
    }, function() {
      btn.removeAttr("disabled");
    });
    
    this.progress_saving = new BS.DelayedShow($('saving'));
    this.progress_saving.start();
    this.disable_btn.start();

    this.disabled = true;
   
    var that = this;
    this.exportInterval = setInterval(function() {
      if (BS.Cookie.get(cookieName)) {
        var fileName = BS.Cookie.get(cookieName);
        BS.Util.show('messageExported');
        $j('#downloadedArchiveName').text(fileName);
        BS.Cookie.remove(cookieName);
        that.progress_saving.stop();
        clearInterval(that.exportInterval);
        that.disabled = false;
        that.disable_btn.stop();
      }
    }, 200);
    return true;
  }
};
