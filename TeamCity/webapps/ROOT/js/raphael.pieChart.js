/**
 * @param cx  x-center
 * @param cy  y-center
 * @param r   radius
 * @param values    array of sector values
 * @param bgColors  array of sector colors
 * @returns {Array} array of created sector elements
 */
Raphael.fn.pieChart = function (cx, cy, r, values, bgColors) {

  if (values.length > bgColors.length) {
    throw "Error, values and colors sizes mismatch: " + values.toString() + " " + bgColors.toString();
  }

  var paper = this,
      rad = Math.PI / 180,
      chart = this.set();

  function sector(cx, cy, r, startAngle, endAngle, params) {
    if (endAngle - startAngle == 360) {
      return paper.circle(cx, cy, r).attr(params);
    }
    startAngle += 90;
    endAngle += 90;

    var x1 = cx + r * Math.cos(-startAngle * rad),
        x2 = cx + r * Math.cos(-endAngle * rad),
        y1 = cy + r * Math.sin(-startAngle * rad),
        y2 = cy + r * Math.sin(-endAngle * rad);
    return paper.path(["M", cx, cy, "L", x1, y1, "A", r, r, 0, +(endAngle - startAngle > 180), 0, x2, y2, "z"]).attr(params);
  }

  var total = 0,
      count = values.length;

  for (var i = 0; i < count; i++) {
    total += values[i];
  }

  var angle = 360;
  for (i = 0; i < count; i++) {
    var value = values[i],
        angleplus = 360 * value / total,
        bcolor = bgColors[i];

    var p = sector(cx, cy, r, angle - angleplus, angle, {fill: bcolor, "stroke-width": '0'});

    angle -= angleplus;
    chart.push(p);
  }

  return chart;
};
