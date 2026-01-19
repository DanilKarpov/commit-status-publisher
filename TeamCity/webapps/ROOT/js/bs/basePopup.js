/*
 * Copyright 2000-2024 JetBrains s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
* Generic popup component which supports everything ;))
* */
BS.Popup = Class.create({
  initialize: function(elementId, options) {
    this._name = elementId;
    options = options || {};

    var user_shift = options.shift || {};
    delete options.shift;

    this.options = _.extend({

      delay: 300,     // msecs before popup is shown
      hideDelay: 600, // msecs before popup is hidden on mouse out; -1 to disable hiding
      width: null,    // if not null, corresponding width is set to the popup

      // positioning options, depend on how you show a popup, either
      // with showPopup or showPopupNearElement
      shift: {
        x: -200,
        y: 15
      },

      hasTriangle: false,

      loadingText: "Loading...",

      fitWithinWindowHeight: false,   // set to true if popup window height should be limited by the current window height
      fitWithinWindowBottomMargin: 0, // margin below the bottom part of the popup
      fitWithinWindowTopMargin: 5,    // margin above the bottom part of the popup (we'll scroll the page)
      doScroll: true,                 // set to false if you do not need scroll on open popup
      forceReload: false,             // set to true if a specific dialog needs to be reloaded/redisplayed even if already visible

      // Content options. If none provided, current content of the element is shown in the popup
      // Priority: innerText, url, textProvider, htmlProvider
      innerText: null,
      innerHTML: null,
      url: null,
      parameters: null,
      textProvider: null, // function(popup) { return "<b>some html</b>"; },
      htmlProvider: null, // function(popup) { return jQuery("<b>some html</b>"); }
      method: "get",

      // Function is called after the content is loaded
      afterShowFunc: function(popup) {},

      // Function is called after the popup is hidden
      afterHideFunc: function() {}

    }, options);

    _.extend(this.options.shift, user_shift);
    this._timer = null;
  }
}, {
  // Popup DOM element
  element: function() {
    return $(this._name);
  },

  // Container to attach popups
  container: function() {
    return BS.Popup.container || document.body;
  },

  // Show this popup near the mouse event location
  showPopup: function(event, moreOptions) {
    _.extend(this.options, moreOptions || {});

    var element = Event.element(event);

    // Don't re-trigger popup if it's already displayed
    if (!this.options.forceReload && this.isShown() && this.isLoaded() && element.getAttribute('data-popup') == this._name) {
      BS.Hider.stopHidingDiv(this._name);
      return;
    }

    var x = Event.pointerX(event) + this.options.shift.x;
    var y = Event.pointerY(event) + this.options.shift.y;

    var onShown = function() {
      // Store popup id in the toggle element
      element.setAttribute('data-popup', this._name);
    }.bind(this);

    this._showWithDelay(x, y, onShown);

    return this;
  },

  // Show this popup near given element
  showPopupNearElement: function(element, moreOptions) {
    var addOptions = moreOptions || {};
    _.extend(this.options, addOptions, {
      shift: _.extend(this.options.shift, addOptions.shift)
    });

    element = $j($(element));

    // Don't re-trigger popup if it's already displayed
    if (!this.options.forceReload && this.isShown() && this.isLoaded() && element.attr('data-popup') == this._name) {
      BS.Hider.stopHidingDiv(this._name);
      return;
    }

    var shift = this.options.shift;
    var shiftX = shift.dx != null ? element.width() + shift.dx : shift.x;
    var shiftY = shift.dy != null ? element.height() + shift.dy : shift.y;

    var pos = element.offset();
    var x = pos.left + shiftX;
    var y = pos.top + shiftY;

    var onShown = function() {
      // Store popup id in the toggle element
      element.attr('data-popup', this._name);
      moreOptions?.onShown?.();
    }.bind(this);

    this._showWithDelay(x, y, onShown);

    return this;
  },

  isLoaded: function() {
    return this._loaded === undefined || this._loaded;
  },

  hidePopup: function(delay, force) {
    this._clearPopupTimer();
    if (delay === undefined) delay = this.options.hideDelay;

    if (this.isShown() && (this.isLoaded() || force)) {
      if (delay > 0) {
        BS.Hider.startHidingDiv(this._name, delay);
      }
      else {
        BS.Hider.stopHidingDiv(this._name);
        BS.Hider.hideDivSingle(this._name);
      }
    }
  },

  stopHidingPopup: function() {
    if (this.isShown()) {
      BS.Hider.stopHidingDiv(this._name);
    }
  },

  isShown: function() {
    return BS.Util.visible(this.element());
  },

  _getMaxHeight: function() {
    if (this.options.fitWithinWindowHeight) {
      var popupPos = $(this.element()).cumulativeOffset();
      var height = BS.Util.windowSize()[1] - this.options.fitWithinWindowBottomMargin;
      height = height - (popupPos[1] - BS.Util._scrollTop());
      return height > 100 ? height : 100;
    }

    return -1;
  },

  _showWithDelay: function(x, y, callback) {
    if (this.isShown() && !this.isLoaded()) {
      _.isFunction(callback) && callback();
      return;
    }

    var delay = this.options.delay;
    this._clearPopupTimer();

    if (delay == 0) {
      this._showPopupNow(x, y, callback);
    } else {
      this._timer = setTimeout(
        function() {
          this._showPopupNow(x, y, callback);
        }.bind(this)
      , delay);
    }
  },

  _clearPopupTimer: function() {
    if (this._timer) {
      clearTimeout(this._timer);
      delete this._timer;
    }
  },

  _showPopupNow: function(x, y, showWithDelayCallback) {
    var div = this.element();
    var container = this.container();
    if (!div) {
      div = document.createElement("div");
      div.id = this._name;
      div.className = 'popupDiv';
      if (this.options.prepend) {
        container.prepend(div);
      } else {
        container.appendChild(div);
      }
    } else {
      this._removeDuplicates();
      if (div.parentNode != container) {
        div.remove();
        if (this.options.prepend) {
          container.prepend(div);
        } else {
          container.appendChild(div);
        }
      }
    }

    div = $(div);
    if (this.options.className) {
      div.addClassName(this.options.className);
    }

    if (!this.options.backgroundColor) {
      this.options.backgroundColor = 'var(--ring-popup-background-color)';
    }

    if (this.options.innerText) {
      $j(div).text(this.options.innerText);
    } else if (this.options.innerHTML) {
      div.innerHTML = this.options.innerHTML;
    } else if (this.options.url || this.options.textProvider) {
      var loadingText = '&nbsp;' + jQuery.trim(this.options.loadingText);
      div.addClassName('popupLoading');
      div.innerHTML = BS.loadingIcon + loadingText;
    }

    if (this.options.hasTriangle) {
      div.addClassName('popupDiv_has-triangle')
      var w = document.createElement('div');
      w.className = 'popupDiv__inner';
      w.style.backgroundColor = this.options.backgroundColor || 'white';

      $j(div).children().wrapAll($j(w));
    }

    if (this.options.beforeShow) {
      this.options.beforeShow(div);
    }
    BS.Util.place(div, x, y);

    if (this._getMaxHeight() != -1) {
      div.style.overflow = 'hidden';
      div.style.height = 'auto';
    }

    this._loaded = false;

    return BS.Hider.showDivWithTimeout(div.id, _.extend({
      hideOnMouseOut: function () {
        return this.options.hideDelay >= 0 && this._loaded;
      }.bind(this)
    }, this.options)).then(function() {
      if (this.options.url) {
        BS.ajaxUpdater(this._name, this.options.url, {
          method: this.options.method,
          evalScripts: true,
          parameters: this.options.parameters,
          onComplete: function () {
            div.removeClassName('popupLoading');
            this._onComplete(showWithDelayCallback);
          }.bind(this)
        });
      } else {
        div.removeClassName('popupLoading');

        if (this.options.textProvider) {
          div.innerHTML = this.options.textProvider(this);
        }

        if (this.options.htmlProvider) {
          $j(div).append(this.options.htmlProvider(this));
        }

        this._initEvents();
        this._onComplete(showWithDelayCallback);
      }
    }.bind(this));
  },

  _removeDuplicates: function() {
    var elem = this.element(),
        _elem;

    elem.id = '_' + this._name;
    _elem = $(this._name);
    while(_elem) {
      _elem.parentNode.removeChild(_elem);
      _elem = $(this._name);
    }

    elem.id = this._name;
  },

  _onComplete: function(showWithDelayCallback) {
    this.element().style.backgroundColor = this.options.backgroundColor;
    if (this.options.width) {
      this.element().style.width = this.options.width;
    }

    this._fixHeight();
    this.updatePopup();
    this.options.afterShowFunc(this);
    _.isFunction(showWithDelayCallback) && showWithDelayCallback();
    this._loaded = true;
  },

  _fixHeight: function() {
    var container = this.element();
    var maxHeight = this._getMaxHeight(container);
    if (maxHeight > 0 && container.offsetHeight > maxHeight) {
      if (this.options.doScroll) {
        window.scrollTo(0, container.cumulativeOffset()[1] - this.options.fitWithinWindowTopMargin);
      }
      container.style.height = this._getMaxHeight(container) + 'px';
      container.style.overflowY = "auto";
    }
  },

  // ensures that popup fits the page
  // should be called each time after popup content changes
  updatePopup: function() {
    BS.Util.shiftToFitPage(this.element());
  },

  _initEvents: function() {
    var that = this;

    if (_.isString(this.options.className) && this.options.className.indexOf('quickLinksMenuPopup') > -1) {
      var $element = jQuery(this.element());

      $element.on("mouseup", "a", function(e) {
        var leftclick;
        if (e.which) leftclick = (e.which == 1);
        else if (e.button) leftclick = (e.button == 0);

        if (!leftclick) return;
        if (e.ctrlKey || e.metaKey) return;

        setTimeout(function() {
          BS.Hider.hideDivSingle(that._name);
        }, 0);
      });

      this._initKeyboardEvents($element);
    }
  },

  _initKeyboardEvents: function($element) {
    function selectNextItem(el) {
      var currentItem = jQuery(el).closest('.menuItem'),
          nextItem = currentItem.next();

      if(nextItem.length > 0 && nextItem.hasClass('menuItem')) {
        currentItem.removeClass('menuItemSelected');
        nextItem.addClass('menuItemSelected');
        nextItem.find('a').focus();
      }
    }

    function selectPreviousItem(el) {
      var currentItem = jQuery(el).closest('.menuItem'),
          previousItem = currentItem.prev();

      if(previousItem.length > 0 && previousItem.hasClass('menuItem')) {
        currentItem.removeClass('menuItemSelected');
        previousItem.addClass('menuItemSelected');
        previousItem.find('a').focus();
      }
    }

    var menuItems = $element.find('.menuItem');

    menuItems.removeClass('menuItemSelected')
        .first().addClass('menuItemSelected');
    menuItems.first().find('a').focus();

    menuItems.off('keydown');
    menuItems.keydown(function(e) {
      switch(e.keyCode) {
        case 38:
            selectPreviousItem(e.target);
            return false;

        case 40:
            selectNextItem(e.target);
            return false;

        default:
            return true;
      }
    });
  }
});

