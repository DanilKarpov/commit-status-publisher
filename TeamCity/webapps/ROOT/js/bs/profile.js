BS.UserProfile = {
  makeEditable: function (elementId) {
    BS.Util.hide("editLink_" + elementId);
    BS.Util.hide("text_" + elementId);

    var inputId = "input_" + elementId;
    BS.Util.show(inputId);

    var input = $(inputId);
    if (input) {
      input.focus();
    }
  },

  onUserPropertyError: function (element, form) {
    var separatorIndex = element.firstChild.nodeValue.indexOf(":");
    if (separatorIndex < 0) return;

    var propId = element.firstChild.nodeValue.substr(0, separatorIndex);
    var errorMsg = element.firstChild.nodeValue.substr(separatorIndex + 1);
    var errorSpan = $("error_" + propId);
    if (errorSpan != null) {
      errorSpan.innerHTML = errorMsg;
      var input = $("input_" + propId);
      if (input) {
        form.highlightErrorField(input);
      }
    }
  },

  __updateTabCounter: function (selector, counter) {
    if (counter == 0) {
      $(selector).remove();
    } else {
      $(selector).innerHTML = counter;
    }
  },

  __createTabCounterIfDoesNotExist: function (tab, elementId, counter) {
    if (!$(elementId)) {
      $j('#admin-container .item a').each(function () {
        var link = $j(this);
        if (link.html() == tab) {
          link.append('<span class="tabCounter" id="' + elementId + '">' + counter + '</span>');
        }
      });
    }
  },

  updateTabCounter: function (tab, selector, counter) {
    this.__createTabCounterIfDoesNotExist(tab, selector, counter);
    this.__updateTabCounter(selector, counter);
  }
};


