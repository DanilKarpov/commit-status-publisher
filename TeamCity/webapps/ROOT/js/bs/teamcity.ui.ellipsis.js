/**
 * For an element, makes it single-line by providing a clickable ellipsis at the end.
 * Should be used with block elements. When applied to inline elements, it sets display to inline-block.
 *
 * Requires ellipsis.css
 *
 * Usage $(".withEllipsis").installEllipsis();
 *
 * @author kir
 */

(function($) {

  var elementProcessor = {

    elements: [],

    install: function(element, options) {
      this.toggleEllipsis(element, options);
      this._saveForResizeProcessing(element);
    },

    toggleEllipsis: function(element, options) {
      this._removeExpander(element);
      options = options || {};
      var ellipsisRequired = options.ellipsisRequired ? options.ellipsisRequired(element) : this._hasMultilineText(element.html()) || this._contentTooWide(element);

      if (ellipsisRequired) {
        element
            .addClass("has-ellipsis")
            .append("<div class='ellipsis-expander'>&middot;&middot;&middot;</div>");
        var inserted = element.children().last();
        element.data('ellipsis-expander', inserted[0]);

        if ('inline' == element.css('display')) {
          element.css('display', 'inline-block');
        }

        // Install expander:
        var that = this;
        inserted.mousedown(function() {
          that._expand(element);
          return false;
        });
      }
      else {
        this._expand(element);
      }
    },

    _expand: function(element) {
      this._removeExpander(element);
      element.removeClass("has-ellipsis");
    },

    _removeExpander: function(element) {
      var expander = element.data('ellipsis-expander');
      if (expander) {
        expander.remove();
      }
      element.data('ellipsis-expander', null);
    },

    _hasMultilineText: function(text) {
      text = $.trim(text);
      // Remove <br>'s at the end of the text
      text = text.replace(/<br[^>]*>\s*$/g, "");
      // Two lines are OK, add ellipsis if there are more
      return text.match(/<br/g) && text.match(/<br/g).length > 1;
    },

    _contentTooWide: function(element) {
      element.addClass("has-ellipsis");

      if ('inline' == element.css('display')) {
        element.css('display', 'inline-block');
      }

      // Two lines are OK, add ellipsis if there are more
      var result = element.get(0).scrollHeight > (element.outerHeight() * 2) + 1;
      if (!result) element.removeClass("has-ellipsis");
      return result;
    },

    _saveForResizeProcessing: function(element) {
      if (!element.data('ellipsis-saved')) {
        this.elements.push(element);
        element.data('ellipsis-saved', true);
      }
    },

    handleResize: function(options) {
      this.cleanupDetachedElements();

      for(var i = 0; i < this.elements.length; i ++) {
        this.toggleEllipsis(this.elements[i], options);
      }
    },

    cleanupDetachedElements: function() {
      this.elements = $.grep(this.elements, function(el) {
        return el.closest('body').length;
      });
    }

  };

  var resizeHandlersInitialized;

  /**
   * Install ellipsis support for the element
   * @public
   * @memberOf jQuery.fn
   * */
  $.fn.installEllipsis = function(options) {
    this.each(function() {
      elementProcessor.install($(this), options);
    });

    if (!resizeHandlersInitialized) {
      resizeHandlersInitialized = true;

      // Recalculate once per second
      $(window).resize(_.throttle(function() {
          elementProcessor.handleResize(options);
      }, 1000));

      // handler to cleanup detached elements (to avoid memory leaks)
      var cleanup = function() {
        setTimeout(cleanup, 10000);
        elementProcessor.cleanupDetachedElements();
      };

      cleanup();
    }
  }

})(jQuery);