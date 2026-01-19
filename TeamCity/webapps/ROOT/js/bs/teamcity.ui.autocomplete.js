(function($) {

  $.widget("teamcity.autocomplete", $.ui.autocomplete, {

    options: {
      /** should autocomplete arise on focus */
      showOnFocus: false,
      /** should widget display dropdown with 'No suggestions found' when no completion found */
      showEmpty: true,
      /** should autocomplete arise on Ctrl-Space even if not in completion position; when invoked with this option $j(input).data('ctrlSpace') will return true */
      completeOnCtrlSpace: null,
      /** set field value to the autocompletion item that get focus, or not */
      insertItemWithFocus: true,
      /** KeyDown handler (with event as a first parameter) for a case when completer is not active/focused; allows to perform an action
       * when text is entered, but no item is selected.
       * 'this' is set to the autocompleter's this */
      onEnterWhenInactive: null,
      /** function to get next portion of completion, will be called when completion menu is scrolled closer to the end,
       * if null - will not be called, signature: more(from, callback), from - is last element in menu */
      more: null
      // + options from $.ui.autocomplete widget
    },

    readTerm: function() {
      this.term = this.element.val();
    },

    /**
     * Focus and select given element under the menu
     * */
    activateItem: function(liElement) {
      this.menu.focus(null, liElement);
      this.menu.select();
    },

    // Add behaviours - special handling of Escape key, completeOnCtrlSpace, showOnFocus...
    _create: function() {
      var self = this;
      var input = this.element;
      self.isCtrl = false;

      if (!this.options.insertItemWithFocus) {
        this.options.focus = function() {
          return false;
        }
      }

      // Call base _create method
      $.ui.autocomplete.prototype._create.apply(self);
      this.menu.options.items = "> :not(.ui-menu-separator)";

      // Remove event listeners created by the base method
      this._off(input, "keydown");
      this._off(input, "keypress");
      this._off(input, "input");

      // Recreate the event listeners. The only difference from the base method's implementation is the following:
      // keypress should only be suppressed by the keydown listener if the autocomplete menu is visible. Fixes TW-24879
      var suppressKeyPress, suppressKeyPressRepeat, suppressInput;
      this._on(input, {
        keydown: function (event) {
          if (this.element.prop("readOnly")) {
            suppressKeyPress = true;
            suppressInput = true;
            suppressKeyPressRepeat = true;
            return;
          }

          var hasSuggestions = this.menu.element.is(":visible") && !this.nothingFound;

          suppressKeyPress = false;
          suppressInput = false;
          suppressKeyPressRepeat = false;
          var keyCode = $.ui.keyCode;
          switch (event.keyCode) {
            case keyCode.PAGE_UP:
              suppressKeyPress = hasSuggestions;
              this._move("previousPage", event);
              break;
            case keyCode.PAGE_DOWN:
              suppressKeyPress = hasSuggestions;
              this._move("nextPage", event);
              break;
            case keyCode.UP:
              suppressKeyPress = hasSuggestions;
              this._keyEvent("previous", event);
              break;
            case keyCode.DOWN:
              suppressKeyPress = hasSuggestions;
              this._keyEvent("next", event);
              break;
            case keyCode.ENTER:
            case keyCode.NUMPAD_ENTER:
              // when menu is open and has focus
              if (this.menu.active) {
                // #6055 - Opera still allows the keypress to occur
                // which causes forms to submit
                suppressKeyPress = true;
                event.preventDefault();
                this.menu.select(event);
              }
              else {
                // if we have a handler for ENTER when nothing is selected - call it here
                if (typeof this.options.onEnterWhenInactive === 'function') {
                  this.options.onEnterWhenInactive.call(this, event);
                }
              }
              break;
            case keyCode.TAB:
              if (this.menu.active) {
                this.menu.select(event);
              }
              break;
            case keyCode.ESCAPE:
              if (this.menu.element.is(":visible")) {
                this._value(this.term);
                this.close(event);
                // Different browsers have different default behavior for escape
                // Single press can mean undo or clear
                // Double press in IE means clear the whole form
                event.preventDefault();
                event.stopPropagation();
              }
              break;
            default:
              suppressKeyPressRepeat = true;
              // search timeout should be triggered before the input value is changed
              this._searchTimeout(event);
              break;
          }
        },
        keypress: function (event) {
          if (suppressKeyPress) {
            suppressKeyPress = false;
            event.preventDefault();
            return;
          }
          if (suppressKeyPressRepeat) {
            return;
          }

          // replicate some key handlers to allow them to repeat in Firefox and Opera
          var keyCode = $.ui.keyCode;
          switch (event.keyCode) {
            case keyCode.PAGE_UP:
              this._move("previousPage", event);
              break;
            case keyCode.PAGE_DOWN:
              this._move("nextPage", event);
              break;
            case keyCode.UP:
              this._keyEvent("previous", event);
              break;
            case keyCode.DOWN:
              this._keyEvent("next", event);
              break;
          }
        },
        input: function (event) {
          if (suppressInput) {
            suppressInput = false;
            event.preventDefault();
            return;
          }
          this._searchTimeout(event);
        }
      });

      // Add TeamCity's own functionality
      this._on(input, {
        keyup: function(event) {
          // Handle Escape key: prevent closing of dialog with autocompletion field
          if (event.keyCode === $.ui.keyCode.ESCAPE) {
            if (self.menu.element.is(":visible") || self.justClosed) {
              self.justClosed = false;
              event.stopPropagation();
            }
          } else {
            self.justClosed = false;
          }
          return true;
        }
      });

      if (this.options.completeOnCtrlSpace) {
        $(input).keydown(function(event) {
          if (event.ctrlKey && event.keyCode === $.ui.keyCode.SPACE) {
            $(input).data('ctrlSpace', true);
            $(input).autocomplete("search");
            return false;
          }
        });
      }

      if (this.options.showOnFocus) {
        $(input).focus(function() {
          //this check prevents reopen of autocompletion when user click on it, instead of type Enter
          if (!self.menu.active) {
            $(input).autocomplete("search");
          }
        });
      }
    },

    //redefine _renderItem to allow html in label and to show meta info on item
    _renderItem: function(ul, item) {
      var item_line = $("<a></a>");
      if (item.meta) {
        item_line.append('<span class="ui-autocomplete-meta-info">' + item.meta + '</span>');
      }
      item_line.append(item.label);
      return $("<li></li>")
            .data("ui-autocomplete-item", item)
            .append(item_line)
            .appendTo(ul);
    },

    _renderSeparator: function(ul, item) {
      var item_line = $('<li class="ui-menu-separator"></li>');
      if (item.meta) {
        item_line.append('<span class="ui-autocomplete-meta-info">' + item.meta + '</span>');
      }
      item_line.append(item.label);
      item_line.appendTo(ul);
    },

    //redefine _renderMenu to show message that nothing found
    _renderMenu: function(ul, items) {
      var self = this;
      if (items.length != 0) {
        $.each(items, function(index, item) {
          if (item.selectable) {
            self._renderItem(ul, item);
          } else {
            self._renderSeparator(ul, item);
          }
        });
        this.nothingFound = false;
      } else {
        ul.append("<li class='ui-autocomplete-nothing'>No suggestions found</li>");
        this.nothingFound = true;
      }
    },

    //redefine it to show popup with 'Nothing found' if there is no suggestions
    //original function show popup only if there are variants
    __response: function(content) {
      if (content === null) return;

      if (content.length || this.options.showEmpty) {
        content = this._normalize(content);
        this._suggest(content);
        this._trigger("open");
      } else {
        this.close();
      }
    },

    //redefine to take menu scroll into account, it seems to be the reason of TW-14337
    _suggest: function(items) {
      // zIndex should be above than max code mirror index (>4) TW-67698
      var zIndex = Math.max(this.element.zIndex() + 1, 5);
      var ul = this.menu.element.empty().zIndex(zIndex),
          menuWidth,
          textWidth;
      this._renderMenu(ul, items);
      this.menu.refresh();
      this.menu.element.show().position($.extend({of: this.element}, this.options.position));

      menuWidth = ul.width("").outerWidth();
      if (this.menu._hasScroll()) {
        $(this.menu.element).scrollTop(0);
        menuWidth = menuWidth + 20;
        this.askMore = true;
      }
      textWidth = this.element.outerWidth();
      ul.outerWidth(Math.max(menuWidth, textWidth));
      if (this.options.more && items.length > 0)
        this._bindMenuScrollHandler(ul, items[items.length - 1].value);
	},

    _bindMenuScrollHandler: function(ul, lastItem) {
      var itemsSize = $(ul).children().size();
      var itemHeight = $(ul).children().first().height();
      var loadMoreOffset = itemsSize * itemHeight * 0.5;
      var self = this;
      $(ul).unbind('scroll');
      var haveRun = false;
      $(ul).scroll(function() {
        var scrollFromTop = $(ul).scrollTop();
        if (self.askMore && scrollFromTop >= loadMoreOffset) {
          if (!haveRun) {
            haveRun = true;
            self._loadMore(ul, lastItem);
          }
        }
      });
    },

    _loadMore: function(ul, lastItem) {
      var self = this;
      this.options.more(lastItem, function(items) {
        if (items && items.length > 0) {
          var menuWidth, textWidth;
          self._renderMenu(ul, items);
          self.menu.refresh();
          menuWidth = ul.width("").outerWidth();
          if (self.menu._hasScroll()) {
            menuWidth = menuWidth + 20
          }
          textWidth = self.element.outerWidth();
          ul.outerWidth(Math.max(menuWidth, textWidth));
          if (items.length > 0 )
            self._bindMenuScrollHandler(ul, items[items.length - 1].value);
        } else {
          self.askMore = false;
          $(self.menu).unbind('scroll');
        }
      });
    },

    //redefine close to set associate data with element
    close: function(event) {
      clearTimeout(this.closing);
      if (this.menu.element.is(":visible")) {
        this._trigger("close", event);
        this.menu.element.hide();
        this.justClosed = true;
      }
      this.isCtrl = false;
      if (this.options.completeOnCtrlSpace) {
        $j(this.element).data("ctrlSpace", false);
      }
      $j(this.element).data("showAll", false);
    },

    /* override it to ignore any moves when nothing found */
    _keyEvent: function(direction, event) {
      if (this.nothingFound) {
        return;
      }
      var self = this;
      $.ui.autocomplete.prototype._keyEvent.apply(self, [direction, event]);
    },

    _move: function(direction, event) {
      if (this.nothingFound) {
        return;
      }
      var self = this;
      $.ui.autocomplete.prototype._move.apply(self, [direction, event]);
    }
  });

} (jQuery));