BS.Popup.openRingPopups = [];

//-------------------------------------------------------------------------
//  Some Specific popups:

BS.ChangesPopup = new BS.Popup("changesPopup", {
  url: window['base_uri'] + "/changesPopup.html?limit=25",
  method: "get"
});

BS.ChangesPopup._switchTab = function(container, promoId, tab) {
  container.style.overflow = 'hidden';
  container.style.height = 'auto';
  container.innerHTML = BS.loadingIcon + "&nbsp;Loading...";
  this.updatePopup();

  var that = this;
  setTimeout(function() {
    BS.ajaxUpdater(container, window['base_uri'] + "/changesPopupTab.html", {
      method: 'get',
      evalScripts: true,
      parameters: "limit=25&promoId=" + promoId + "&tab=" + tab,
      onComplete: function() {
        that.updatePopup();
      }
    });
  }, 500);
};

BS.ChangesPopup.showCurrentBuild = function(container, promoId) {
  this._switchTab(container, promoId, "");
};

BS.ChangesPopup.showSinceLastSuccessful = function(container, promoId) {
  this._switchTab(container, promoId, "sinceLastSuccessful");
};

BS.ChangesPopup.showBuildChangesPopup = function(nearestElement, id, isBuildId) {
  this.options.parameters = (isBuildId ? "buildId" : "promoId") + "=" + id;
  this.showPopupNearElement(nearestElement);
};

BS.ChangesPopup.showPendingChangesPopup = function(nearestElement, buildTypeId, userBranch, moreOptions) {
  this.options.parameters = "buildTypeId=" + buildTypeId;
  if (userBranch != null) {
    this.options.parameters += "&branch=" + encodeURIComponent(userBranch);
  }
  this.showPopupNearElement(nearestElement, moreOptions);
};

BS.ChangesPopup.expandComment = function(elem) {
  $j(elem)
      .parent().hide()
      .next().show();
  return false;
};

BS.ChangesPopup.initArtifactChangesBlocks = function () {
  var artifactDescriptionCaptions = $j('.artifactsChangeHeader');

  artifactDescriptionCaptions.click(function() {
    var caption = $j(this);

    caption.toggleClass('expanded').toggleClass('collapsed');
    caption.parent().find(".artifactChange").toggleClass('hidden');
  });

  artifactDescriptionCaptions.mousedown(function() {
    return false;
  });
};


