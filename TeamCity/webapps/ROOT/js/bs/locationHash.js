// Helper for window.location.hash getting, setting and parsing
// Supports hash parameters like http://page.html#key1=val1&key2=val2

BS.LocationHash = {
  prefix: '#_', // should be at least #

  // returns hash value without #
  getHash: function () {
    var hash = window.location.hash;
    if (hash) {
      hash = hash.substring(this.prefix.length);
    }
    return hash;
  },

  // sets new hash value, browser history entry is added
  setHash: function (hash) {
    window.location.hash = this.prefix + hash;
  },

  // sets new hash value, browser history entry is not added
  replaceHash: function (hash) {
    var oldLocation = window.location.toString();
    if (oldLocation.indexOf(this.prefix) >= 0) {
      window.location.replace(oldLocation.replace(this.prefix + this.getHash(), this.prefix + hash));
    } else {
      window.location.replace(window.location + this.prefix + hash);
    }
  },

  getHashParameter: function (key) {
    return this.getHash().toQueryParams()[key];
  },

  setHashParameter: function (key, value) {
    this.replaceHash(this.getHashWithParameter(key, value));
  },

  // returns hash value without # and with specified parameter
  getHashWithParameter: function (key, value) {
    var params = this.getHash().toQueryParams();
    params[key] = value;
    return decodeURIComponent(Object.toQueryString(params));
  }
};