/**
 * @param inputElement text input element to bind to
 * @param enablerFunction function to call when entered value to inputElement will match the host name of the current server
 * @constructor
 */
BS.HostnameConfirm = function(inputElement, enablerFunction) {
  var isHostnameMatches = function(s) {
    s = s.trim();
    if (!s.match(/^https?:\/\//)) {
      s = location.protocol + "//" + s;
    }
    return location.href.indexOf(s) === 0 && s.length > 8 &&
           (location.href.charAt(s.length) === "/" || location.href.charAt(s.length - 1) === "/");
  };

  var runCheck = function() {
    setTimeout(function () {
      if (isHostnameMatches(inputElement.value)) {
        enablerFunction();
      }
    }, 100);
  };

  inputElement.addEventListener("keydown", runCheck);
  inputElement.addEventListener("paste", runCheck);

  inputElement.disabled = false;
  inputElement.value = '';
  setTimeout(function() {
    inputElement.focus();
    var placeholders = document.querySelectorAll(".hostnamePlaceholder");
    Array.from(placeholders).forEach(function(field) {
      field.innerHTML = location.host;
    })
  }, 50);

  return {
    dispose: function() {
      inputElement.removeEventListener("keydown", runCheck);
      inputElement.removeEventListener("paste", runCheck);
    }
  }
};