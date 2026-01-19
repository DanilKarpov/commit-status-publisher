(function($) {

  $.widget("teamcity.placeholder", {

    options: {
      text:  '&lt;start typing to see suggestions>',
      css_class: 'placeholder'
    },

    /**
     * Tests if placeholders are supported natively
     */
    hasPlaceholderSupport: function() {
      var input = document.createElement('input');
      return ('placeholder' in input);
    },

    /**
     * Show placeholder
     */
    show: function() {
      this.placeholder && this.placeholder.show().position({my: 'left center', at: 'left center', of: this.element});
    },

    /**
     * Hide placeholder
     */
    hide: function() {
      this.placeholder && this.placeholder.hide();
    },

    /**
     * Show placeholder if input field is empty, visible and enabled, otherwise - hide
     */
    refresh: function() {
      if ($(this.element).is(':hidden') || $(this.element).is(':disabled')) {
        this.hide();
      } else {
        var value = this.element.val();
        if (value && value.length > 0) {
          this.hide();
        } else {
          this.show();
        }
      }
    },

    _create: function() {
      if (this.hasPlaceholderSupport()) {
        this._createNative();
      } else {
        this._createFallback();
      }
    },

    _createNative: function() {
      var fakePlaceholder = $('<span style="display: none"/>');
      var placeholderText = fakePlaceholder.html(this.options.text).text(); // HTMLize
      this.element.attr('placeholder', placeholderText);
      this.placeholder = fakePlaceholder;
    },

    _createFallback: function() {
      var that = this;
      var css_class = this.options.css_class || 'placeholder';
      var placeholder = $('<div class="' + css_class + '">' + this.options.text + '</div>');

      this.element.wrap('<div style="position: relative;"/>');

      placeholder
          .zIndex(this.element.zIndex() + 1)
          .insertBefore(this.element)
          .on('click', function() {
            that.element.trigger('focus');
          }).on('focus', function() {
            that.element.trigger('focus');
          });

      this.placeholder = placeholder;

      this.element
          .on("change.placeholder", function() {
            that.refresh();
            return true;
          }).on("keydown.placeholder", function(event) {
            if (event.keyCode !== $.ui.keyCode.ESCAPE) {
              that.hide();
            }
            return true;
          }).on("blur.placeholder", function() {
            that.refresh();
            return true;
          });
      this.refresh();
    },

    destroy: function() {
      if (this.placeholder) {
        this.element.unbind('*.placeholder');
        this.placeholder.remove();
        $.Widget.prototype.destroy.call(this);
      }
    }

  });

} (jQuery));