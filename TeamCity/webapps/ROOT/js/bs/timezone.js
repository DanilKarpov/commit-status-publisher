(function() {
  var tz;
  if (window.Intl != null) {
    tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
  }

  var cd = new Date().toString();
  if (tz == null) {
    var pos = cd.indexOf('GMT');
    if (pos == -1) {
      pos = cd.indexOf('UTC');
    }

    if (pos != -1) {
      tz = cd.substr(pos);
      pos = tz.indexOf(' ');
      if (pos != -1) {
        tz = tz.substr(0, pos).replace('UTC', 'GMT');
      }
    }
  }

  // Using document.write here because we really need it to run ASAP
  if (tz != null) {
    document.write("<script type='text/javascript' src='" + window['base_uri'] + "/tz.html?tz=" + encodeURIComponent(tz) + "'></script>");
  } else {
    document.write("<script type='text/javascript' src='" + window['base_uri'] + "/tz.html?tz=&curDate=" + encodeURIComponent(cd) + "'></script>");
  }
})();