BS.FilesPopup = new BS.Popup("filesPopup", {
  url: window['base_uri'] + "/filesPopup.html",
  shift: {x: -300, y: 10},
  afterShowFunc: function() {
    // Make sure the URL in the links matches current page URL.
    // This code is needed while we support two diff URLs.
    var path = window.location.pathname + "?";
    if (path.include("/diff.html?") || path.include("/diffView.html?")) {
      $j("a", "#filesPopup .changedFiles").each(function() {
        var self = $j(this);
        self.attr("href", self.attr("href").replace(/\/.*\?/, path));
      });
    }
  }
});

// BS.BuildResultsPopupTracker(buildId).showPopup(buildTypeId, finished, skipChangesArtifacts, element, options)
// BS.BuildResultsPopupTracker(buildId).hidePopup()
// BS.BuildResultsPopupTracker(buildId).stopHidingPopup()
BS.BuildResultsPopupTracker = (function(){

  var myPopups = {};

  return function(buildId) {

    return {
      getPopup: function() {
        return myPopups[buildId];
      },

      showPopup: function(buildTypeId, finished, skipChangesArtifacts, element, options) {
        if (!myPopups[buildId]) {
          myPopups[buildId] = new BS.BuildResultsSummary(buildId, buildTypeId, finished, skipChangesArtifacts);

          options = options || {};
          options.afterHideFunc = this._removePopup;
        }

        myPopups[buildId].showPopupNearElement(element, options);
      },

      _removePopup: function() {
        if (myPopups[buildId] && !myPopups[buildId].isShown()) {
          delete myPopups[buildId];
          BS.Log.info("Cleanup build results popup " + buildId + "; remains " + $H(myPopups).keys().length);
        }
      },

      hidePopup: function() {
        if (myPopups[buildId]) {
          myPopups[buildId].hidePopup();
          this._removePopup();
        }
      },

      stopHidingPopup: function() {
        if (myPopups[buildId]) {
          myPopups[buildId].stopHidingPopup();
        }
      }
    }

  }

})();



