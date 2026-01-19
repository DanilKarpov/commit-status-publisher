
BS.ProxyChecker = {

  check: function() {
    BS.ajaxRequest(window['base_uri'] + '/proxyCheck.html', {
      method: 'post',
      parameters : {
        browserLocationHost : window.location.host
      },
      evalScripts: true
    });
  },

  checkAndLoadResult: function(progressContainer, resultContainer) {
    BS.Util.show(progressContainer);
    BS.ajaxUpdater(resultContainer, window['base_uri'] + '/proxyCheck.html', {
      method: 'post',
      parameters : {
        browserLocationHost : window.location.host
      },
      evalScripts: true,
      onComplete: function() {
        BS.Util.hide(progressContainer);
      }
    });
  }
};