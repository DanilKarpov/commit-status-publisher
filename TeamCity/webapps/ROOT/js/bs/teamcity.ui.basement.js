/*
    <div id="basement" style="display: none;">
      <div class="splitter"></div>
      <a href="#" class="hider">x</a>
      <div id="basementInner"></div>
    </div>

    also, basement.css

* */
(function($) {

$.fn.basement = function(options) {
  var $doc = $(document);
  var jqueryShow = $.fn.show;

  var config = {};

  $.extend(config, options || {});

  var that = this;
  this.children(".hider").click(function(e) {
    that.hide();
  });

  var isMoving = false;
  $doc.mousedown(function(e) {
    if (Math.abs(that.offset().top - e.pageY) < 5) {
      isMoving = true;
    }
  });

  $doc.mouseup(function(e) {
    isMoving = false;
    that.trigger("resize");
  });

  $doc.mousemove(function(e) {
    if (isMoving) {
      var newHeight = $doc.scrollTop() + $(window).height() - e.pageY;
      that.css("height", newHeight + "px");
    }
  });

  return this.extend({
    show: function() {
      if (this.is(":hidden")) {
        this.css({height: 0});
        jqueryShow.apply(this, arguments);
        this.animate({height: "30%"}, "fast");
      }
    }
  });
};

})(jQuery);


BS.Basement = {
  show: function() {
    if (!this.basement) {
      BS.Basement.onResize = BS.Basement.onResize || function() {};
      this.basement = jQuery('#basement').basement();
      this.basement.on('resize', BS.Basement.onResize);
    }
    this.basement.show();
  },

  hide: function() {
    if (this.basement) {
      this.basement.hide();
    }
  },

  updateContent: function(content) {
    jQuery('#basementInner').html(content);
  }
};