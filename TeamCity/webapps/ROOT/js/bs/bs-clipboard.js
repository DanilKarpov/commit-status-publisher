/**
 * @typedef {Object} extendedClipboardOptions
 *
 * @param {Function} text - (trigger:DOMNode):String
 * @param {Function} target - (trigger:DOMNode):DOMNode
 * @param {Boolean} skipDefaultHandlers
 */

/**
 * Creates new instance of clipboard.js helper
 * and return it to allow adding/removing
 * handlers for the `success`/`error` events
 *
 * @param {String} selector - might match several elements
 * @param {extendedClipboardOptions} options
 * @returns {Clipboard}
 *
 */
BS.Clipboard = function (selector, options) {
  var cb = new Clipboard(selector, options || {});

  if (!(options && options.skipDefaultHandlers)) {

    cb.on('success', function (e) {
      BS.Tooltip.showMessage(e.trigger, {shift: {x: 10, y: 18}, hideDelay: 300}, 'Copied!');
    });

    cb.on('error', function (e) {
      BS.Tooltip.showMessage(e.trigger, {shift: {x: 10, y: 18}, hideDelay: 300}, BS.Clipboard.fallbackMessage(e.action));
    });

    // `$j` is not defined in maintenance pages
    jQuery('body').on('mouseleave', selector, function() {
      BS.Tooltip.hidePopup();
    });

  }

  return cb;
};

BS.Clipboard.fallbackMessage = function (action) {
  var actionMsg='';
  var actionKey = action === 'cut' ? 'X' : 'C';
  if (document.documentElement.classList.contains('ua-mac')) {
    actionMsg='Press \u2318-'+ actionKey+' to '+ action;
  } else {
    actionMsg='Press Ctrl-'+ actionKey+' to '+ action;
  }

  return actionMsg;
};

BS.Clipboard.installGlobalHandler = function() {

  var decodeEntities = function(encodedString) {
    var textarea = document.createElement('textarea');
    textarea.innerHTML = encodedString;
    return textarea.value;
  };

  BS.Clipboard(".copy2Clipboard", {
    text: function(target) {
      var text = target.getAttribute('data-clipboard-text');
      if (!text) {
        var txtContainer = target.getAttribute('data-clipboard-id');
        if (txtContainer && $(txtContainer)) {
          text = decodeEntities($(txtContainer).innerHTML);
        }
      }
      if (!text) {
        text = target.innerHTML;
      }
      if (target.getAttribute('data-strip-tags') == 'true') {
        text = text.replace(/<br\/?>\r?\n?/g, "\n").stripTags().trim();
      }
      return text;
    }
  });

};