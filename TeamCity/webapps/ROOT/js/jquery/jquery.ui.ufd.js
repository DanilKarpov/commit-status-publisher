/*
 ufd 0.6 : Unobtrusive Fast-filter Drop-down jQuery plugin.

 Authors:
 thetoolman@gmail.com
 Kadalashvili.Vladimir@gmail.com

 Version:  0.6

 Website: http://code.google.com/p/ufd/
 */

(function ($) {

  var widgetName = "ui.ufd";

  $.widget(widgetName, {

    // options: provided by framework
    // element: provided by framework

    _init: function () { //1.7 init
      // in 1.8 this method is  "default functionality" which we don't have; here for 1.7 support
      if (!this.created) this._create();
    },

    _create: function () { //1.8 init
      if (this.created) return;
      this.created = true;

      if (this.element[0].tagName.toLowerCase() != "select") {
        this.destroy();
        return false;
      }

      this.options = $.extend(true, {}, this.options); //deep copy: http://dev.jqueryui.com/ticket/4366

      this.visibleCount = 0;
      this.selectbox = this.element;
      this.logNode = $(this.options.logSelector);
      this.overflowCSS = this.options.allowLR ? "overflow" : "overflowY";
      var selectName = this.selectbox.attr("name");
      var prefixName = this.options.prefix + selectName;
      var inputName = this.options.submitFreeText ? selectName : prefixName;
      var inputId = ""; // none unless master select has one

      var sbId = this.selectbox.attr("id");

      if (sbId) {
        inputId = this.options.prefix + sbId;
        this.labels = $("label[for='" + sbId + "']").attr("for", inputId);
      }

      if (this.options.submitFreeText) this.selectbox.attr("name", prefixName);
      if (this.options.calculateZIndex) this.options.zIndexPopup = this._calculateZIndex();

      var css = this.options.css;
      this.css = this.options.css;
      if (this.options.useUiCss) $.extend(this.css, this.options.uiCss);
      if (!css.skin) css.skin = this.options.skin; // use option skin if not specified in CSS

      if (this.options.monospace) css.listScroll = "list-scroll custom-scroll mono mono-12px";

      this.wrapper = $([
                         '<span class="', css.wrapper, ' ', css.hidden, ' ', css.skin, '">',
                         '<input type="text" autocomplete="off" spellcheck="false" id="', inputId, '" class="', css.input, '" name="', inputName, '"/>',
                         '<button type="button" tabindex="-1" class="', css.button, '"><div class="', css.buttonIcon, '"/></button>',
                         //   <select .../> goes here
                         '</span>'
                       ].join(''));
      this.dropdown = $([
                          '<div class="', css.skin, '">',
                          // leonid.khachaturov: use css.button in the class name to easily match a dropdown list to its corresponding input field
                          '<div class="', css.listWrapper, ' ', css.listWrapper + css.button, ' ', css.hidden, '">',
                          '<div class="', css.listScroll, '">',
                          //  <ul/> goes here
                          '</div>',
                          '</div>',
                          '</div>'
                        ].join(''));

      this.selectbox.after(this.wrapper);
      this.getDropdownContainer().append(this.dropdown);

      this.input = this.wrapper.find("input");
      this.button = this.wrapper.find("button");
      this.listWrapper = this.dropdown.children(":first").css("z-index", this.options.zIndexPopup);
      this.listScroll = this.listWrapper.children(":first");

      if ($.fn.bgiframe) this.listWrapper.bgiframe(); //ie6 !

      // check browser supports min-width, revert to fixed if no support - Looking at you, iE6...
      if (!this.options.listWidthFixed) {
        // leonid.khachaturov: was this.listWrapper.css({"width": 50, "min-width": 100});
        this.listWrapper.css({"min-width": 100, "max-width": 1000});
        this.options.listWidthFixed = (this.listWrapper.width() < 100);
        this.listWrapper.css({"width": null, "min-width": null});
      }

      this._populateFromMaster();
      this._initEvents();
    },


    _initEvents: function () { //initialize all event listeners
      var self = this;
      var keyCodes = $.ui.keyCode;
      var key, isKeyDown, isKeyPress, isKeyUp;
      var css = this.options.css;

      this.input.bind("keydown keypress keyup", function (event) {
        // Key handling is tricky; here is great key guide: http://unixpapa.com/js/key.html
        isKeyDown = (event.type == "keydown");
        isKeyPress = (event.type == "keypress");
        isKeyUp = (event.type == "keyup");
        key = null;

        if (undefined === event.which) {
          key = event.keyCode;
        } else if (!isKeyPress && event.which != 0) {
          key = event.keyCode;
        } else {
          return; //special key
        }

        switch (key) { //stop default behaviour for these events
          case keyCodes.HOME:
          case keyCodes.END:
            if (self.options.homeEndForCursor) return; //no action except default

          case keyCodes.DOWN:
          case keyCodes.PAGE_DOWN:
          case keyCodes.UP:
          case keyCodes.PAGE_UP:
          case keyCodes.ENTER:
            if (!(keyCodes.ENTER && event.ctrlKey)) { // leonid.khachaturov: allow Ctrl+Enter to bubble up - it's our Submit shortcut
              self.stopEvent(event);
            }

          default:
        }

        // only process: keyups excluding tab/return; and only tab/return keydown
        // Only some browsers fire keyUp on tab in, ignore if it happens
        // leonid.khachaturov: do not process keyup on Up/Down keys as well to enable key repeat
        if (!isKeyUp == ((key != keyCodes.TAB) && (key != keyCodes.ENTER) && (key != keyCodes.UP) && (key != keyCodes.DOWN) && (key != keyCodes.ESCAPE))) return;

        self.lastKey = key;

        switch (key) {
          case keyCodes.SHIFT:
          case keyCodes.CONTROL:
          case keyCodes.ALT:
          case keyCodes.LEFT:
          case keyCodes.RIGHT:
            //don't refilter
            break;

          case keyCodes.DOWN:
            self.selectNext(false);
            break;
          case keyCodes.PAGE_DOWN:
            self.selectNext(true);
            break;
          case keyCodes.END:
            self.selectLast();
            break;

          case keyCodes.UP:
            self.selectPrev(false);
            break;
          case keyCodes.PAGE_UP:
            self.selectPrev(true);
            break;
          case keyCodes.HOME:
            self.selectFirst();
            break;

          case keyCodes.ENTER:
            self.hideList();
            self.tryToSetMaster();
            self.inputFocus();
            break;
          case keyCodes.TAB: //tabout only
            self.realLooseFocusEvent();
            break;
          case keyCodes.ESCAPE:
            // leonid.khachaturov: just close the dropdown, don't propagate
            if (self.listVisible()) {
              self.stopEvent(event);
            }
            self.hideList();
            self.revertSelected();
            // leonid.khachaturov: TW-22154
            try {
              self.setActive(self.listItems[self.selectbox.get(0).selectedIndex]);
            } catch (e) {
            }
            break;

          default:
            self.showList();
            self.filter(false, true); //do delay, as more keypresses may cancel
            break;
        }
      });

      if (this.options.propagateTrigger === false) {
        this.wrapper.bind("click", function () {
          return false;
        });
      }

      this.input.bind("click", function (e) {
        if (self.isDisabled) {
          self.stopEvent(e);
          return;
        }
        if (!self.listVisible()) {
          self.filter(true); //show all
          self.inputFocus();
          self.showList();
        }

        if (self.options.propagateTrigger === false) {
          return false;
        }
      });
      this.input.bind("focus", function (e) {
        if (self.isDisabled) {
          self.stopEvent(e);
          return;
        }
        if (!self.internalFocus) {
          self.realFocusEvent();
        }
      });

      this.button.bind("mouseover", function (e) {
        self.button.addClass(css.buttonHover);
      });
      this.button.bind("mouseout", function (e) {
        self.button.removeClass(css.buttonHover);
      });
      this.button.bind("mousedown", function (e) {
        self.button.addClass(css.buttonMouseDown);
      });
      this.button.bind("mouseup", function (e) {
        self.button.removeClass(css.buttonMouseDown);
      });
      this.button.bind("click", function (e) {
        function show() {
          self.filter(true); //show all
          self.inputFocus();
          self.showList();
        }

        function hide() {
          self.hideList();
          self.inputFocus();
        }

        if (self.isDisabled) {
          self.stopEvent(e);
          return;
        }

        if (self.button.data('triggeredBy') == 'mouseover') {
          show();
          self.button.data('triggeredBy', null);
          return false;
        }

        if (self.listVisible()) {
          hide();
        } else {
          show();
        }

        if (self.options.propagateTrigger === false) {
          return false;
        }
      });

      /*
       * Swallow mouse scroll to prevent body scroll
       * thanks http://www.switchonthecode.com/tutorials/javascript-tutorial-the-scroll-wheel
       * Leonid.Khachaturov: rewritten using jquery.mousewheel.js
       */
      this.listScroll.bind("mousewheel", function (e, delta) {
        var curST = self.listScroll.scrollTop();
        var newScroll = curST + ((delta > 0) ? -1 * self.itemHeight : 1 * self.itemHeight);
        self.listScroll.scrollTop(newScroll);
        return false;
      });

      function debounce(method, delay) {
        clearTimeout(method._tId);
        method._tId= setTimeout(function(){
          method();
        }, delay);
      }

      const recalculationDropDownPosition = ()=> {
        var offset = this.wrapper.offset();
        var left = offset.left;
        var top;
        var wrapperOuterHeight = this.wrapper.outerHeight();
        var bottomPos = offset.top + wrapperOuterHeight + outerHeight;
        var maxShown = $(window).height() + $(document).scrollTop();
        var forceDropDown = 2 * (offset.top - $(document).scrollTop()) < $(window).height() - wrapperOuterHeight;
        var doDropUp = (bottomPos > maxShown) && !forceDropDown;

        if (doDropUp) {
          top = (offset.top - outerHeight) + 1;
        } else {
          top = (offset.top + wrapperOuterHeight) - 1;
        }

        this.listWrapper.css("left", left);
        this.listWrapper.css("top", top);
      };

      addEventListener("scroll", () =>  debounce(recalculationDropDownPosition, 5), { passive: true });
      addEventListener("resize", recalculationDropDownPosition, { passive: true });

      this.listScroll.bind("mouseover mouseout click", function (e) {
        if ("LI" == e.target.nodeName.toUpperCase()) {
          if (self.setActiveTimeout) { //cancel pending selectLI -> active
            clearTimeout(self.setActiveTimeout);
            self.setActiveTimeout = null;
          }
          if ("mouseout" == e.type) {
            $(e.target).removeClass(css.liActive);
            self.setActiveTimeout = setTimeout(function () {
              $(self.selectedLi).addClass(css.liActive);
            }, self.options.delayYield);

          } else if ("mouseover" == e.type) {
            if (self.selectedLi != e.target) {
              $(self.selectedLi).removeClass(css.liActive);
            }
            $(e.target).addClass(css.liActive);

          } else { //click
            self.stopEvent(e); //prevent bubbling to document onclick binding etc
            // leonid.khachaturov: input field displays text from the data-title attribute, if available
            var thisOpt = $(e.target);
            var optionText = thisOpt.attr('data-title') || thisOpt.text();
            var value = $.trim(optionText);
            self.input.val(value);
            self.setActive(e.target);
            if (self.tryToSetMaster()) {
              self.hideList();
              self.filter(true); //show all
            }
            self.inputFocus();
          }
        }

        self.preventHiding = true;

        return true;
      });

      this.selectbox.bind("change." + widgetName, function (e) {
        if (self.isUpdatingMaster) {
          self.isUpdatingMaster = false;
          return true;
        }
        self.revertSelected();
      });

      // click anywhere else; keep reference for selective unbind
      this._myDocClickHandler = function (e) {
        if ((self.button.get(0) == e.target) || (self.input.get(0) == e.target)) return;
        if (self.internalFocus) self.realLooseFocusEvent();
      };
      $(document).bind("click." + widgetName, this._myDocClickHandler);

      // polling for disabled, dimensioned
      if (this.options.polling) {
        var self = this; // shadow self var - less lookup chain == faster
        this._myPollId = setInterval(function () {
          // fast as possible
          if (!self.dimensioned) self.setDimensions();
          if (self.selectbox[0].disabled != self.isDisabled) {
            (self.selectbox[0].disabled) ? self.disable() : self.enable();
          }

        }, self.options.polling);
      }

    },

    // pseudo events

    realFocusEvent: function () {
      this.internalFocus = true;
      this._triggerEventOnMaster("focus");
      this.wrapper.addClass(this.options.css.skin + "-" + this.options.css.inputFocus); // for ie6 support
      this.input.addClass(this.options.css.inputFocus);
      this.button.addClass(this.options.css.inputFocus);
      this.filter(true); //show all
      this.inputFocus();
      this.showList();
    },

    realLooseFocusEvent: function () {
      this.internalFocus = false;
      this.hideList();
      this.wrapper.removeClass(this.options.css.skin + "-" + this.options.css.inputFocus);
      this.input.removeClass(this.options.css.inputFocus);
      this.button.removeClass(this.options.css.inputFocus);
      this.tryToSetMaster();
      this.input.blur();
      this._triggerEventOnMaster("blur");
    },

    _triggerEventOnMaster: function (eventName) {
      if (document.createEvent) { // good browsers
        var evObj = document.createEvent('HTMLEvents');
        evObj.initEvent(eventName, true, true);
        this.selectbox.get(0).dispatchEvent(evObj);

      } else if (document.createEventObject) { // iE
        try {
          this.selectbox.get(0).fireEvent("on" + eventName);
        } catch (e) {
        }
      }

    },

    // methods

    inputFocus: function () {
      var input = this.input;

      try {
        input.focus();

        if (this.getCurrentTextValue().length) {
          setTimeout(function () { // workaround for webkit issue, UFD issue #59
            input.get(0).select();
          }, 10);
        }
      } catch (e) {
      }
    },

    inputBlur: function () {
      this.input.blur();
    },

    showList: function () {
      if (this.listVisible()) return;
      this.listWrapper.removeClass(this.css.hidden);
      this.setListDisplay();
    },

    hideList: function () {
      if (!this.listVisible()) return;
      this.listWrapper.addClass(this.css.hidden);
      this.listItems.removeClass(this.css.hidden);
    },

    /*
     * adds / removes items to / from the dropdown list depending on combo's current value
     *
     * if doDelay, will delay execution to allow re-entry to cancel.
     */
    filter: function (showAll, doDelay) {
      var self = this;

      //cancel any pending
      if (this.updateOnTimeout) clearTimeout(this.updateOnTimeout);
      if (this.filterOnTimeout) clearTimeout(this.filterOnTimeout);
      this.updateOnTimeout = null;
      this.filterOnTimeout = null;

      var searchText = self.getCurrentTextValue();

      var search = function () {
        var mm = self.trie.find(searchText); // search!

        self.trie.matches = mm.matches;
        self.trie.misses = mm.misses;

        //yield then screen update
        self.updateOnTimeout = setTimeout(function () {
          screenUpdate();
        }, self.options.delayYield);

      };

      var screenUpdate = function () {
        var active = self.getActive(); //get item before class-overwrite

        if (self.options.addEmphasis) {
          self.emphasis(self.trie.matches, true, searchText);
        }

        self.visibleCount = self.overwriteClass(self.trie.matches, "");
        self.nothingFound.toggleClass('hidden', self.visibleCount !== 0);

        if (showAll) {
          self.visibleCount += self.overwriteClass(self.trie.misses, "");
          if (self.options.addEmphasis) {
            self.emphasis(self.trie.misses, false, searchText);
          }
        } else {
          self.overwriteClass(self.trie.misses, self.css.hidden);
        }
        var oldActiveHidden = active.hasClass(self.css.hidden);

        // need to set overwritten active class
        if (!oldActiveHidden && active.length && self.trie.matches.length) {
          self.setActive(active.get(0));

        } else {
          var firstmatch = self.listItems.filter(":visible:first");
          self.setActive(firstmatch.get(0));
        }

        var _get_depth = function (element) {
          var cached = element._depth;
          if (cached) return cached;

          var className = element.className;
          var idx = className.indexOf("user-depth-");
          var result = idx > -1 ? parseInt(className.substr(idx + 11)) : -1;

          // When depth markers are not set, consider optgroups on level 0 and regular items on level 1 - TW-29790
          if (result == -1) {
            result = element.className.indexOf("optgroup") > -1 ? 0 : 1;
          }

          element._depth = result;
          return result;
        };

        var _last = function (arr) {
          return arr[arr.length - 1];
        };

        var _visible = function (element) {
          return element.className.indexOf("invisible") == -1;
        };

        var stack = [];
        self.listWrapper.find("li").each(function () {
          // See TW-30647.
          if (this.className.indexOf("user-delete") > -1) {
            return;
          }

          // By default, headers are invisible
          if (this.className.indexOf("optgroup") > -1) {
            $(this).addClass("invisible");
          }

          // Maintain a stack of parents
          // Invariant - currentParentsStack contains all parent elements of the current till the current element (inclusive)
          var depth = _get_depth(this);
          if (depth >= 0) {
            if (stack.length > 0) {
              var prev_depth = _get_depth(_last(stack));

              // tip of the stack has the same depth or more - remove all elements with deeper level
              while (prev_depth >= depth && stack.length > 0) {
                stack.pop();
                if (stack.length > 0) {
                  prev_depth = _get_depth(_last(stack));
                }
              }
            }

            stack.push(this);
          }

          // Well, if the current element is visible, we should make the hierarchy visible as well:
          if (_visible(this) && stack.length > 1 && !_visible(stack[stack.length - 2])) {
            for (var i = 0; i < stack.length; i++) {
              $(stack[i]).removeClass("invisible");
            }
          }
        });

        self.visibleCount = self.listWrapper.find("li:visible").length;
        self.setListDisplay();
      };

      if (doDelay) {
        //setup new delay
        this.filterOnTimeout = setTimeout(function () {
          search();
        }, this.options.delayFilter);
      } else {
        search();
      }
    },

    /*
     * replace chars with entity encoding
     */
    _encodeDom: $('<div/>'),
    _encodeString: function (toEnc) {
      return $.trim(this._encodeDom.text(toEnc).html());
    },

    emphasis: function (array, isAddEmphasis, searchText) {

      var tritem, index, indexB, li, text, stPattern, escapedST;
      var searchTextLength = searchText.length || 0;
      var options = this.selectbox.get(0).options;
      index = array.length;

      isAddEmphasis = (isAddEmphasis && searchTextLength > 0); // don't add emphasis to 0-length

      if (isAddEmphasis) {
        // html encode search string to match innerHTML then escape regexp chars; thanks http://xkr.us/js/regexregex
        escapedST = this._encodeString(searchText).replace(/([\\\^\$*+[\]?{}.=!:(|)])/g, "\\$1");
        stPattern = new RegExp("(" + escapedST + ")", "gi"); // $1
        this.hasEmphasis = true;
      }
      while (index--) {
        tritem = array[index];
        indexB = tritem.length;
        while (indexB--) { // duplicate match array
          li = tritem[indexB];
          text = $.trim(options[li.getAttribute("name")].innerHTML);
          li.innerHTML = isAddEmphasis ? text.replace(stPattern, "<em>$1</em>") : text;
        }
      }
    },

    _timingMeasure_firebug: function (isStart, label) {
      if (isStart) {
        console.time(label);
      } else {
        console.timeEnd(label);
      }
    },
    _timingMeasure: function (isStart, label) {
      this._timingMeasure_firebug(isStart, label);
    },
    removeEmphasis: function () {
      if (!this.hasEmphasis) {
        return;
      }
      this.hasEmphasis = false;
      var options = this.selectbox.get(0).options;
      var theLiSet = this.list.get(0).getElementsByTagName('LI'); // much faster array then .childElements !
      var liCount = theLiSet.length;
      var li;
      while (liCount--) {
        li = theLiSet[liCount];
        li.innerHTML = $.trim(options[li.getAttribute("name")].innerHTML);
      }
    },

    // attempt update of master - returns true if update good or already set correct.
    tryToSetMaster: function () {
      var optionIndex = null;
      var active = this.getActive();
      if (active.length) {
        optionIndex = active.attr("name"); //sBox pointer index
      }

      // leonid.khachaturov: make "disabled" options unselectable in custom dropdown as well
      if (active.attr("data-disabled")) {
        this.revertSelected();
        return false;
      }

      if (optionIndex == null || optionIndex == "" || optionIndex < 0) {
        if (this.options.submitFreeText) {
          return false;

        } else {
          this.revertSelected();
          return false;
        }
      } // else optionIndex is set to activeIndex

      var sBox = this.selectbox.get(0);
      var curIndex = sBox.selectedIndex;
      var option = sBox.options[optionIndex];
      // leonid.khachaturov: input field displays text from the data-title attribute, if available
      var optionText = option && (option.getAttribute('data-title') || option.text);
      if (!this.options.submitFreeText || this.input.val() == optionText) { //freetext only if exact match
        this.input.val(optionText); // input may be only partially set

        if (option && optionIndex != curIndex) {
          this.isUpdatingMaster = true;
          sBox.selectedIndex = optionIndex;
          this._triggerEventOnMaster("change");

        } // else already correctly set, no change
        return true;

      } // else have a non-matched freetext

      return false;
    },

    _populateFromMaster: function () {
      var isEnabled = !this.selectbox.filter("[disabled]").length; //remember incoming state
      this.disable();

      this.trie = new InfixTrie(this.options.infix, this.options.caseSensitive);
      this.trie.matches = [];
      this.trie.misses = [];

      var self = this;
      var listBuilder = $('<ul/>');
      listBuilder.
        append($j('<li class="nothing hidden">Nothing found</li>').attr('data-disabled', 'true'));

      var options = this.selectbox.get(0).options;
      var thisOpt, loopCountdown, index;
      var optionText = '';

      loopCountdown = options.length;
      index = 0;
      var selectedOptIndex = -1;

      function getFirstOption(optgroup) {
        var el;

        for (var i = 0; i < optgroup.childNodes.length; i++) {
          el = optgroup.childNodes[i];
          if (el.nodeType == 1 && el.tagName.toUpperCase() == 'OPTION') {
            return el;
          }
        }

        return null;
      }

      while (loopCountdown--) {
        thisOpt = options[index++];

        // leonid.khachaturov: insert LIs for OPTGROUPs
        var inOptgroup = thisOpt.parentNode.tagName.toUpperCase() == 'OPTGROUP';
        if (inOptgroup && getFirstOption(thisOpt.parentNode) == thisOpt) {
          this._insertOptgroup(listBuilder, thisOpt.parentNode);
        }

        var li = $('<li>');
        li.addClass("option");
        li.addClass(thisOpt.className);

        if (!inOptgroup) {
          li.addClass('nogroup');
        }

        li.attr('name', thisOpt.index);
        // leonid.khachaturov: mark disabled options with a special attribute
        if (thisOpt.getAttribute('disabled')) {
          li.attr('data-disabled', 'true');
        }

        li.attr('data-title', thisOpt.getAttribute('data-title') || thisOpt.text);
        li.attr('title', thisOpt.getAttribute('title'));

        if (thisOpt.selected) {
          selectedOptIndex = thisOpt.index;
        }
        li.append($.trim(thisOpt.innerHTML));
        listBuilder.append(li);
      }

      this.listScroll.html(listBuilder);
      this.list = this.listScroll.find("ul:first");
      this.nothingFound = this.list.find('.nothing:first');

      // Search only proper options, not optgroups
      var theLiSet = this.list.find('li.option');
      this.listItems = theLiSet;

      loopCountdown = theLiSet.length;
      index = 0;
      while (loopCountdown--) {
        thisOpt = options[index];
        if (index == selectedOptIndex) {
          this.setActive(theLiSet[index]);
        }
        // leonid.khachaturov: search by data-title attribute, if available. We use it to store additional information that should be invisible,
        // but searchable (e.g. build type's project name, when searching build types)
        optionText = thisOpt.getAttribute('data-title') || thisOpt.text;

        self.trie.add($.trim(optionText), theLiSet[index++]); //option.text not innerHTML for trie as we don't want escaping
      }

      this.visibleCount = theLiSet.length;
      this.setInputFromMaster();
      if (selectedOptIndex == -1) {
        this.selectedLi = null;
      }

      this.dimensioned = false;
      this.setDimensions();

      if (isEnabled) this.enable();

      this._moveAttrs(this.selectbox, this.input, this.options.moveAttrs);
    },

    _insertOptgroup: function (listBuilder, optgroup) {
      var li = $('<li/>').addClass("optgroup");
      li.attr('data-title', optgroup.getAttribute('label'));
      li.html(optgroup.getAttribute('label').escapeHTML());
      li.addClass(optgroup.className);
      li.appendTo(listBuilder);
    },

    /*
     * cuts and pastes all listed attributes from the source to the destination
     */
    _moveAttrs: function (src, dest, attrs) {

      for (var i = 0; i < attrs.length; ++i) {
        var attr = attrs[i];
        var value = src.attr(attr);
        if (value) {
          dest.attr(attr, value);
          src.removeAttr(attr);
        }
      }

    },

    /*
     * This method is called by the poller, so needs to return quickly when not dimensioning
     */
    setDimensions: function () {
      // if a new UFD (unwrapped) and selectbox is invisible, we can't dimension
      if (!this.selectIsWrapped && !this.selectbox.filter(":visible").length) {
        return;
      }
      // if pre-exising UFD needs redimensioning, but is not visible
      if (this.selectIsWrapped && !this.wrapper.filter(":visible").length) {
        return;
      }

      this.wrapper.addClass(this.css.hidden);
      if (this.selectIsWrapped && (!this.options.manualWidth || this.options.unwrapForCSS)) { // unwrap
        this.wrapper.before(this.selectbox);
        this.selectIsWrapped = false;
      }

      //match original width
      var newSelectWidth;
      if (this.options.manualWidth) {
        newSelectWidth = this.options.manualWidth;
      } else {
        newSelectWidth = this.selectbox.outerWidth();
        if (newSelectWidth < this.options.minWidth) {
          newSelectWidth = this.options.minWidth;
        } else if (this.options.maxWidth && (newSelectWidth > this.options.maxWidth)) {
          newSelectWidth = this.options.maxWidth;
        }
      }

      var props = this.options.mimicCSS;
      for (propPtr in props) {
        var prop = props[propPtr];
        if (!props.hasOwnProperty(propPtr) || typeof  prop === 'function') continue;
        this.wrapper.css(prop, this.selectbox.css(prop)); // copy property from selectbox to wrapper
      }

      if (!this.selectIsWrapped) { // wrap
        this.wrapper.get(0).appendChild(this.selectbox.get(0));
        this.selectIsWrapped = true;
      }

      this.wrapper.removeClass(this.css.hidden);
      this.listWrapper.removeClass(this.css.hidden);

      var buttonWidth = this.button.outerWidth(true);
      var wrapperBP = this.wrapper.outerWidth() - this.wrapper.width();
      var inputBP = this.input.outerWidth(true) - this.input.width();
      var listScrollBP = this.listScroll.outerWidth() - this.listScroll.width();
      var inputWidth = newSelectWidth - buttonWidth - inputBP;

      this.input.width(inputWidth);
      this.wrapper.width(newSelectWidth);

      var cssWidth = this.options.listWidthFixed ? "width" : "min-width";
      this.listWrapper.css(cssWidth, newSelectWidth + wrapperBP);
      this.listScroll.css(cssWidth, newSelectWidth + wrapperBP - listScrollBP);

      this.listWrapper.addClass(this.css.hidden);

      this.dimensioned = true;

    },

    setInputFromMaster: function () {
      var selectNode = this.selectbox.get(0);
      var thisOpt;
      var val = "";
      try {
        // leonid.khachaturov: input field displays text from the data-title attribute, if available
        thisOpt = selectNode.options[selectNode.selectedIndex];
        val = thisOpt.getAttribute('data-title') || thisOpt.text;
      } catch (e) {
        //must have no items!BP
      }
      this.input.val(val);
    },

    revertSelected: function () {
      this.setInputFromMaster();
      this.filter(true); //show all
    },

    //corrects list wrapper's height depending on list items height
    setListDisplay: function () {

      if (!this.itemHeight) { // caclulate only once
        this.itemHeight = this.listItems.filter("li:first").outerHeight(true);
      }
      var height;

      if (this.visibleCount > this.options.listMaxVisible) {
        height = this.options.listMaxVisible * this.itemHeight;
        this.listScroll.css(this.overflowCSS, "scroll");
      } else {
        height = this.visibleCount * this.itemHeight;
        this.listScroll.css(this.overflowCSS, "hidden");
      }

      this.listScroll.height(height);
      var outerHeight = this.listScroll.outerHeight();
      this.listWrapper.height(outerHeight);

      //height set, now position

      var offset = this.wrapper.offset();
      var wrapperOuterHeight = this.wrapper.outerHeight();
      var bottomPos = offset.top + wrapperOuterHeight + outerHeight;

      var maxShown = $(window).height() + $(document).scrollTop();
      // force drop down if there is less space above the input than below
      var forceDropDown = 2 * (offset.top - $(document).scrollTop()) < $(window).height() - wrapperOuterHeight;
      var doDropUp = (bottomPos > maxShown) && !forceDropDown;

      var left = offset.left;
      var top;

      if (doDropUp) {
        this.listWrapper.addClass(this.css.listWrapperUp);
        top = (offset.top - outerHeight) + 1;
      } else {
        this.listWrapper.removeClass(this.css.listWrapperUp);
        top = (offset.top + wrapperOuterHeight) - 1;
      }
      this.listWrapper.css("left", left);
      this.listWrapper.css("top", top);
      this.scrollTo();

      return height;
    },

    //returns active (hovered) element of the dropdown list
    getActive: function () {
      if (this.selectedLi == null) return $([]);
      return $(this.selectedLi);
    },

    //highlights the item given
    setActive: function (activeItem) {
      $(this.selectedLi).removeClass(this.css.liActive);
      this.selectedLi = activeItem;
      $(this.selectedLi).addClass(this.css.liActive);
    },

    selectFirst: function () {
      var toSelect = this.listItems.filter(":not(.invisible):first");
      this.afterSelect(toSelect);
    },

    selectLast: function () {
      var toSelect = this.listItems.filter(":not(.invisible):last");
      this.afterSelect(toSelect);
    },


    //highlights list item before currently active item
    selectPrev: function (isPageLength) {
      var count = isPageLength ? this.options.pageLength : 1;
      var toSelect = this.searchRelativeVisible(false, count);
      this.afterSelect(toSelect);
    },

    //highlights item of the dropdown list next to the currently active item
    selectNext: function (isPageLength) {
      var count = isPageLength ? this.options.pageLength : 1;
      var toSelect = this.searchRelativeVisible(true, count);
      this.afterSelect(toSelect);
    },

    afterSelect: function (active) {
      if (active == null) return;
      this.setActive(active);
      // leonid.khachaturov: input field displays text from the data-title attribute, if available
      var optionText = active.attr('data-title') || active.text();
      this.input.val(optionText);
      this.scrollTo();
      //this.tryToSetMaster(); // leonid.khachaturov: don't - we don't want the action to occur when navigating the select box with keyboard arrows
      this.inputFocus();
      this.removeEmphasis();
    },

    searchRelativeVisible: function (isSearchDown, count) {
      var active = this.getActive();
      if (!active.length) {
        this.selectFirst();
        return null;
      }

      var searchResult;

      do { // count times
        searchResult = active;
        do { //find next/prev item
          searchResult = isSearchDown ? searchResult.next() : searchResult.prev();
        } while (searchResult.length && searchResult.hasClass(this.css.hidden));

        if (searchResult.length) active = searchResult;
      } while (--count);

      return active;
    },

    //scrolls list wrapper to active: true if scroll occured
    scrollTo: function () {
      if ("scroll" != this.listScroll.css(this.overflowCSS)) return false;
      var active = this.getActive();
      if (!active.length) return false;

      var activePos = Math.floor(active.position().top);
      var activeHeight = active.outerHeight(true);
      var listHeight = this.listWrapper.height();
      var scrollTop = this.listScroll.scrollTop();

      var top;
      var viewAheadGap = (this.options.viewAhead * activeHeight);

      if (activePos < viewAheadGap) { //  off top
        top = scrollTop + activePos - viewAheadGap;
      } else if ((activePos + activeHeight) >= (listHeight - viewAheadGap)) { // off bottom
        top = scrollTop + activePos - listHeight + activeHeight + viewAheadGap;
      }
      else {
        return false;
      } // no need to scroll
      this.listScroll.scrollTop(top);
      return true; // we did scroll.
    },

    getCurrentTextValue: function () {
      return $.trim(this.input.val());
    },

    stopEvent: function (e) {
      e = e ? e : window.event;
      e.cancel = true;
      e.cancelBubble = true;
      e.returnValue = false;
      if (e.stopPropagation) {
        e.stopPropagation();
      }
      if (e.preventDefault) {
        e.preventDefault();
      }
    },

    overwriteClass: function (array, classString) { //fast attribute OVERWRITE
      var tritem, index, indexB, count = 0;
      index = array.length;
      while (index--) {
        tritem = array[index];
        indexB = tritem.length;
        count += indexB;
        while (indexB--) { // duplicate match array
          // leonid.khachaturov: preserve item type classes (.option, .optgroup, .nogroup)
          var currentClasses = tritem[indexB].className.split(" ");
          var keepClasses = [];
          for (var i = 0; i < currentClasses.length; ++i) {
            var cur = currentClasses[i];
            if (cur == "option" || cur == "optgroup" || cur == "nogroup" || cur.startsWith("user-")) {
              keepClasses.push(cur);
            }
          }
          tritem[indexB].className = classString + ' ' + keepClasses.join(' ');
        }
      }
      return count;
    },

    listVisible: function () {
      return !this.listWrapper.hasClass(this.css.hidden);
    },

    preventHiding: false,
    showInProgress: false,
    hideInProgress: false,

    disable: function () {
      this.hideList();
      this.isDisabled = true;
      this.wrapper.addClass(this.css.buttonDisabled);
      this.button.addClass(this.css.buttonDisabled);
      this.input.addClass(this.css.inputDisabled);
      this.input.attr("disabled", "disabled");
      this.selectbox.attr("disabled", "disabled");
    },

    enable: function () {
      this.isDisabled = false;
      this.wrapper.removeClass(this.css.buttonDisabled);
      this.button.removeClass(this.css.buttonDisabled);
      this.input.removeClass(this.css.inputDisabled);
      this.input.removeAttr("disabled");
      this.selectbox.removeAttr("disabled");
    },

    getDropdownContainer: function () {
      var ddc = $("#" + this.options.dropDownID);
      if (!ddc.length) { //create
        ddc = $("<div></div>")
            .appendTo("body")
            .css("height", 0)
            .attr("id", this.options.dropDownID);
      }
      return ddc;
    },

    log: function (msg) {
      if (!this.options.log) return;

      if (window.console && window.console.log) {  // firebug logger
        console.log(msg);
      }
      if (this.logNode && this.logNode.length) {
        this.logNode.prepend("<div>" + msg + "</div>");
      }
    },

    _calculateZIndex: function (msg) {
      var zIndex = this.options.zIndexPopup; // start here as a min

      this.selectbox.parents().each(function () {
        var el = $(this);
        var elZIndex = el.get(0).style.zIndex || el.css('z-index');
        elZIndex = parseInt(elZIndex, 10);

        if (!elZIndex) return true;

        zIndex = Math.max(elZIndex + 1, zIndex);
        return true;
      });

      return zIndex;
    },

    changeOptions: function () {
      this._populateFromMaster();
    },

    destroy: function () {
      if (this.selectIsWrapped) { //unwrap
        this.wrapper.before(this.selectbox);
      }

      this._moveAttrs(this.input, this.selectbox, this.options.moveAttrs); // restore moved attributes
      this.labels.attr("for", this.selectbox.attr("id")); //revert label 'for' attributes.
      this.labels = null;

      this.selectbox.unbind("change." + widgetName);
      $(document).unbind("click." + widgetName, this._myDocClickHandler);
      if (this._myPollId) clearInterval(this._myPollId);
      //all other handlers are in these removed nodes.
      this.wrapper.remove();
      this.dropdown.remove();

      if (($.ui.version.split('.')[0]|0) <= 1 && ($.ui.version.split('.')[1]|0) < 8) { // $.ui.version < 1.8
        // see ticket; http://dev.jqueryui.com/ticket/5005 - wasn't fixed 1.7.3
        this.selectbox.unbind("setData." + widgetName);
        this.selectbox.unbind("getData." + widgetName);
        // will remove all events sorry, might have other side effects but needed
        this.selectbox.unbind("remove");

        $.widget.prototype.destroy.apply(this, arguments); // default destroy

      } else { // 1.8+
        $.Widget.prototype.destroy.apply(this, arguments); // default destroy
      }
      this.selectbox = null;
      this._encodeDom = null;

    },


    //internal state
    dimensioned: false, // polling flag indicating that setDimensions needs to be called.
    selectIsWrapped: false,
    internalFocus: false,
    lastKey: null,
    selectedLi: null,
    isUpdatingMaster: false,
    created: false,
    hasEmphasis: false,
    isDisabled: false

  });

  /****************************************************************************
   * Trie + infix extension implementation for fast prefix or infix searching
   * http://en.wikipedia.org/wiki/Trie
   ****************************************************************************/

  /**
   * Constructor
   */
  var InfixTrie = function (isInfix, isCaseSensitive) {

    this.isInfix = !!isInfix;
    this.isCaseSensitive = !!isCaseSensitive;
    this.root = [null, {}, false]; //masterNode: object, char -> trieNode map, traverseToggle
    this.infixRoots = (isInfix) ? {} : null;
  };

  /**
   * Add (String, Object) to store
   */
  InfixTrie.prototype.add = function (key, object) {
    key = this.cleanString(key);

    var kLen = key.length;
    var curNode = this.root;
    var chr, node;

    for (var i = 0; i < kLen; i++) {
      chr = key.charAt(i);
      node = curNode[1];
      if (chr in node) {
        curNode = node[chr];
      } else {
        curNode = node[chr] = [null, {}, this.root[2]]; // match roots' toggle setting

        if (this.isInfix) { // only add curNodes once, when created.
          if (chr in this.infixRoots) {
            this.infixRoots[chr].push(curNode);
          } else {
            this.infixRoots[chr] = [curNode];
          }
        }
      }
    }

    if (curNode[0]) {
      curNode[0].push(object);
    }
    else {
      curNode[0] = [object];
    }
    return true;
  };

  /**
   * Get object with two properties:
   *     matches: array of all objects not matching entire key (String)
   *     misses:  array of all objects exactly matching the key (String)
   *
   */
  InfixTrie.prototype.find = function (key) { // string
    var trieNodeArray = this.findNodeArray(key);
    var toggleTo = !this.root[2];
    var matches = [];
    var misses = [];
    var trie;

    for (arrName in trieNodeArray) {
      trie = trieNodeArray[arrName];
      if (!trieNodeArray.hasOwnProperty(arrName) || typeof trie === 'function') continue;

      this.markAndRetrieve(matches, trie, toggleTo);
    }
    this.markAndRetrieve(misses, this.root, toggleTo); //will ensure whole tree is toggled.

    return { matches: matches, misses: misses };
  };

  /**
   * Find array of trieNodes that match the infix key
   */
  InfixTrie.prototype.findNodeArray = function (key) {
    var key = this.cleanString(key);
    var retArray = [this.root];
    var kLen = key.length;
    var chr;

    this.cache = this.cache || {};
    var thisCache = this.cache;

    for (var i = 0; i < kLen; i++) {
      chr = key.charAt(i);
      if (thisCache.chr == chr) {
        retArray = thisCache.hit;

      } else {
        retArray = this.mapNewArray(retArray, chr);
        thisCache.chr = chr;
        thisCache.hit = retArray;
        thisCache.next = {};
      }
      thisCache = thisCache.next;
    }

    return retArray;
  };

  /**
   * Take an array of nodes, and construct new array of children nodes along the given chr.
   */
  InfixTrie.prototype.mapNewArray = function (nodeArr, chr) {

    if (nodeArr.length && nodeArr[0] == this.root) {
      if (this.isInfix) {
        return (this.infixRoots[chr] || []); // return empty array if undefined
      } else {
        var prefixRoot = this.root[1][chr];
        return (prefixRoot) ? [prefixRoot] : [];
      }
    }

    var retArray = [];
    var aLen = nodeArr.length;
    var thisNodesArray;
    for (var i = 0; i < aLen; i++) {
      thisNodesArray = nodeArr[i][1];
      if (thisNodesArray.hasOwnProperty(chr)) {
        retArray.push(thisNodesArray[chr]);
      }
    }

    return retArray;
  };

  /**
   * retrieves objects on the given array of trieNodes.
   * Also sets toggleSet and doesnt traverse already marked branches.
   * You must call this with root to ensure complete tree is toggled.
   */
  InfixTrie.prototype.markAndRetrieve = function (array, trie, toggleSet) {
    var stack = [ trie ];
    while (stack.length > 0) {
      var thisTrie = stack.pop();
      if (thisTrie[2] == toggleSet) continue; //already traversed
      thisTrie[2] = toggleSet;
      if (thisTrie[0]) array.unshift(thisTrie[0]);
      for (chr in thisTrie[1]) {
        if (thisTrie[1].hasOwnProperty(chr)) {
          stack.push(thisTrie[1][chr]);
        }
      }
    }
  };

  /**
   * Conform case as needed. Clean invalid characters ?
   */
  InfixTrie.prototype.cleanString = function (inStr) {
    if (!this.isCaseSensitive) {
      inStr = inStr.toLowerCase();
    }
    //invalid char clean here
    return inStr;
  };

  /**
   * Expose for testing
   */
  $.ui.ufd.getNewTrie = function (isCaseSensitive, isInfix) {
    return new InfixTrie(isCaseSensitive, isInfix);
  };

  /* end InfixTrie */


  $.extend($.ui.ufd, {
    version: "0.6",
    getter: "", //for methods that are getters, not chainables
    classAttr: (($.support.style) ? "class" : "className"), // IE6/7 class attribute

    defaults: { // 1.7 default options location, see below
      skin: "plain", // skin name
      prefix: "ufd-", // prefix for pseudo-dropdown text input name attr.
      dropDownID: "ufd-container", // ID for a root-child node for storing dropdown lists. avoids ie6 zindex issues by being at top of tree.
      logSelector: "#log", // selector string to write log into, if present.
      mimicCSS: ["float", "tabindex", "marginLeft", "marginTop", "marginRight", "marginBottom"
      ], //copy these properties to widget. Width auto-copied unless min/manual.
      moveAttrs: ["tabindex", "title"], // attributes to move from select to text input


      infix: true, //infix search, not prefix
      addEmphasis: false, // add <EM> tags around matches.
      caseSensitive: false, // case sensitive search
      submitFreeText: false, // re[name] original select, give text input the selects' original [name], and allow unmatched entries
      homeEndForCursor: false, // should home/end affect dropdown or move cursor?
      allowLR: false, // show horizontal scrollbar
      calculateZIndex: false, // {max ancestor} + 1
      useUiCss: false, // use jquery UI themeroller classes.
      log: false, // log to firebug console (if available) and logSelector (if it exists)
      unwrapForCSS: false, // unwrap select on reload to get % right on units etc. unwrap causes flicker on reload in iE6
      // leonid.khachaturov: was listWidthFixed: true
      listWidthFixed: false, // List width matches widget? If false, list can be wider to fit item width, but uses min-width so no iE6 support.

      polling: 250, // poll msec to test disabled, dimensioned state of master. 0 to disable polling, but needed for (initially) hidden fields.
      listMaxVisible: 10, // number of visible items
      minWidth: 50, // don't autosize smaller then this.
      maxWidth: null, // null, or don't autosize larger then this.
      manualWidth: null, //override selectbox width; set explicit width - stops flicker on reload in iE6 (unless unwrapForCSS) as no unwrap needed
      viewAhead: 1, // items ahead to keep in view when cursor scrolling
      pageLength: 10, // number of visible items jumped on pgup/pgdown.
      delayFilter: ($.support.style) ? 1 : 150, // msec to wait before starting filter (or get cancelled); long for IE
      delayYield: 1, // msec to yield for 2nd 1/2 of filter re-entry cancel; 1 seems adequate to achieve yield
      zIndexPopup: 10, // dropdown z-index

      // leonid.khachaturov: some lists look better with a monospace font
      monospace: false,
      // leonid.khachaturov: whether the click event that triggered the dropdown should be propagated
      propagateTrigger: true,

      // class sets
      css: {
        //skin: "plain", // if not set, will inherit options.skin
        input: "",
        inputDisabled: "disabled",
        inputFocus: "focus",

        button: "",
        buttonIcon: "icon",
        buttonDisabled: "disabled",
        buttonHover: "hover",
        buttonMouseDown: "mouseDown",

        li: "",
        liActive: "active",

        hidden: "invisible",

        wrapper: "ufd",
        listWrapper: "list-wrapper",
        listWrapperUp: "list-wrapper-up",
        listScroll: "list-scroll custom-scroll" /* leonid.khachaturov: custom-scroll adds custom scrollbar styling for WebKit */
      },

      //overlaid CSS set
      uiCss: {
        skin: "uiCss",
        input: "ui-widget-content",
        inputDisabled: "disabled",

        button: "ui-button",
        buttonIcon: "ui-icon ui-icon-triangle-1-s",
        buttonDisabled: "disabled",
        buttonHover: "ui-state-focus",
        buttonMouseDown: "ui-state-active",

        li: "ui-menu-item",
        liActive: "ui-state-hover",

        hidden: "invisible",

        wrapper: "ufd ui-widget ui-widget-content",
        listWrapper: "list-wrapper ui-widget ui-widget",
        listWrapperUp: "list-wrapper-up",
        listScroll: "list-scroll ui-widget-content" /* leonid.khachaturov: custom-scroll adds custom scrollbar styling for WebKit */
      }
    }
  });

  $.ui.ufd.prototype.options = $.ui.ufd.defaults; // 1.8 default options location

})(jQuery);
/* END */
