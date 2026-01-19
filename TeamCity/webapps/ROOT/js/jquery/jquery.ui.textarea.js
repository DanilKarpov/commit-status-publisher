/**
 * TextAreaExpander plugin for jQuery
 * v1.0
 * Expands or contracts a textarea height depending on the
 * quantity of content entered by the user in the box.
 *
 * By Craig Buckler, Optimalworks.net
 *
 * As featured on SitePoint.com:
 * http://www.sitepoint.com/blogs/2009/07/29/build-auto-expanding-textarea-1/
 *
 * Please use as you wish at your own risk.
 *
 * Contains modifications by Pavel Sher, Leonid Khachaturov
 */

/**
 * Usage:
 *
 * From JavaScript, use:
 *     $(<node>).textAreaExpander(<minHeight>, <maxHeight>);
 *     where:
 *       <node> is the DOM node selector, e.g. "textarea"
 *       <minHeight> is the minimum textarea height in pixels (optional)
 *       <maxHeight> is the maximum textarea height in pixels (optional)
 *
 *     `js_expandable_no-manual` removes native resize handler from the <node>
 */

(function($) {

	// jQuery plugin definition
	$.fn.textAreaExpander = function(minHeight, maxHeight, source) {

		var hCheck = !(BS.Browser.msie || BS.Browser.opera);

		// resize a textarea
		function resizeTextarea(e) {
			// event or initialize element?
			e = e.target || e;
			// due to `box-sizing: border-box` for <textarea> in main.css
			var verticalAddition = parseInt(window.getComputedStyle(e)['border-top-width'], 10) +
								   parseInt(window.getComputedStyle(e)['border-bottom-width'], 10);
			var hasManualResize = e.className.indexOf('js_expandable_no-manual') === -1;

			// find content length and box width
			var vlen = e.value.length, ewidth = e.offsetWidth;

			if (vlen != e.valLength || ewidth != e.boxWidth) {
				if (!hasManualResize && hCheck && (vlen < e.valLength || ewidth != e.boxWidth)) e.style.height = '0';

				var h = Math.max(e.expandMin, Math.min(e.scrollHeight, e.expandMax));

                // When content is tall, allow the standard browser resizer in addition to auto expansion.
                // Addresses TW-19254
				if (e.scrollHeight > h) {
                  e.style.overflow = 'auto';
                  e.style.resize = 'both';
                }  else {
                  e.style.overflow = 'hidden';

                  if (!hasManualResize) {
				    e.style.resize = 'none';
				  }
                }

				e.style.height = Math.max(h, e.scrollHeight) + verticalAddition + 'px';

                if (jQuery(e).parents('.modalDialog').length > 0) {
                  e.style.maxHeight = maxHeight + 'px';
                }

				e.valLength = vlen;
				e.boxWidth = ewidth;

                if (BS.MultilineProperties) {
                  if (!source || source != 'updateVisibility') {
                    BS.MultilineProperties.updateVisible();
                  }
                }
			}

			return true;
		};

		// initialize
		this.each(function() {
			// is a textarea?
			if (this.nodeName.toLowerCase() != "textarea") return;

			// set height restrictions
			this.expandMin = minHeight || 0;
			this.expandMax = maxHeight || 99999;

			// initial resize
			resizeTextarea(this);

			// zero vertical padding and add events
			if (!this.initialized) {
				this.initialized = true;
                var $el = $(this);
				$el.css({
                  "padding-top": 0,
                  "padding-bottom": 0
                });
                // Listen to mouseup to detect native resize
				$el.bind("keyup mouseup focus", resizeTextarea);
			}
		});

		return this;
	};

})(jQuery);
