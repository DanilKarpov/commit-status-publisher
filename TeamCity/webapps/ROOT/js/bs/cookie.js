BS.Cookie = {};

BS.Cookie.set = function(name, value, duration_days, path) {
  var cookietext = name + "=" + encodeURIComponent(value);
  if (duration_days != null) {
    var expiredate = new Date();
    expiredate.setTime(new Date().getTime() + 1000 * 60 * 60 * 24 * duration_days);
    cookietext += "; EXPIRES=" + expiredate.toGMTString();
  }
  if (path == null) {
    path = "/";
  }
  cookietext += "; PATH=" + path;
  document.cookie = cookietext;
};

BS.Cookie.get = function(name) {
  var cs = document.cookie;
  var result = null;
  if (cs) {
    var offset = cs.indexOf(name + "=");
    if (offset >= 0) {
      offset += name.length + 1;
      var end = cs.indexOf(";", offset);
      if (end < 0) {
        end = cs.length;
      }
      result = decodeURIComponent(cs.substring(offset, end));
    }
  }
  return result;
};

BS.Cookie.remove = function(name) {
  this.set(name, "Deleted", -1);
};

BS.Cookie.clearAll = function() {
  document.cookie.split(";").map(function(cookie) {
    var cookieTuple = cookie.split("=");
    this.remove(cookieTuple[0]);
  }.bind(this))
}