BS.BuildResultsSummary = Class.create(BS.Popup, {
  initialize: function($super, buildId, buildTypeId, finished, skipChangesArtifacts) {
    $super("popupRes" + buildId, {
      buildId: buildId,
      skipChangesArtifacts: skipChangesArtifacts,
      buildTypeId: buildTypeId,

      shift: {x: -80},

      textProvider: function(popup) {
        var template = $('buildResultsSummaryTemplate');
        if (!template) return;

        var text = template.innerHTML;
        text = text.replace(/##BUILD_ID##/g, popup.options.buildId);
        text = text.replace(/##BUILD_TYPE_ID##/g, popup.options.buildTypeId);

        setTimeout(function() { this.showDetailedInfo(); }.bind(popup), 20);
        return text;
      }
    });
  },
  showDetailedInfo: function() {
    this._loaded = false;
    var buildId = this.options.buildId;

    $('summaryProgress:' + buildId).innerHTML = BS.loadingIcon + " Loading details...";

    var ajaxOptions = {
      method: "GET",
      evalScripts: true,
      onComplete: function() {
        if ($('summaryProgress:' + buildId))
          $('summaryProgress:' + buildId).innerHTML = "";
        this.updatePopup();
        this._loaded = true;
      }.bind(this)
    };

    var location = window.location.href;
    var customStyle = "";
    if (location.indexOf("style=light")>-1){
      customStyle = "&style=light";
    }
    BS.ajaxUpdater($('detailedSummary:' + buildId),
                   window['base_uri'] + "/buildResultsSummary.html?buildId=" + buildId + "&skipChangesArtifacts=" + this.options.skipChangesArtifacts + customStyle,
                   ajaxOptions);
  }
});


BS.BuildTypeSummary = new BS.Popup("buildTypeSummary");
BS.BuildTypeSummary.showSummaryPopup = function(nearestElement, buildTypeId, projectExternalId, withSelf, withProject, withAdmin, withResponsibility) {
  this.showPopupNearElement(nearestElement, {
    shift: {x: 5, y: 20},
    url: window['base_uri'] + "/buildTypePopup.html",
    parameters: {
      buildTypeId: buildTypeId,
      branch: BS.Branch.getBranch(projectExternalId),
      withSelf: withSelf ? 'true' : 'false',
      withProject: withProject ? 'true' : 'false',
      withAdmin: withAdmin ? 'true' : 'false',
      withResponsibility: withResponsibility ? 'true' : 'false'
    }
  });
};

BS.AgentInfoPopup = new BS.Popup("agentInfoPopup", {
  url: window['base_uri'] + "/showCompatibleAgents.html",
  shift: {x: -150}
});

BS.AgentInfoPopup.showAgentsPopup = function(nearestElement, itemId) {
  this.options.parameters = "itemId=" + itemId;
  this.showPopupNearElement(nearestElement);
};

// noinspection SpellCheckingInspection
BS.BuildCommentPopup = new BS.Popup("buildCommentPopup", {
  url: window['base_uri'] + "/bsout.html",
  shift: {x: -150}
});

//parameters = content=some comment&buildTypeId=1234as
BS.BuildCommentPopup.showBuildCommentPopup = function(nearestElement, parameters) {
  this.options.parameters = parameters;
  this.showPopupNearElement(nearestElement);
};



BS.DependentArtifactsPopup = new BS.Popup("dependentArtifactsPopup", {
  shift: {x: -60},
  url: window['base_uri'] + "/viewDependentArtifactsPopup.html"
});
BS.DependentArtifactsPopup.showPopup = function(nearestElement, buildId, targetBuildId, mode) {
  this.options.parameters = "buildId=" + buildId + "&targetBuildId=" + targetBuildId + "&mode=" + mode;
  this.showPopupNearElement(nearestElement);
};


BS.BuildTypeSettingsPopup = {
  showMultilineValue: function(element, title, text, syntax) {
    var valueContainer = $('valueContainer');
    BS.Util.center('valuePopup');
    valueContainer.value = text;
    $('valuePopupTitle').innerHTML = title;
    BS.Hider.showDivWithTimeout('valuePopup', {
      hideOnMouseOut: false,
      draggable: true,
      dragHandle: $('valuePopup').getElementsBySelector('.dialogHandle')[0]
    });

    if (this.cm) {
      valueContainer.parentNode.removeChild(this.cm.getWrapperElement());
    }

    if (!syntax) {
      this.togglePaddings(/*arePaddingsEnabled*/true);
      valueContainer.show();
    } else {
      this.togglePaddings(/*arePaddingsEnabled*/false);
      this.cm = BS.CodeMirror.fromTextArea(valueContainer, {
        mode: syntax,
        readOnly: true,
        cursorBlinkRate: -1, // do not show cursor
        styleActiveLine: false,
        autofocus: false
      });

      this.cm.setSize('100%', $j('#valuePopup').height() - $j('#valuePopup .dialogHeader').outerHeight());
    }
    valueContainer.focus();
  },
  closeMultilineValuePopup: function() {
    BS.Hider.hideDiv('valuePopup');
  },
  togglePaddings: function(arePaddingsEnabled) {
    $j('#valuePopup .modalDialogBody').toggleClass('modalDialogBody_nopaddings', !arePaddingsEnabled);
  }
};


BS.ProgressPopup = new BS.Popup("progressPopup", {
  delay: 0,
  hideDelay: 0
});

BS.ProgressPopup.showProgress = function(nearestElem, message, options) {
  message = jQuery.trim(message);

  this.options.innerHTML = '<span style="white-space: nowrap;">' + BS.loadingIcon + '&nbsp;' + message + '</span>';
  if (this.options.delay === undefined) {
    this.options.delay = 0;
  }

  _.extend(this.options, options);
  this.showPopupNearElement(nearestElem);
};


BS.WarningPopup = new BS.Popup("warningPopup", {
  delay: 0,
  hideOnMouseOut: false
});

BS.WarningPopup.showWarning = function(nearestElem, shift, message, moreOptions) {
  this.options.innerText = message;
  this.options.shift = shift;
  setTimeout(function() {
    this.showPopupNearElement(nearestElem, moreOptions)
  }.bind(this), 50)
};


/* simple popup for displaying messages */
BS.Tooltip = {
  _id: 1,

  getId: function() {
    return "messagePopup_" + this._id++;
  }
};

BS.Tooltip.create = function(options, message) {
  if  (BS.Tooltip.popup) return null;

  options = _.extend({
                            delay: options.delay || 400,
                            shift: options.shift,
                            hideOnMouseOut: true,
                            hideOnMouseClickOutside: false,
                            innerHTML: message
                          }, options);

  BS.Tooltip.popup = new BS.Popup(BS.Tooltip.getId(), options);
  return BS.Tooltip.popup;
};

BS.Tooltip.showMessage = function(nearestElem, options, message, evalScripts) {
  var popupToggle = $(nearestElem);

  evalScripts && message.evalScripts();

  var popup = BS.Tooltip.create(options, message);
  if (popup) popup.showPopupNearElement(popupToggle);
  BS.Tooltip.popupToggle = popupToggle;
  BS.Tooltip.deleteTitles(popupToggle);
};

BS.Tooltip.showMessageFromContainer = function(nearestElem, options, container, evalScripts) {
  BS.Tooltip.showMessage(nearestElem, options, $(container).innerHTML, evalScripts);
};

BS.Tooltip.showMessageAtCursor = function(event, options, message) {
  var popupToggle = $(event.currentTarget || event.target);

  var popup = BS.Tooltip.create(options, message);
  if (popup) popup.showPopup(event);
  BS.Tooltip.popupToggle = popupToggle;
  BS.Tooltip.deleteTitles(popupToggle);
};

BS.Tooltip.hidePopup = function() {
  if (BS.Tooltip.popup) {
    BS.Tooltip.popup.hidePopup(BS.Tooltip.popup.options.delay, true);
    BS.Tooltip.popup = null;
  }

  if (BS.Tooltip.popupToggle) {
    BS.Tooltip.recreateTitles(BS.Tooltip.popupToggle);
    BS.Tooltip.popupToggle = null;
  }
};

// See TW-11045. Here `3` is a magic number controlling JS performance. The greater the value, the more accurate
// the result will be, the slower the method. But I have never seen that a higher parent has the `title`.
BS.Tooltip.deleteTitles = function(elem) {
  if (!elem) return;
  elem = elem.up();
  for (var i = 0; i < 3; ++i) {
    if (!elem) return;
    if (elem.getAttribute("title")) {
      elem.setAttribute("data-original-title", elem.getAttribute("title"));
      elem.removeAttribute("title");
    }
    elem = elem.up();
  }
};

BS.Tooltip.recreateTitles = function(elem) {
  if (!elem) return;
  elem = elem.up();
  for (var i = 0; i < 3; ++i) {
    if (!elem) return;
    if (elem.getAttribute("data-original-title")) {
      elem.setAttribute("title", elem.getAttribute("data-original-title"));
    }
    elem = elem.up();
  }
};

BS.QueuedBuildsPopup = new BS.Popup("queuedBuildsPopup", {
  url: window['base_uri'] + "/queue.html",
  method: "get"
});

BS.QueuedBuildsPopup.showQueuedBuilds = function(nearestElem, buildTypeId, userBranch, itemId) {
  var parameters = "forBuildTypeId=" + buildTypeId;
  if (userBranch != null) {
    parameters += "&branch=" + encodeURIComponent(userBranch);
  }
  if (itemId!= null){
    parameters += "&itemId=" + encodeURIComponent(itemId);
  }
  this.showPopupNearElement(nearestElem, {parameters: parameters, shift: {x: -600, y: 15}});
};

BS.RunningBuildsPopup = new BS.Popup("runningBuildsPopup");

BS.RunningBuildsPopup.showBuilds = function(nearestElem, buildTypeId) {
  var container = $j(BS.Util.escapeId("btb" + buildTypeId));

  this.showPopupNearElement(nearestElem, {
    shift: {x: -800, y: 15},
    afterShowFunc: function() {
      var popup = $j("#runningBuildsPopup");

      // The popup may still contain the running builds for the previous build type
      // (happens when user triggers several popups in a row quickly).
      // In this case we should move the builds back to the corresponding container *before*
      // inserting builds for this build type.
      // A kind of hacky fallback. Normally the `if` should be false.
      if (!popup.is(":empty")) {
        var btId = popup.attr("bt-id");
        if (btId == buildTypeId) return;
        popup.children("table").appendTo(BS.Util.escapeId("btb" + btId));
      }

      popup.append(container.children("table")).attr("bt-id", buildTypeId);
    },
    afterHideFunc: function() {
      $j("#runningBuildsPopup").children("table").appendTo(container);
    }
  });
};

BS.ClickPopupSupport = {
  clickPopups: {},

  togglePopup: function(id, showPopupCommand) {
    var popup = BS.ClickPopupSupport.clickPopups[id];
    if (!popup || !popup.isShown()) {
      popup = eval(showPopupCommand); // eslint-disable-line no-eval
      BS.ClickPopupSupport.clickPopups[id] = popup;

      var linkPos = $(this).cumulativeOffset();
      var linkDim = $(this).getDimensions();
      var elDim = popup.element().getDimensions();

      BS.Util.place(popup.element(), linkPos[0] + linkDim.width - elDim.width, linkPos[1] + linkDim.height - 1);
      popup.updatePopup();

      BS.Hider.addHideFunction(popup._name, function() {
        delete BS.ClickPopupSupport.clickPopups[id];
      }.bind(this));
    }
    else {
      popup.hidePopup(0, true);
    }
  }
};


BS.PromoDetailsPopup = new BS.Popup("promoDetailsPopup", {
  url: window['base_uri'] + "/promoDetailsPopup.html",
  method: "get",
  shift: {x: -50}
});

BS.PromoDetailsPopup.showDetailsPopup = function(nearestElement, promoId) {
  BS.PromoDetailsPopup.options.parameters = "promoId=" + promoId;
  BS.PromoDetailsPopup.showPopupNearElement(nearestElement);
};


// BS.PromoDetailsPopupFunc(buildId).showPopup()
// BS.PromoDetailsPopupFunc(buildId).hidePopup()
// BS.PromoDetailsPopupFunc(buildId).stopHidingPopup()
BS.PromoDetailsPopupFunc = (function(){

  return function(buildId) {

    return {

      showPopup: function(buildTypeId, isFinished, skipChangesArtifact, element, options) {
        BS.PromoDetailsPopup.showDetailsPopup(element, buildId);
      },

      hidePopup: function() {
        BS.PromoDetailsPopup.hidePopup();
      },

      stopHidingPopup: function() {
        BS.PromoDetailsPopup.stopHidingPopup();
      }
    }

  }

})();


BS.AuthorityRolesPopup = new BS.Popup("authorityRolesPopup", {
  url: window['base_uri'] + "/admin/authorityRolesPopup.html",
  method: "get"
});

BS.AuthorityRolesPopup.showPopup = function(nearestElement, userId) {
  this.options.parameters = "rolesHolderId=" + userId;
  this.showPopupNearElement(nearestElement);
};


BS.GroupUsersPopup = new BS.Popup("groupUsersPopup", {
  url: window['base_uri'] + "/admin/groupUsersPopup.html",
  method: "get"
});

BS.GroupUsersPopup.showPopup = function(nearestElement, groupCode) {
  this.options.parameters = "groupCode=" + encodeURIComponent(groupCode);
  this.showPopupNearElement(nearestElement);
};


BS.ParentGroupsPopup = new BS.Popup("parentGroupsPopup", {
  url: window['base_uri'] + "/admin/parentGroupsPopup.html",
  method: "get"
});

BS.ParentGroupsPopup.showUserParentGroups = function(nearestElement, userId) {
  this.options.parameters = "userId=" + userId;
  this.showPopupNearElement(nearestElement);
};

BS.ParentGroupsPopup.showGroupParentGroups = function(nearestElement, groupCode) {
  this.options.parameters = "groupCode=" + encodeURIComponent(groupCode);
  this.showPopupNearElement(nearestElement);
};

BS.BuildTypeTemplatesPopup = new BS.Popup("buildTypeTemplatesPopup", {
  url: window['base_uri'] + "/admin/buildTypeTemplatesPopup.html",
  method: "get"
});

BS.BuildTypeTemplatesPopup.showPopup = function(nearestElement, buildTypeId, selectedStep) {
  this.options.parameters = "buildTypeId=" + encodeURIComponent(buildTypeId) + "&selectedStep=" + selectedStep;
  this.showPopupNearElement(nearestElement);
};

BS.ShowBuildTypesPopup = new BS.Popup('showBuildTypesPopup', {
  hideDelay: 0,
  shift: {x: -230, y: 20},
  className: 'flatView'
});

BS.ShowBuildTypesPopup.showPopup = function(nearestElement, projectExternalId) {
  var params = {
    projectId: projectExternalId
  };
  BS.Branch.addBranchToParams(params, projectExternalId);

  this.options.url = window['base_uri'] + '/showBuildTupesPopup.html?' + Object.toQueryString(params);
  this.showPopupNearElement(nearestElement);
};


BS.InstallAgentsPopup = {
  showNearElement: function(element) {
    $('installAgents').style.position = 'absolute';
    BS.Util.placeNearElement('installAgents', element, {x: -180, y: 21});
    BS.Hider.showDivWithTimeout('installAgents', {hideOnMouseOut: false});
  }
};


BS.TogglePopup = new BS.Popup('togglePopup', {
  delay: 0,
  hideDelay: -1,
  shift: {x: 0}
});

BS.TogglePopup.toggle = function(link) {
  if (this.isShown()) {
    this.hidePopup();
  } else {
    this.options.innerHTML = link.nextSibling.innerHTML;
    this.showPopupNearElement(link);
  }
  return false;
};


BS.JumpTo = new BS.Popup("jumpToPopup", {
  delay: 0,
  hideDelay: -1,
  shift: {x: -209, y: 20}
});

BS.JumpTo.jump = function(label) {
  BS.HistoryTable.update('jumpTo=' + label);
  this.hidePopup();
};


BS.PopupDialog = {
  _popups: {},

  show: function(nearestElement, popupDialogTypeId, contextId, afterApply, moreOptions) {
    if (this._popups[popupDialogTypeId]) {
      this.hide(popupDialogTypeId, false);
    }

    var popupOptions = OO.extend({
      method: "get",
      url: window['base_uri'] + "/popupDialog.html",
      parameters: "init=1&typeId=" + encodeURIComponent(popupDialogTypeId) + "&contextId=" + contextId,
      hideOnMouseOut: false,
      hideOnMouseClickOutside: false,
      width: '25em',
      delay: 0,
      shift: {
        x: 0,
        y: nearestElement ? nearestElement.offsetHeight + 5 : 16
      },
      hideDelay: -1
    }, moreOptions || {});

    var popup = new BS.Popup("popupDialog_" + popupDialogTypeId, popupOptions);
    popup._afterApply = afterApply;
    this._popups[popupDialogTypeId] = popup;
    popup.showPopupNearElement(nearestElement);
  },

  hide: function(popupDialogTypeId, applied) {
    var popup = this._popups[popupDialogTypeId];
    this._popups[popupDialogTypeId] = null;
    if (popup) {
      popup.hidePopup();
      if (applied && popup._afterApply) {
        popup._afterApply();
      }
    }
  }
};

// A shortcut. Used in popupControl.tag
window._tc_es = function(e) {
  var element = e.currentTarget;
  if (element.hasAttribute('data-pinned')) {
    element.removeAttribute('data-pinned');
  } else {
    element.setAttribute('data-pinned', 'true');
    e.stopPropagation();
    return true;
  }
};

/**
 * @deprecated
 */
window._pc_over = function() {};

/**
 * @deprecated
 */
window._pc_out = function() {};


BS.ProjectDataPopup = new BS.Popup("projectDataPopup", {
  url: window['base_uri'] + "/projectData.html",
  method: "get",
  hideOnMouseOut: false,
  hideOnMouseClickOutside: true,
  shift: {x: 0, y: 20}
});

BS.ProjectDataPopup.showPopup = function(nearestElement, type, sourceFieldId, targetFieldId, popupTitle) {
  this.options.parameters = "type=" + type +
                            "&projectFilePath=" + $(sourceFieldId).value +
                            "&sourceFieldId=" + sourceFieldId +
                            "&targetFieldId=" + targetFieldId +
                            "&popupTitle=" + popupTitle +
                            "&retrieveData=true";
  this.showPopupNearElement(nearestElement);
};

BS.ProjectDataPopup.insertSelectedValue = function(val, targetFieldId) {
  $(targetFieldId).value = val;
  this.hidePopup(0);
};

BS.ProjectDataPopup.appendSelectedValues = function(formId, targetFieldId) {
  var elements = Form.getElements(formId);
  elements = elements.filter(function(element) {
    return element.type=='checkbox'
           && element.name.startsWith('dataItem_')
           && element.checked;
  });

  var separator = ' ';
  if ($(targetFieldId).tagName == 'TEXTAREA') {
    separator = '\n';
  }

  var val = $(targetFieldId).value + separator;
  for (var i=0; i<elements.length; i++) {
    val += elements[i].value + separator;
  }

  val = $j.trim(val);
  if (val.length > 0) {
    $(targetFieldId).value = val;
    this.hidePopup(0);
  }
};

BS.ProjectDataPopup.attachHandler = function (type, sourceFieldId, targetFieldId, popupTitle) {
  var handleId = "handle_" + sourceFieldId + targetFieldId;
  var icon = document.createElement('span');
  icon.id = handleId;
  icon.className = 'projectDataPopupHandle icon-magic';
  icon.style.position = 'absolute';
  icon.style.display = 'none';
  icon.style.right = '4px';
  icon.style.top = '4px';
  icon.title = popupTitle;
  icon.onclick = function() {
    BS.ProjectDataPopup.showPopup(this, type, sourceFieldId, targetFieldId, popupTitle);
  };
  $(targetFieldId).parentNode.appendChild(icon);

  var handler = {
    updateVisibility: function () {
      var control = $(targetFieldId);
      var popupControl = $(handleId);
      if (control.disabled || control.readOnly) {
        BS.Util.hide(popupControl);
      } else {
        if (popupControl != null) {
          BS.Util.show(popupControl);
        }
      }
    }
  };
  BS.VisibilityHandlers.attachTo(targetFieldId, handler);
};

BS.BranchesPopup = new BS.Popup("branchesPopup", {
  url: window['base_uri'] + "/branchesPopup.html",
  method: "get",
  hideOnMouseOut: false,
  hideOnMouseClickOutside: true,
  shift: {x: 0, y: 20}
});

BS.BranchesPopup.showPopup = function(nearestElement, idParamsFunc, targetFieldId, selectMode, branchesPolicy, applyBranchFilter) {
  this.options.parameters = idParamsFunc() + "&targetFieldId=" + targetFieldId + "&selectMode=" + selectMode + (branchesPolicy != null ? "&branchesPolicy=" + branchesPolicy : "")
    + (applyBranchFilter != null ? "&applyBranchFilter=" + applyBranchFilter : "");
  this.showPopupNearElement(nearestElement);
};

BS.BranchesPopup.attachBuildTypeHandler = function (buildTypeId, targetFieldId, selectMode, branchesPolicy, applyBranchFilter) {
  BS.BranchesPopup.doAttachHandler(function() {
    return "buildTypeId=" + buildTypeId;
  }, targetFieldId, selectMode, branchesPolicy, applyBranchFilter);
};

BS.BranchesPopup.attachBuildTypesHandler = function (buildTypeIdsFunc, targetFieldId, selectMode, branchesPolicy, applyBranchFilter) {
  BS.BranchesPopup.doAttachHandler(function() {
    var idsParam = "";
    var buildTypeIds = buildTypeIdsFunc();
    for (var i=0; i<buildTypeIds.length; i++) {
      idsParam += "buildTypeId=" + buildTypeIds[i] + "&";
    }
    return idsParam;
  }, targetFieldId, selectMode, branchesPolicy, applyBranchFilter);
};

BS.BranchesPopup.attachHandler = function (settingsId, targetFieldId, selectMode, branchesPolicy, applyBranchFilter) {
  BS.BranchesPopup.doAttachHandler(function () {
    return "id=" + settingsId;
  }, targetFieldId, selectMode, branchesPolicy, applyBranchFilter);
};

BS.BranchesPopup.doAttachHandler = function (idParamsFunc, targetFieldId, selectMode, branchesPolicy, applyBranchFilter) {
  if (!selectMode) {
    selectMode = 'branchFilter';
  }
  var handleId = "handle_branches_" + targetFieldId;
  if ($(handleId)) {
    $(handleId).parentNode.removeChild($(handleId));
  }

  var icon = document.createElement('span');
  icon.id = handleId;
  icon.className = 'branchesPopupHandle icon-magic';
  icon.onclick = function() {
    BS.BranchesPopup.showPopup(this, idParamsFunc, targetFieldId, selectMode, branchesPolicy, applyBranchFilter);
  };

  var parentClass = $(targetFieldId).parentNode.className;
  if (parentClass.indexOf('posRel') == -1) {
    BS.Util.wrapRelative($(targetFieldId));
  }

  $(targetFieldId).parentNode.appendChild(icon);
};

BS.BranchesPopup.appendSelected = function(prefix, formId, targetFieldId, parentPopup) {
  var elements = Form.getElements(formId);
  elements = elements.filter(function(element) {
    return element.type=='checkbox'
           && element.name.startsWith('branch_')
           && element.checked;
  });

  var separator = ' ';
  if ($(targetFieldId).tagName == 'TEXTAREA') {
    separator = '\n';
  }

  var val = $(targetFieldId).value + separator;
  for (var i=0; i<elements.length; i++) {
    var line = prefix + elements[i].value;
    var regExp = new RegExp("^" + BS.Util.escapeRegExp(line) + "$", "mg");
    if (regExp.test(val)) continue;
    val += line + separator;
   }

  val = $j.trim(val);
  if (val.length > 0) {
    $(targetFieldId).value = val;
    $j('#' + targetFieldId).trigger("onchange");
    BS.VisibilityHandlers.updateVisibility($(targetFieldId));
    if (parentPopup != null) {
      parentPopup.hidePopup(0)
    } else {
      this.hidePopup(0);
    }
  }

  return false;
};

BS.BranchesPopup.createParams = function(settingsId, selectMode, branchesPolicy, applyBranchFilter) {
  return BS.BranchesPopup.doCreateParameters(`id=${settingsId}`, selectMode, branchesPolicy, applyBranchFilter);
};

BS.BranchesPopup.createBuildTypesParams = function(btIdsFunc, selectMode, branchesPolicy, applyBranchFilter) {
  var idsParam = "";
  var buildTypeIds = btIdsFunc();
  for (var i=0; i<buildTypeIds.length; i++) {
    idsParam += "buildTypeId=" + buildTypeIds[i];
    if (i != buildTypeIds.length - 1) {
      idsParam += "&";
    }
  }
  return BS.BranchesPopup.doCreateParameters(idsParam, selectMode, branchesPolicy, applyBranchFilter);
};

BS.BranchesPopup.doCreateParameters = function(idsParam, selectMode, branchesPolicy, applyBranchFilter) {
  if (selectMode == null) {
    selectMode = 'branchFilter';
  }
  return idsParam + "&selectMode=" + selectMode + (branchesPolicy != null ? "&branchesPolicy=" + branchesPolicy : "")
    + (applyBranchFilter != null ? "&applyBranchFilter=" + applyBranchFilter : "");
};

BS.BranchFilterHelperPopup = new BS.Popup("branchFilterHelperPopup", {
  url: window['base_uri'] + "/branchFilterHelperPopup.html",
  method: "get",
  hideOnMouseOut: false,
  hideOnMouseClickOutside: false,
  shift: {x: 0, y: 20}
});

BS.BranchFilterHelperPopup.appendPattern = function (targetFieldId, pattern) {
  var separator = ' ';
  if ($(targetFieldId).tagName == 'TEXTAREA') {
    separator = '\n';
  }
  var val = $(targetFieldId).value + separator;
  var line = pattern;
  var regExp = new RegExp("^" + BS.Util.escapeRegExp(line) + "$", "mg");
  if (regExp.test(val)) return;
  val += line;

  val = $j.trim(val);
  if (val.length > 0) {
    $(targetFieldId).value = val;
    $j('#' + targetFieldId).trigger("onchange");
    BS.VisibilityHandlers.updateVisibility($(targetFieldId));
    this.hidePopup(0);
  }
};

BS.BranchFilterHelperPopup.attachHandler = function (targetFieldId, extensionIds, extensionParams) {
  var handleId = "handle_helper_" + targetFieldId;
  if ($(handleId)) {
    $(handleId).parentNode.removeChild($(handleId));
  }

  var icon = document.createElement('span');
  icon.id = handleId;
  icon.className = 'branchFilterHelperHandle icon-magic';
  icon.onclick = function() {
    BS.BranchFilterHelperPopup.showPopup(this, targetFieldId, extensionIds, extensionParams);
  };

  var parentClass = $(targetFieldId).parentNode.className;
  if (parentClass.indexOf('posRel') == -1) {
    BS.Util.wrapRelative($(targetFieldId));
  }

  $(targetFieldId).parentNode.appendChild(icon);
};

BS.BranchFilterHelperPopup.showPopup = function (nearestElem, targetFieldId, extensionIds, extensionParams) {
  this.options.parameters = `targetFieldId=${targetFieldId}`;
  extensionIds.forEach((id, index) => {
    this.options.parameters += `&${id}=true`;
    var extensionParamVar = extensionParams[index];
    var extensionParam = typeof extensionParamVar === 'function' ? extensionParamVar() : extensionParamVar;
    if (extensionParam != null && extensionParam.length > 0) {
      this.options.parameters += `&${extensionParam}`;
    }
  });

  this.showPopupNearElement(nearestElem);
};

(function () {
  /**
   * @typedef {object} popupOptions
   *
   * @property {string} [__base=BS.Popup] - base popup class
   * @property {function} [show]
   * @property {function} [hide]
   * @property {function} [stopHiding]
   * @property {function} [live] - live initialization function which must return
   *                               popup instance, has extended  `BS.Popup` signature:
   *                               function(elementId, options, [elem])
   * @property {object} [options] - constructor options
   * @property {array} [handlers]
   */
  /**
   * @typedef {object} bindPopupOptions
   *
   * @prop {object} [create]
   * @prop {array} [show]
   * @prop {array} [hide]
   * @prop {array} [stopHiding]
   */
  /**
   * Object containing singleton popup types instances
   * and multi-instance popup constructors
   * @type {object}
   * @private
   */
  var _registeredPopups = {};
  /**
   *
   * @param {string} typeNameOrId
   * @param {function} Ctor - popup constructor
   * @param {popupOptions} [options]
   * @param {DOMElement} [elem] - `.pc` element
   * @returns {Ctor} - popup instance
   * @private
   */
  function _getPopupInstance(typeNameOrId, Ctor, options, elem) {
    var handlerNames = [ 'show', 'hide', 'stopHiding' ],
      options = options || {},
      // when creating singleton instance of `BS.Popup` `typeName` is used as `id`
      // of `div` with popup content
      newPopup = new Ctor(typeNameOrId, options.options, elem);

    if (options.handlers) {
      newPopup.handlers = options.handlers;
    }

    handlerNames.forEach(function (fn) {
      if (options[fn]) {
        newPopup[ fn + 'Popup' ] = options[fn];
      }
    });

    // `showPopupNearElement` method is used by default - it uses element as first argument
    // in oppose to `showPopup` method using triggered event position
    if (! options.show) {
      newPopup.showPopup = function (closestElem, opts) {
        this.showPopupNearElement(closestElem, opts);
      }
    }

    return newPopup;
  }
  /**
   * Returns registered popup instance, constructor or throws an error
   * @param {string} typeName
   * @returns {Popup} - instance or constructor
   * @private
   */
  function _getPopupInstanceOrCtor(typeName) {
    var popup = _registeredPopups[typeName];

    if (!popup) {
      BS.Log.error('no popup type', typeName);
      throw new Error('no popup type', typeName);
    }

    return popup;
  }
  /**
   * Registers singleton or multi-instance popup
   * @param {string} typeName - name of the type (is used as an id for `.popupDiv`)
   * @param {popupOptions} [popupOptions]
   */
  BS.registerPopupType = function (typeName, popupOptions) {
    var newPopupType;

    popupOptions = popupOptions || {};

    if ( ! popupOptions.live) {
      newPopupType = _getPopupInstance(typeName, popupOptions.__base || BS.Popup, popupOptions);
    } else {
      /**
       * Multi-instance popup constructor
       * @param {string} id
       * @param {object} ctorOptions
       * @param {DOMElement} elem
       * @returns {Ctor}
       */
      newPopupType = function (id, ctorOptions, elem) {
        ctorOptions = ctorOptions || {};
        return _getPopupInstance(id, popupOptions.live, OO.extend(popupOptions, { options: ctorOptions }), elem);
      }
    }

    _registeredPopups[typeName] = newPopupType;
  };
  /**
   * Gets popup instance and binds its handlers to element and its `.toggle` child
   *
   * @param {DOMElement|string} elemOrId
   * @param {string} typeName
   * @param {bindPopupOptions} options
   */
  BS.bindPopup = function(elemOrId, typeName, options) {
    var $elem = $j(typeof elemOrId === 'string' ? BS.Util.escapeId(elemOrId) : elemOrId),
        $toggle = $elem.find('.toggle:last'),
        showOptions = options && options.show || [],
        hideOptions = options && options.hide || [],
        stopHidingOptions = options && options.stopHiding || [],
        createOptions = options && options.create || {},
        popup = $elem.length ? _getPopupInstanceOrCtor(typeName) : null;

    function show(event) {
      if (popup.__showNearEvent) {
        popup.showPopup.apply(popup, [event].concat(showOptions));
      } else {
        // `.toggle` element is passed as first argument to `show` function
        popup.showPopup.apply(popup, [$toggle[0]].concat(showOptions));
      }
    }

    if (popup) {
      if ('function' === typeof popup) {
        popup = popup($elem.attr('id'), createOptions, elemOrId);
      }

      $elem.removeAttr('onmouseover');
      // dirty saving for future use in simplePopup link click attribute
      popup._showOptions = showOptions;
      popup._$toggle = $toggle;

      if (popup.options.hideOnMouseOut !== false) {
        $elem.on('mouseover', function () {
          popup.stopHidingPopup.apply(popup, stopHidingOptions);
        }).on('mouseout', function () {
          // $toggle.removeAttr('data-popup'); // actually this hack is not working
          // because it lets popup redrawing. Normal solution must include adding
          // element id to data-popup attribute to allow drawing of popup of the same type
          popup.hidePopup.apply(popup, hideOptions);
        });
      }

      if ($toggle.length) {
        $toggle
          .on('mouseover', show)
          .on('click', function (e) {
            if(_tc_es(e)) {
              show(e);
            }
          });

        if (window.event && (window.event.target || window.event.srcElement) === $toggle[0]) {
          $toggle.trigger('mouseover');
        }
      }

      if (popup.handlers) {
        popup.handlers.forEach(function (handler) {
          $elem.on(handler.event, handler.delegate, handler.getHandler(popup));
        })
      }
    } else {
      BS.Log.warn('bind ' + typeName + ': Cannot find element with id ' + elemOrId);
    }
  };

  /*
    Legacy popups are registered in the closure to allow `_getPopupInstanceOrCtor`
    invocation to support legacy JS API
   */

  BS.registerPopupType('projectSummary', {
    show: function(nearestElement, projectId, withSelf, withAdmin) {
      this.showPopupNearElement(nearestElement, {
        shift: {x: 5, y: 20},
        url: window['base_uri'] + '/projectPopup.html',
        parameters: {
          projectId: projectId,
          branch: BS.Branch.getBranch(projectId),
          withSelf: withSelf ? 'true' : 'false',
          withAdmin: withAdmin ? 'true' : 'false'
        }
      });
    }
  });

  BS.ProjectSummary = _getPopupInstanceOrCtor('projectSummary');
  BS.ProjectSummary.showSummaryPopup = BS.ProjectSummary.showPopup;

  BS.registerPopupType('simplePopup', {
    live: function (elementId, options/*, elem*/) {
//      shift: {x: 0, y: 17}

      var el = $j(BS.Util.escapeId(elementId || ''));
      if (el.length == 0) {
        BS.Log.warn('bind simplePopup: Cannot find element with id ' + elementId);
        return;
      }

      return new BS.Popup(elementId + 'Content', OO.extend(options, { hideDelay: 300 }));
    },
    handlers: [
      {
        event: 'click',
        delegate: '.popupLink',
        getHandler: function (popup) {
          return function () {
            var $elem = $j(popup._$toggle.length ? popup._$toggle : this),
                parentPopup = $elem.parents('.popupDiv:last')[0];

            BS.Hider.hideAll(parentPopup);
            popup.showPopupNearElement($elem,
              OO.extend(popup._showOptions[0], {delay: 0}));
          }
        }
      }
    ]
  });

  BS.registerPopupType('buildTypeMenuPopup', {
    show: function (nearestElement, buildTypeExtId, cameFrom) {
      return this.showPopupNearElement(nearestElement, {
        parameters: {
          buildTypeId: buildTypeExtId,
          cameFromUrl: cameFrom
        },
        shift: {x: -241, y: 20},
        url: window['base_uri'] + '/showBuildTypeMenu.html',
        className: 'quickLinksMenuPopup'
      });
    }
  });

  /*===========================================================================*/
  /*   Handler for simplePopup.tag     */
  /*===========================================================================*/
  BS.install_simple_popup = function(elementId, options) {
    options = options || {};

    BS.bindPopup(elementId, 'simplePopup', { create: options });
  };
})();

BS.createReorderDialog = function (dialogId, $sortableList, saveHandler, sortableItemsSelector) {
  sortableItemsSelector = sortableItemsSelector || ".draggable";

  var dialog = BS.SimpleModalDialog(dialogId);
  dialog.$dialog = $j("#" + dialogId);

  var initState = [];
  $sortableList.find(sortableItemsSelector).each(function(idx, elt) { initState.push(elt.innerHTML); });
  dialog.resetState = function() {
    $sortableList.find(sortableItemsSelector).each(function(idx, elt) { elt.innerHTML = initState[idx]; });
  };

  dialog.setDisabled = function(state) {
    dialog.$dialog.find("#cancelButton").attr("disabled", state);
    dialog.$dialog.find(".saveOrderButton").attr("disabled", state);
    $sortableList.sortable(state ? "disable" : "enable");
  };

  $sortableList.sortable({
                           cancel: ".inherited",
                           tolerance: "pointer",
                           scroll: true,
                           axis: "y",
                           opacity: 0.7
                         });

  dialog.$dialog.bind("closeDialog", function () {
    dialog.close();
    dialog.$dialog.find("#saveOrderProgress").hide();
  }).bind("saveDialog", function () {
    dialog.$dialog.find("#saveOrderProgress").show();
    saveHandler(BS.QueueLikeSorter.computeOrder($sortableList.get(0), "ord_"));
    return false;
  });

  dialog.$dialog.find("#cancelButton").bind("click", function () {
    dialog.resetState();
    dialog.$dialog.trigger("closeDialog");
  });
  dialog.$dialog.find(".saveOrderButton").bind("click", function () {
    dialog.$dialog.trigger("saveDialog");
  });

  return dialog;
};