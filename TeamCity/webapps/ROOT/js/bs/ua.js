(function() {
  var classNames = [ document.documentElement.className, 'ua-js' ];
  var ua = window.navigator.userAgent.toLowerCase();

  if (ua.indexOf('mac') > -1) {
    classNames.push('ua-mac');
  } else if (ua.indexOf('windows') !== -1 && ua.indexOf('chrome') !== -1) {
    classNames.push('ua-win-chrome');
  }
  document.documentElement.className = classNames.join(' ');
})();
