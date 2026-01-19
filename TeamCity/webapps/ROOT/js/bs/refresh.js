(function() {
  function _pageid() {
    var l = document.location;
    return BS.Crypto.hex_md5((l.href.substring(l.href.lastIndexOf('/') + 1) + l.search).replace(/[?=&\.]/g, ""));
  }

  function rememberScrolling() {
    var scrollPos = $j(window).scrollTop();
    var cookieName = "sp" + _pageid();
    if (scrollPos > 0) {
      BS.Cookie.set(cookieName, scrollPos, 1.0/24);
    } else {
      BS.Cookie.remove(cookieName);
    }
  }

  function restoreScrolling() {
    setTimeout(function() {
      var pos = BS.Cookie.get("sp" + _pageid());
      if (pos != null) {
        window.scrollTo(0, pos);
      }
    }, 20);
  }

  // Export
  window.rememberScrolling = rememberScrolling;
  window.restoreScrolling = restoreScrolling;
})();

