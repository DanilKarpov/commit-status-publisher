BS.Overflower = function(element, tooltipBgcolor) {
  this.element = element;
  this.background = "#ffffcc";
  //alert(1);
  if (typeof tooltipBgcolor != 'undefined') {
    this.background = tooltipBgcolor;
  }
};

/** Returns true, if element content overflows it's dimensions */
BS.Overflower.prototype.isOverflown = function() {
  var el = $(this.element);
  var curr = [el.offsetWidth, el.offsetHeight];
  var oldOverflow = el.getStyle("overflow");

  el.style.overflow = "auto";
  var newVal = [el.offsetWidth, el.offsetHeight];
  el.style.overflow = oldOverflow;
  return (curr[0] != newVal[0] || curr[1] != newVal[1]);
};

BS.Overflower.prototype.installTooltip = function() {

  this.element.style.overflow = "hidden";
  this.element.style.textOverflow = "ellipsis";

  $(this.element).on("mouseover", function() {
    if (!this.isOverflown()) return;

    if (!this.tooltip) {
      var tt = document.createElement("div");
      tt.style.position = 'absolute';
      tt.style.width = 'auto';
      tt.style.height = 'auto';
      tt.style.zIndex = '300';
      if (this.background) {
        tt.style.backgroundColor = this.background;
      }
      $(tt).on("mouseout", function() {
        this.style.display = 'none';
      }.bindAsEventListener(tt));

      this.tooltip = tt;
      this.element.parentNode.insertBefore(this.tooltip, this.element); // To make styles as consistent as possible
    }

    var p = $(this.element).positionedOffset();
    this.tooltip.style.left = p[0] + "px";
    this.tooltip.style.top = p[1] + "px";

    this.tooltip.innerHTML = this.element.innerHTML;
    this.tooltip.style.display = 'block';

  }.bindAsEventListener(this));
};
