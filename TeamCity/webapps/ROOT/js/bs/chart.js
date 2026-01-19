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
 * User: Andrei Titov
 * Date: 12/24/12
 */

BS.Chart = function (chartHolder, id, styles, _options) {
  var dataset = null; // flot data JSON
  var datasetTC = null; // TC chart JSON
  var chartId = id;
  var plot = null;
  var colors = null;
  var builds = null;

  this.isEmpty = function () {
    return dataset.length !== undefined && (dataset == null || dataset.length == 0);
  };

  var tickColor = window?.getComputedStyle(document?.body)?.getPropertyValue('--ring-line-color') || '#dfe5eb';

  var options = {
    grid: {
      hoverable: true,
      clickable: true,
      borderWidth: 0.8,
      autoHighlight: false
    },
    yaxis: {
      min: 0,
      minTickSize: 0.1,
      tickDecimals: 1,
      tickColor: tickColor,
      color: "black",
      labelWidth: 35,
      reserveSpace: true,
      tickFormatter: function (tick) {
        return BS.Chart.prettyPrint(parseFloat(tick)) + "";
      }
    },
    xaxes: [
      { // vertical grid for each build without tick labels
        min: -0.9,
        tickFormatter: function () {
          return "";
        },
        tickSize: 1,
        tickColor: tickColor,
        position: "top"
      },
      { // labels for some builds
        min: -0.9,
        color: "black",
        tickDecimals: 0,
        tickColor: tickColor,
        tickLength: 5
      }
    ],
    selection: {
      mode: "x"
    },
    legend: {
      show: false
    },
    BSChart: {
      splitLines: true,
      format: "text",
      averaged: false,
      hideFailed: false,
      hideZero: false,
      pointClicker: function (item, options) {
      },
      minFormatter: function (val) {
        return val;
      },
      maxFormatter: function (val) {
        return val;
      },
      onHighlightSerie: function () {
      },
      onUnhighlightSerie: function () {
      },
      toggleSerie: function () {
      },
      toolTip: function (item, options) {
      },
      customMax: false,
      customMin: false,
      defaultMax: null,
      average: {
        enabled: false,
        disableOtherSeries: true,
        compact: true,
        groupBy: "today"
      }
    }
  };

  this.getOptions = function () {
    return options;
  };

  this.containsNotNullData = function () {
    if (this.isEmpty()) return false;
    for (var i = 0; i < dataset.length; ++i) {
      if (BS.Chart._def(dataset[i].data)) {
        for (var j = 0; j < dataset[i].data.length; ++j) {
          if (dataset[i].data[j][1] != null && dataset[i].data[j][1] != "null") {
            return true;
          }
        }
      } else {
        for (j = 0; j < dataset[i][j].length; ++j) {
          if (dataset[i][j][1] != null && dataset[i][j][1] != "null") {
            return true;
          }
        }
      }
    }
    return false;
  };

  this.setMin = function (min) {
    options.yaxis.min = parseFloat(options.BSChart.minFormatter(min));
    options.BSChart.customMin = min != null;
  };

  this.setMax = function (max) {
    options.yaxis.max = parseFloat(options.BSChart.maxFormatter(max));
    options.BSChart.customMax = max != null;
  };

  this.extendOptions = function (styles) {
    var temp = {};
    for (var i = 0; i < styles.length; ++i) {
      if (BS.Chart._def(BS.Chart.Styles[styles[i]])) {
        jQuery.extend(true, temp, BS.Chart.Styles[styles[i]]);
      } else if (BS.Chart._def(BS.Chart.Formats[styles[i]])) {
        jQuery.extend(true, temp, BS.Chart.Formats[styles[i]]);
      } else {
        jQuery.extend(true, temp, styles[i]);
      }
    }
    jQuery.extend(true, options, temp);
  };

  this.setColors = function (colors) {
    options.BSChart.colors = colors;
  };

  this.rerenderBuildChart = function() {
    plot.getPlaceholder().trigger("plotunselected");
    return this.doRenderChart(datasetTC, colors, builds)
  };

  this.doRenderChart = function (rawData, _colors, _builds) {
    var _dataset;
    if (rawData && _colors && _builds) _dataset = BS.Chart.extractRawData(rawData || datasetTC, _colors || colors, options, _builds || builds);
    else _dataset = rawData;
    if (_builds) chartHolder.data("buildsInfo", _builds);


    dataset = _dataset || dataset;
    datasetTC = rawData || datasetTC;
    colors = _colors || colors;
    builds = _builds || builds;

    if (this.isEmpty() || !this.containsNotNullData()) {
      options.yaxis.show = false;
      options.selection.mode = null;
    }

    plot = jQuery.plot(chartHolder, dataset, options);
    plot.unhighlightSerie = function (serie) {
      options.BSChart.onUnhighlightSerie(serie);
    };
    plot.highlightSerie = function (serie) {
      options.BSChart.onHighlightSerie(serie);
    };
    plot.toggleSerie = function (serie) {
      options.BSChart.toggleSerie(serie);
    };
    plot.showToolTip = function (item) {
      var _tip;
      if (BS.Chart._def(options.BSChart.toolTip)) {
        if (typeof options.BSChart.toolTip === 'function') {
          _tip = options.BSChart.toolTip(item, options);
        } else {
          _tip = options.BSChart.toolTip[item];
        }
      } else {
        _tip = "value: " + item.datapoint[0];
      }

      var x = BS.Chart._def(item.pageX) ? item.pageX : $j(chartHolder).offset().left;
      var y = BS.Chart._def(item.pageY) ? item.pageY : $j(chartHolder).offset().top;

      BS.Chart.toolPopup.showTipAtPagePoint($(chartHolder), _tip, x, y);
    };

    if (this.isEmpty() || !this.containsNotNullData()) {
      var text;
      if (!this.containsNotNullData()) {
        text = "No data in builds";
      } else {
        text = "No builds available";
      }
      chartHolder.append('<div class="no_data_label">' + text + '</div>');
    }

    return plot;
  };

  this.renderChart = function (rawData, _colors, _builds) {
    function bindMouseListeners() {
      BS.Chart.CtrlKeyEventListeners.push(chartHolder.get(0));

      var selectionEvent = false;
      var yMin = null, yMax = null;
      var xMin = null, xMax = null;
      chartHolder.bind("plotselected", function (event, ranges) {
        plot.isSelected = true;
        selectionEvent = true;
        var opts = plot.getOptions();
        for (var i = 0; i < opts.xaxes.length; ++i) {
          if (xMin == null && xMax == null) {
            xMin = opts.xaxes[1].min;
            xMax = opts.xaxes[1].max;
          }
          opts.xaxes[i].min = ranges.xaxis.from;
          opts.xaxes[i].max = ranges.xaxis.to;
        }
        var yaxes = plot.getYAxes();
        for (i = 0; i < opts.yaxes.length; ++i) {
          if (yMin == null && yMax == null) {
            yMin = opts.yaxes[0].min;
            yMax = opts.yaxes[0].max;
          }
          if (Math.abs(yaxes[i].min - ranges.yaxis.from) > 0.01 || Math.abs(yaxes[i].max - ranges.yaxis.to) > 0.01) {
            opts.yaxes[i].min = ranges.yaxis.from;
            opts.yaxes[i].max = ranges.yaxis.to;
          }
        }
        plot.setupGrid();
        plot.draw();
        plot.setSelection(ranges, true);
      });
      chartHolder.bind("plotunselected", function (/*event*/) {
        // The event is fired even when no selection present on the chart. Moreover plot.getSelection() will always return null here
        if (plot.isSelected) {
          plot.isSelected = false;
          selectionEvent = true;
          var opts = plot.getOptions();
          for (var i = 0; i < opts.xaxes.length; ++i) {
            opts.xaxes[i].min = xMin;
            opts.xaxes[i].max = xMax;
          }
          for (i = 0; i < opts.yaxes.length; ++i) {
            opts.yaxes[i].min = yMin;
            opts.yaxes[i].max = yMax;
          }
          plot.setupGrid();
          plot.draw();
          yMin = yMax = xMin = xMax = null;
          plot.setSelection({}, false);
        }
      });
      chartHolder.bind("plotclick", function (event, pos, item) {
        if (item && !selectionEvent) {
          options.BSChart.pointClicker(item, options);
        }
        selectionEvent = false;
      });
    }

    bindMouseListeners();

    return this.doRenderChart(rawData, _colors, _builds);
  };

  this.setMessage = function (message) {
    var $label = chartHolder.find(".no_data_label");
    if (message) {
      if ($label.length > 0) {
        $label.text(message);
      } else {
        chartHolder.append('<div class="no_data_label">' + message + '</div>');
      }
    } else {
      $label.remove();
    }
  };

  this.onHighlightSerie = function (serieName) {
    var data = plot.getData();
    for (var i = 0; i < data.length; ++i) {
      if (data[i].labelId == serieName || !serieName) {
        if (!plot.getData()[i].highlighted) {
          plot.getData()[i].highlighted = true;
          options.BSChart.onHighlightSerie(plot.getData()[i]);
          plot.draw();
        }
        return;
      }
    }
  };

  this.onUnhighlightSerie = function (serieName) {
    var data = plot.getData();
    for (var i = 0; i < data.length; ++i) {
      if (data[i].labelId == serieName || !serieName) {
        if (plot.getData()[i].highlighted) {
          plot.getData()[i].highlighted = false;
          options.BSChart.onUnhighlightSerie(plot.getData()[i]);
          plot.draw();
        }
        return;
      }
    }
  };

  this.toggleSerie = function (serieId) {
    this.onUnhighlightSerie(serieId);

    for (var sId in datasetTC.series) {
      if (datasetTC.series.hasOwnProperty(sId) && sId == serieId) {
        datasetTC.series[sId].enabled = typeof datasetTC.series[sId].enabled === "boolean" ? !datasetTC.series[sId].enabled : false;
        break;
      }
    }
    this.rerenderBuildChart();
  };

  this.togglePersonal = function(state) {
    options.BSChart.hidePersonal = state || !(options.BSChart.hidePersonal || false);
    this.rerenderBuildChart();
  };

  this.setSerieEnabled = function (/*String*/ serieId, /*boolean*/ enabled) {
    this.onUnhighlightSerie(serieId);

    if (serieId != null) {
      datasetTC.series[serieId].enabled = enabled;
    } else {
      for (var sId in datasetTC.series) {
        if (datasetTC.series.hasOwnProperty(sId)) {
          datasetTC.series[sId].enabled = enabled;
        }
      }
    }
    this.rerenderBuildChart();
  };

  this.getChart = function () {
    return plot;
  };

  this.getId = function () {
    return chartId;
  };

  if (BS.Chart._def(styles) && styles.length > 0) {
    this.extendOptions(styles);
  } else {
    this.extendOptions(["line", "float"]);
  }
  if (BS.Chart._def(_options)) {
    this.extendOptions([_options]);
  }
};

BS.Chart.extractMarkings = function (data) {
  var points = [];
  var point = null;
  for (var series in data.data) {
    for (var i = 0; i < data.data[series].length; ++i) {
      point = data.data[series][i];
      var build = point.buildInfo;
      if (BS.Chart._def(build)) {
        if (build.status == 'FAILURE') {
          if (jQuery.inArray(point[0], points) < 0) {
            points.push(point[0]);
          }
        }
      }
    }
  }
  var markings = [];
  for (i = 0; i < points.length; ++i) {
    var m = points[i];
    markings.push({
                    color: "rgba(255,0,0,0.4)",
                    lineWidth: 1,
                    xaxis: {from: m, to: m}
                  });
  }
  return markings;
};

BS.Chart.extractColors = function (data, colors) {
  var result = [];
  if (!BS.Chart._def(colors) || !BS.Chart._def(colors.series)) {
    return result;
  }
  for (var serie in data.data) {
    if (BS.Chart._def(colors.series[serie])) {
      result.push(colors.series[serie]);
    } else {
      result.push(null);
    }
  }
  return result;
};

/*
 takes data in format {<serieName1>: [[<p1>], [<p2>]], <serieName2>: [[<points]]} and colors in format {series: {<serieName1>: <color1>, <serieName2>: <color2>}}
 returns array in format [{data: [[<p1>], [<p2>]], color: <color1>}, {data: [[<points>]], color: <color2>}]
 */
BS.Chart.extractRawData = function (data, colors, options, buildsInfo) {
  function getWeekNumber(d) {
    // Copy date so don't modify original
    d = new Date(+d);
    d.setHours(0,0,0);
    // Set to nearest Thursday: current date + 4 - current day number
    // Make Sunday's day number 7
    d.setDate(d.getDate() + 4 - (d.getDay()||7));
    // Get first day of year
    var yearStart = new Date(d.getFullYear(),0,1);
    // Calculate full weeks to nearest Thursday
    var weekNo = Math.ceil(( ( (d - yearStart) / 86400000) + 1)/7);
    return weekNo;
  }

  function getGroup(/*string*/ groupBy, date) {
    date = new Date(+date);
    switch (groupBy) {
      case "today":
        return date.getFullYear() + " " + date.getMonth() + " " + date.getDate() + date.getHours();
      case "week": case "month":
        return date.getFullYear() + " " + date.getMonth() + " " + date.getDate();
      case "year":
        return date.getFullYear() + " " + getWeekNumber(date);
      case "quarter": case "all": default:
        return date.getFullYear() + " " + date.getMonth();
    }
  }

  function month(n) {
    switch (n) {
      case 0: return "Jan";
      case 1: return "Feb";
      case 2: return "Mar";
      case 3: return "Apr";
      case 4: return "May";
      case 5: return "Jun";
      case 6: return "Jul";
      case 7: return "Aug";
      case 8: return "Sep";
      case 9: return "Oct";
      case 10: return "Nov";
      case 11: return "Dec";
    }
    return "";
  }

  function label(groupBy, timestamp) {
    var date = new Date(timestamp);
    switch (groupBy) {
      case "today":
        return date.getHours() + "h";
      case "week": case "month":
      return date.getDate() + " " + month(date.getMonth());
      case "year":
        return "week " + getWeekNumber(date);
      case "quarter": case "all": default:
      return month(date.getMonth()) + " " + date.getFullYear();
    }
  }
  var tickNames = {};

  var points = [];
  var point = null;
  var containsData = false;
  var dataset = [];
  // noinspection SpellCheckingInspection
  var datamin = Number.MAX_VALUE, datamax = Number.MIN_VALUE;
  for (var series in data.data) {

    var dataObj = {
      data: [],
      enabled: data.series[series] && typeof data.series[series].enabled === "boolean" ? data.series[series].enabled : true,
      xaxis: 2,
      labelId: series,
      label: data.series[series],
      serieInfo: data.series[series]
    };

    // setting color for each serie if the color exists
    if (BS.Chart._def(colors) && BS.Chart._def(colors.series) && BS.Chart._def(colors.series[series])) {
      dataObj.color = colors.series[series];
    }

    var initData = data.data[series];
    for (var i = 0, prev, curr; i < initData.length; ++i) {
      if (initData[i][0] > datamax) datamax = initData[i][0];
      if (initData[i][0] < datamin) datamin = initData[i][0];
      if (!dataObj.enabled) continue;

      point = initData[i].slice();

      if (BS.Chart._def(buildsInfo[point[0]])) {
        if (options.BSChart.hidePersonal && buildsInfo[point[0]].isPersonal) {
          continue;
        }
      }

      dataObj.data.push(point);

      prev = curr;
      curr = point;
      if (BS.Chart._def(buildsInfo[point[0]])) {
        curr.buildInfo = buildsInfo[point[0]];
        if (buildsInfo[point[0]].status == 'FAILURE') {
          if (jQuery.inArray(point[0], points) < 0) {
            curr.marked = 'true';
          }
        }
        if (buildsInfo[point[0]].current == true) {
          curr.current = 'true';
        }
      }
      if (curr[1] != "null") {
        containsData = true;
      }
    }

    data.containsData = containsData;

    dataset.push(dataObj);
  }

  if (options.BSChart.average && options.BSChart.average.enabled && buildsInfo) {
    var averageDataObj = {
      average: true,
      data: [],
      enabled: true,
      xaxis: 2,
      labelId: -1,
      label: "Average",
      color: "#008021",
      serieInfo: {name: "Average", enabled: true}
    };
    var temp = {};
    for (i = 0; i < dataset.length; ++i) {
      if (!dataset[i].enabled) continue;

      for (var j = 0; j < dataset[i].data.length; ++j) {
        point = dataset[i].data[j];
        var y = point[0];
        temp[y] = temp[y] || {count: 1, value: 0};
        temp[y].value += (+point[1]);
      }

      dataset[i].enabled = !options.BSChart.average.disableOtherSeries;
    }

    var averageBy = options.BSChart.average.groupBy;
    var grouped = averageDataObj.data;
    var prevGroup = null, groupIdx = 0;
    for (y in temp) {
      if (temp.hasOwnProperty(y)) {
        var group = getGroup(averageBy, buildsInfo[y].date);
        if (prevGroup == null) {
          prevGroup = group;
          grouped[groupIdx] = [y, temp[y].value, 0, temp[y].count, label(averageBy, buildsInfo[y].date)];
        } else {
          if (group != prevGroup) {
            prevGroup = group;
            grouped[++groupIdx] = [y, 0, 0, 0, label(averageBy, buildsInfo[y].date)];
          }
          grouped[groupIdx][1] += temp[y].value;
          grouped[groupIdx][3] += temp[y].count;
        }
      }
    }

    if (options.BSChart.average.compact) {
      for (i = 0; i < grouped.length; ++i) {
        grouped[i][0] = i;
      }
    }

    dataset.push(averageDataObj);

    options.xaxis.tickIndexToName = function(n, axis) {
      return grouped[n] ? grouped[n][4] : "";
    };
  } else if (options && options.xaxis) {

    options.xaxis.tickIndexToName = function (n, axis) {
      return tickNames[n] || "";
    };
  }

  for (i = 0; i < dataset.length; ++i) {
    if (!dataset[i].enabled) {
      dataset[i].data = [];
    }
  }

  if (datamin < Number.MAX_VALUE && datamax > Number.MIN_VALUE) {
    var shift = 0;
    for (i = datamin; i <= datamax; ++i) {
      var contains = false;
      for (j = 0; j < dataset.length; ++j) {
        for (var k = 0; k < dataset[j].data.length; ) {
          var found = false;
          while (dataset[j].data[k] && dataset[j].data[k][0] == i) {
            dataset[j].data[k][0] -= shift;
            contains = found = true;
            ++k;
          }
          if (found) break;
          ++k;
        }
      }
      if (!contains) {
        shift++;
      }
    }
  }

  if (options.BSChart.splitLines) {
    for (i = 0; i < dataset.length; ++i) {
      for (j = 0; j < dataset[i].data.length; ++j) {
        prev = curr;
        curr = dataset[i].data[j];
        if (prev && (curr[0] - prev[0]) > 1) {
          dataset[i].data.splice(j, 0, [prev[0], null, "splitMarker"]);
        }
      }
    }
  }

  for (i = 0; i < dataset.length; ++i) {
    if (dataset[i].enabled) {
      for (j = 0; j < dataset[i].data.length; ++j) {
        if (dataset[i].data[j].buildInfo) tickNames[dataset[i].data[j][0]] = dataset[i].data[j].buildInfo.name;
      }
    }
  }

  dataset.push({data: [], xaxis: 1});

  return dataset;
};

BS.Chart.Styles = {
  bar: {
    xaxis: {
      addSpace: function(xAxes) {
        var max = xAxes[0].datamax;
        for (var i = 1; i < xAxes.length; ++i) {
          if (BS.Chart._def(xAxes[i].options.max) && xAxes[i].options.max != null) return xAxes[i].options.max;
          if (xAxes[i].datamax > max || max == null) {
            max = xAxes[i].datamax;
          }
        }
        return max + 0.5;
      }
    },
    series: {
      bars: {
        show: true,
        align: "center"
      }
    },
    selection: {
      mode: null
    }
  },
  line: {
    series: {
      lines: {
        show: true,
        lineWidth: 1,
        selectedWidth: 2
      },
      shadowSize: 1
    },
    BSChart: {
      onHighlightSerie: function (serie) {
        if (!BS.Chart._def(serie.lines.unselectedWidth)) {
          serie.lines.unselectedWidth = serie.lines.lineWidth;
        }
        serie.lines.lineWidth = serie.lines.selectedWidth;
      },
      onUnhighlightSerie: function (serie) {
        serie.lines.lineWidth = serie.lines.unselectedWidth;
      },
      toggleSerie: function (serie) {
        serie.lines.show = !serie.lines.show;
      }
    }
  },
  mergeLines: {
    BSChart: {
      splitLines: false
    }
  },
  point: {
    series: {
      points: {
        selectedRadius: 3.5,
        show: true,
        radius: 2.5,
        lineWidth: 1,
        symbol: "circle"
      }
    },
    BSChart: {
      onHighlightSerie: function (serie) {
        if (!BS.Chart._def(serie.points.unselectedRadius)) {
          serie.points.unselectedRadius = serie.points.radius;
        }
        BS.Chart.Styles.line.BSChart.onHighlightSerie(serie);
        serie.points.radius = serie.points.selectedRadius;
      },
      onUnhighlightSerie: function (serie) {
        BS.Chart.Styles.line.BSChart.onUnhighlightSerie(serie);
        serie.points.radius = serie.points.unselectedRadius;
      },
      toggleSerie: function (serie) {
        BS.Chart.Styles.line.BSChart.toggleSerie(serie);
        serie.points.show = !serie.points.show;
      }
    }
  },
  averaged: {
    BSChart: {
      average: {
        enabled: true
      }
    }
  },
  hideFailed: {
    BSChart: {
      hideFailed: true
    }
  },
  hideZero: {
    yaxis: {
      min: null
    },
    BSChart: {
      hideZero: true
    }
  },
  log: {
    yaxis: {
      transform: function (num) {
        if (num == 0) {
          return 0;
        } else {
          if (num > 0) {
            return Math.log(num + 1);
          } else {
            return -Math.log(-num + 1);
          }
        }
      },
      inverseTransform: function (num) {
        if (num >= 0) {
          return Math.exp(num) - 1;
        } else {
          return -Math.exp(-num) - 1;
        }
      },
      ticks: function (axis) {
        function signedLog(n) {
          if (n > 0) {
            return Math.log(n);
          } else if (n < 0) {
            return -Math.log(-n);
          } else return 0;
        }

        function signedPow(n, pow) {
          if (n == 1) {
            return pow;
          }
          if (pow > 0) {
            return Math.pow(n, pow);
          } else if (pow < 0) {
            return -Math.pow(n, -pow - 1);
          } else return 1;
        }

        var prevVal = null;

        function formatTick(tickNumber, val, axis, num) {
          var label;
          if (num >= 10 && tickNumber % 2 != 0) {
            label = "";
          } else {
            label = axis.tickFormatter(val, axis);
            prevVal = val;
          }
          return [val, label];
        }

        var max = axis.options.max == null ? axis.datamax : axis.options.max;
        var min;
        if (axis.options.min == null) {
          //axis.min = axis.options.min = Math.floor(axis.datamin / 4);
          min = axis.options.min != null ? Math.min(axis.datamin, axis.options.min) : axis.datamin;
        } else {
          min = axis.options.min;
        }

        var N = 10, NMax, NMin;
        var log10 = Math.log(10);
        if (max < 10 && min > -10) {
          N = 1;
          NMax = Math.floor(max);
          NMin = Math.floor(min);
        } else {
          NMax = Math.floor(signedLog(max) / log10);
          NMin = Math.ceil(signedLog(min) / log10) - 1;
        }

        var ticks = [];
        for (var i = NMin, j = 0; i <= NMax + 1; ++i, ++j) {
          ticks[j] = formatTick(j, signedPow(N, i), axis, NMax - NMin);
        }

        return ticks;
      }
    }
  }
};

BS.Chart.createBuildChart = function (chartHolder, data, id, styles, colors, showBranches, showBuildType, options) {
  function makeBuildToolTipMessage(item, build, options) {
    var serieName;
    var i = 0;
    serieName = item.series.label.name;

    var valuePart = "Value: <b>" + options.yaxis.tickFormatter(item.datapoint[1]) + "</b>";
    var branchPart = "";
    if (build.branchName && !options.BSChart.average.enabled) {
      branchPart = "<br>Branch: <span class='branch hasBranch'>" +
        (ReactUI
          ? ReactUI.createAndRenderStatic(ReactUI.BuildBranch, {
            name: build.branchName,
            noLink: true,
            tailLength: 0
          })
          : "<span class='branchName'>" + build.branchName + "</span>")
        + "</span>";
    }
    if (options.BSChart.average.enabled) {
      return valuePart + "<br>Builds: " + item.datapoint[3] + "<br>Period: " + item.datapoint[4] + branchPart;
    } else {
      if (!build.linkable) {
        return valuePart + "<br>Build: #" + build.name + "<img class='icon' src='img/buildStates/" + (build.status == 'FAILURE' ? "error" : "success") + "_small.png'>" + build.statusText
               + "<br>Started: " + BS.Chart.dateFormat(build.date)
               + "<br>Series: " + serieName + branchPart + "<br><i>Build is already cleaned up from the history</i>";
      } else {
        return valuePart + "<div id='statisticsBuildDescription'></div>Series: " + serieName
          + "<br><script>BS.Chart.showSpinner($j('#statisticsBuildDescription'));"
          + "BS.ajaxUpdater($('statisticsBuildDescription'), window['base_uri'] + '/statisticsbuilddescription.html', {parameters: {showBranch: "
          + showBranches + ",buildId: '" + build.id + "', buildTypeExtId: '" + build.buildTypeId + "', showBuildType: '" + showBuildType + "'}, evalScripts: true});</script>";
      }
    }
  }

  var builds = data.builds;
  if (!BS.Chart._def(styles) || styles == null) {
    styles = [];
  }
  styles.push({
                BSChart: {
                  toolTip: function (item, options) {
                    return makeBuildToolTipMessage(item, item.series.data[item.dataIndex].buildInfo || builds[item.datapoint[0]], options);
                  }, pointClicker: function (item, options) {
                    if (!options.BSChart.average.enabled) {
                      var build = item.series.data[item.dataIndex].buildInfo;
                      if (build.linkable) {
                        // noinspection SpellCheckingInspection
                        var w = window.open(window['base_uri'] + "/viewLog.html?buildTypeId=" + build.buildTypeId + "&buildId=" + build.id, '_blank', 'noopener=yes,noreferrer=yes');
                        w.focus();
                      }
                    }
                  }
                },
                xaxis: {
                  tickFormatter: function (num, axis) {
                    if (axis.options.tickIndexToName) {
                      return axis.options.tickIndexToName(num);
                    }
                    return num;
                  }
                }
              });
  var chart = new BS.Chart(chartHolder, id, styles, options);
  chartHolder.data("chart", chart);

  chart.setColors(colors);
  BS.Chart.parseYAxisOptions(id, chart);

  var plot = chart.renderChart(data, colors, builds);
  plot.buildsInfo = builds;
  chartHolder.data("plot", plot);
};

BS.Chart.prettyPrint = function (number) {
  number += '';
  var spl = number.split('.');
  var reg = /(\d+)(\d{3})/;
  while (reg.test(spl[0])) {
    spl[0] = spl[0].replace(reg, '$1' + ',' + '$2')
  }
  if (spl.length > 1) {
    spl[0] += '.' + spl[1];
  }
  return spl[0];
};

BS.Chart.Formats = OO.extend({
  text: {
    BSChart: {
      format: "float",
      description: "Float"
    },
    yaxis: {
      tickFormatter: function (tick, axis) {
        var number = parseFloat(tick);
        if (axis && axis.max != axis.min) {
          var log10 = Math.log10(Math.abs(axis.max - axis.min));
          var nearestPowerOf10 = Math.pow(10, -(log10 > 0 ? Math.ceil(log10) : Math.floor(log10)) + 2);
          number = Math.round(number * nearestPowerOf10) / nearestPowerOf10;
        }
        return BS.Chart.prettyPrint(number + "");
      }
    }
  },
  integer: {
    BSChart: {
      format: "int",
      description: "Integer"
    },
    yaxis: {
      minTickSize: 1,
      tickFormatter: function (tick) {
        return BS.Chart.prettyPrint(parseInt(tick)) + "";
      }
    }
  },
  duration: {
    BSChart: {
      format: "duration",
      description: "Time (ms)"
    },
    yaxis: {
      tickFormatter: function (milliseconds) {
        function fmtLeft(string, t) {
          var fl = Math.round(string);
          if (fl < 10) {
            return "0" + fl + t;
          }
          return fl + t;
        }

        var sign = milliseconds >= 0 ? "" : "-";
        milliseconds = Math.abs(milliseconds);
        if (milliseconds < 1000) {
          return sign + milliseconds.toFixed(0) + "ms";
        } else if (milliseconds < 1000 * 60) {
          return sign + milliseconds.toFixed(0) / 1000 + "s";
        } else if (milliseconds < 1000 * 60 * 60) {
          return sign + Math.floor(milliseconds / 60000) + "m:" + fmtLeft(milliseconds / 1000 % 60, "s");
        } else if (milliseconds < 1000 * 60 * 60 * 24) {
          return sign + Math.floor(milliseconds / 3600000) + "h:" + fmtLeft(milliseconds / 60000 % 60, "m");
        }
        return sign + Math.floor(milliseconds / 86400000) + "d:" + fmtLeft(milliseconds / 3600000 % 24, "h");
      },
      ticks: function(axis) {
        var max, min;
        if (axis.datamin == axis.datamax && axis.min != 0 && axis.max != 0) {
          max = axis.options.max == null ? axis.datamax + 1 : axis.options.max;
          min = axis.options.min == null ? axis.datamin - 1 : axis.options.min;
          return [min, axis.datamax, max];
        } else {
          max = axis.options.max == null ? axis.max != null ? axis.max : axis.datamax : axis.options.max;
          min = axis.options.min == null ? axis.min != null ? Math.min(axis.datamin, axis.min) : axis.datamin : axis.options.min;
        }

        var dt = max - min;

        var tickSizes = [1, 2, 5, 10, 25, 50, 100, 200, 500, // milliseconds
                         1000, 2000, 5000, 10000, 20000, 30000, // 1, 2, 5, 10, 20, 30 seconds
                         60000, 120000, 300000, 600000, 1200000, 1800000, // 1, 2, 5, 10, 20, 30 minutes
                         3600000, 7200000, 10800000, 14400000, 18000000, 21600000, 43200000, // 1, 2, 3, 4, 5, 6, 12 hours
                         86400000];

        var tickSize = tickSizes[0];
        for (var n = 1; n < tickSizes.length && dt >= tickSize * 4; ++n) {
          tickSize = tickSizes[n];
        }
        if (dt >= tickSize * 5) {
          var multipliers = [2, 2.5, 2];
          var m = 0;
          while (dt >= tickSize * 5) {
            tickSize *= multipliers[m % 3];
            ++m;
          }
        }

        var i = Math.floor(min / tickSize);
        while (tickSize * i < min) ++i;

        if (axis.options.min == null && tickSize * i != 0) {
          i--;
        }

        var ticks = [tickSize * i];

        for (var j = 1; tickSize * (i + j - 1) <= max + dt * 0.2 || j < 3; ++j) {
          ticks[j] = tickSize * (i + j);
        }
        return ticks;
      }
    }
  },
  durationSeconds: {
    BSChart: {
      format: "durationSeconds",
      description: "Time (s)"
    },
    yaxis: {
      tickFormatter: function (seconds) {
        return BS.Chart.Formats.duration.yaxis.tickFormatter(seconds * 1000);
      },
      ticks: function(axis) {
        return BS.Chart.Formats.duration.yaxis.ticks(axis);
      }
    }
  },
  size: {
    BSChart: {
      format: "size",
      description: "File size (byte)"
    },
    yaxis: {
      minTickSize: 1, // not less than 1 byte
      tickFormatter: function (size) {
        var sign = size >= 0 ? "" : "-";
        size = Math.abs(size);
        if (size < 0x400) {
          return sign + size.toFixed(0) + " B";
        } else if (size < 0x100000) {
          return sign + (size / 0x400).toFixed(2) + " KB";
        } else if (size < 0x40000000) {
          return sign + (size / 0x100000).toFixed(2) + " MB";
        } else if (size < 0x10000000000) {
          return sign + (size / 0x40000000).toFixed(2) + " GB";
        }
        return sign + (size / 0x10000000000).toFixed(2) + " TB";
      }
    }
  },
  percent: {
    BSChart: {
      format: "percent",
      maxFormatter: function (max) {
        return max;
      },
      minFormatter: function (min) {
        return min;
      },
      defaultMax: 100,
      description: "Percent (range 0-100)"
    },
    yaxis: {
      max: 100,
      minTickSize: 0.01,
      tickFormatter: function (num) {
        return parseFloat(num).toFixed(1) + "%";
      }
    }
  },
  percentBy1: {
    BSChart: {
      format: "percent",
      maxFormatter: function (max) {
        return max / 100;
      },
      minFormatter: function (min) {
        return min / 100;
      },
      defaultMax: 1,
      description: "Percent (range 0-1)"
    },
    yaxis: {
      max: 1,
      minTickSize: 0.1,
      tickFormatter: function (num) {
        return (parseFloat(num) * 100).toFixed(1) + "%";
      }
    }
  }
}, BS.CustomChartFormats || {});

BS.Chart.toolPopup = new (Class.create(BS.Popup, {
  baseOptions: {
    innerHTML: undefined,
    delay: 10,
    hideDelay: 50,
    forceReload: true,
    afterShowFunc: function (popup) {
      var element = jQuery(popup.element());
      element.find(".spinner").show();
      element.off("mouseenter").on("mouseenter", function () {
        popup.mouseOver = true;
      }).mouseleave(function () {
        popup.mouseOver = false;
      });
    },
    afterHideFunc: function () {
      jQuery(BS.Chart.toolPopup.element()).off("mouseenter");
    }
  },

  showTipAtPagePoint: function (container, tip, pageX, pageY) {
    this.hideText(true);

    var popupToggle = $(container);

    var pos = $j(popupToggle).offset();
    this.showText(container, tip, pageX - pos.left + 2, pageY - pos.top + 10);
  },

  showText: function (element, text, shiftX, shiftY) {
    this.options.url = undefined;
    this.options.innerHTML = text;

    this.showPopupNearElement(element, OO.extend(this.baseOptions, {
      htmlProvider: function(popup) {
        popup.element().innerHTML = "";
        return text;
      },
      shift: {x: shiftX, y: shiftY}
    }));
  },

  hideText: function () {
    if (this.mouseOver) {
      return;
    }
    BS.Hider.hideDiv(this._name);
  },

  mouseOver: false
}))("chartDataPopup");

BS.Chart.dateFormat = function (dateStr) {
  return jQuery.plot.formatDate(new Date(dateStr), "%d-%b-%y %H:%M:%S");
};

BS.Chart._def = function (v) {
  return typeof v !== 'undefined';
};

BS.Chart.parseYAxisOptions = function (id, chart) {
  var popup = jQuery("#" + id + "PopupW");
  if (popup != null && popup.length > 0) {
    var data = popup.data("chartConfigPopup");
    if (BS.Chart._def(data)) {
      var zeroCB = data.data['axis.y.includeZero'].value;
      var typeCB = data.data['axis.y.type'].value;
      var minT = data.data['axis.y.min'].value;
      var maxT = data.data['axis.y.max'].value;
      if (!zeroCB) {
        chart.extendOptions(['hideZero']);
      }
      if (typeCB == 'logarithmic') {
        chart.extendOptions(['log']);
      }
      if (minT != "" && minT != null) {
        chart.setMin(minT);
      }
      if (maxT != "" && maxT != null) {
        chart.setMax(maxT);
      }
    }
  }
};

BS.Chart.hidingDelay = 200;

BS.Chart.MarkedData = function() {
  var extractMarkings = function(plot, series, data/*, datapoints*/) {
    if (typeof plot.getOptions().grid.markings === 'function') {
      return;
    }
    if (!BS.Chart._def(plot.getOptions().grid.markings) || plot.getOptions().grid.markings == null) {
      plot.getOptions().grid.markings = [];
    }

    function contains(markings, point) {
      for (var i = 0; i < markings.length; ++i) {
        if (markings[i].xaxis.from <= point && markings[i].xaxis.to >= point) {
          return true;
        }
      }
      return false;
    }

    var points = [];
    var markings = [];
    for (var i = 0; i < data.length; ++i) {
      if (BS.Chart._def(data[i].marking)) {
        if (!plot.getOptions().grid.markingsOptions.removeDuplicates || !contains(plot.getOptions().grid.markings, data[i][0])) {
          markings.push(data[i].marking);
        }
      } else if (BS.Chart._def(data[i].marked) && data[i].marked != false) {
        if (!plot.getOptions().grid.markingsOptions.removeDuplicates || !contains(plot.getOptions().grid.markings, data[i][0])) {
          points.push(data[i]);
        }
      }
    }

    for (i = 0; i < points.length; ++i) {
      var m = points[i];
      var color = BS.Chart._def(m.marked) && typeof m.marked !== "boolean" && m.marked != 'true' && m.marked != 'false' ? m.marked : plot.getOptions().grid.markingsOptions.color;
      markings.push({
                      color: color,
                      lineWidth: plot.getOptions().grid.markingsOptions.lineWidth,
                      xaxis: {from: m[0], to: m[0]}
                    });
    }
    plot.getOptions().grid.markings = plot.getOptions().grid.markings.concat(markings);
  };

  var init = function(plot) {
    plot.hooks.processRawData.push(extractMarkings);
  };

  var options = {
    grid: {
      markingsOptions: {
        color: "rgba(255,0,0,0.4)",
        lineWidth: 1,
        removeDuplicates: true
      }
    }
  };

  jQuery.plot.plugins.push({init: init, options: options, name: "AddMarkings"});
};

BS.Chart.SmartYAxisLimitsFlotPlugin = function() {
  var findXMax = function(xAxes) {
    var max = xAxes[0].datamax;
    for (var i = 1; i < xAxes.length; ++i) {
      if (xAxes[i].datamax > max || max == null) {
        max = xAxes[i].datamax;
      }
    }
    return max + 1;
  };

  var adjustYAxisLimits = function(plot/*, offset*/) {
    function containsNotNullData(dataset) {
      for (var i = 0; i < dataset.length; ++i) {
        if (BS.Chart._def(dataset[i].data)) {
          for (var j = 0; j < dataset[i].data.length; ++j) {
            if (dataset[i].data[j][1] != null && dataset[i].data[j][1] != "null") {
              return true;
            }
          }
        } else {
          for (j = 0; j < dataset[i][j].length; ++j) {
            if (dataset[i][j][1] != null && dataset[i][j][1] != "null") {
              return true;
            }
          }
        }
      }
      return false;
    }

    function findLimits(axes) {
      var limits = {max: null, min: null};
      for (var i = 0; i < axes.length; ++i) {
        if (axes[i].datamin < limits.min || limits.min == null || limits.min == 'null') {
          limits.min = axes[i].datamin;
        }
        if (axes[i].datamax > limits.max || limits.max == null || limits.max == 'null') {
          limits.max = axes[i].datamax;
        }
      }
      return limits;
    }

    function setToAll(axes, limits) {
      for (var i = 0; i < axes.length; ++i) {
        if (BS.Chart._def(limits.max)) {
          axes[i].options.max = limits.max;
        }
        if (BS.Chart._def(limits.min)) {
          axes[i].options.min = limits.min;
        }
      }
    }

    var options = plot.getOptions();
    var yAxes = plot.getYAxes();
    var limits = findLimits(yAxes);
    var dataset = plot.getData();

    if (dataset != null && dataset.length != 0 && containsNotNullData(dataset)) {
      yAxes[0].options.show = true;
      options.selection.mode = 'x';
      if (options.BSChart.format == "percent" && limits.max > options.yaxis.max &&
          options.yaxis.max == options.BSChart.defaultMax && !options.BSChart.customMax) {
        setToAll(yAxes, {max: limits.max * 1.1});
      }

      if (limits.max < 0 && !options.BSChart.hideZero && !options.BSChart.customMax) {
        setToAll(yAxes, {max: 0});
      }
      if (limits.min < 0 && !options.BSChart.customMin) {
        if (limits.min == limits.max && options.BSChart.hideZero) {
          setToAll(yAxes, {min: limits.min - 1});
        } else {
          setToAll(yAxes, {min: limits.min - ((BS.Chart._def(options.yaxis.max) ? options.yaxis.max : limits.max) - limits.min) * 0.1});
        }
      }

      if (BS.Chart._def(options.xaxis.addSpace) && !plot.isSelected) {
        if (typeof options.xaxis.addSpace === "function") {
          setToAll(plot.getXAxes(), {max: options.xaxis.addSpace(plot.getXAxes())});
        } else {
          setToAll(plot.getXAxes(), {max: findXMax(plot.getXAxes())});
        }
      }
    } else {
      for (var i = 0; i < yAxes.length; ++i) {
        yAxes[0].options.show = false;
      }
      options.selection.mode = null;
    }
  };

  this.init = function(plot) {
    plot.hooks.processOffset.push(adjustYAxisLimits);
  };

  this.options = {
    grid: {
      emptyChartMessage: null,
      allNullDataMessage: null
    },
    xaxis: {
      addSpace: true
    }
  };
};

BS.Chart.FlotPlugin = function () {
  var cross = function (ctx, x, y, radius /*, shadow*/) {
    var size = radius / Math.PI * 2;
    ctx.moveTo(x - size, y - size);
    ctx.lineTo(x + size, y + size);
    ctx.moveTo(x - size, y + size);
    ctx.lineTo(x + size, y - size);
  };

  var filledCircle = function (ctx, x, y, radius, shadow) {
    if (!shadow) {
      ctx.arc(x, y, radius, 0, Math.PI * 2, true);
    }
  };

  var triangle = function (ctx, x, y, radius/*, shadow*/) {
    ctx.moveTo(x, y);
    ctx.lineTo(x - radius / 2 + 0.5, y + radius);
    ctx.lineTo(x + radius / 2 - 0.5, y + radius);
    ctx.lineTo(x, y);
    ctx.fill();
    ctx.stroke();
  };

  var findSymbolFunction = function (name, def) {
    if ("cross" == name) {
      return cross;
    } else if ("circle" == name) {
      return filledCircle;
    } else if ("triangle" == name) {
      return triangle;
    }
    return def;
  };

  var setSymbolFunction = function (plot, options) {
    var func = findSymbolFunction(options.series.points.symbol, null);
    if (func != null) {
      options.series.points.symbol = func;
    }
  };

  var drawSeriesHook = function (plot, canvascontext, series) {
    series.points.fillColor = series.color;
  };

  var patchMinMaxAccordingXFiltering = function(plot/*, offset*/) {
    var minX = Math.ceil(plot.getXAxes()[0].options.min);
    var maxX = Math.ceil(plot.getXAxes()[0].options.max);
    var max = null;
    var min = null;
    var plotData = plot.getData();
    for (var j = 0; j < plotData.length; ++j) {
      var data = plotData[j];
      for (var i = Math.max(0, minX); i < data.data.length && i < maxX; ++i) {
        var value = parseFloat(data.data[i][1]);
        if (isNaN(value)) continue;
        if (min == "null" || min == null || value < min) min = value;
        if (max == "null" || max == null || value > max) max = value;
      }
    }
    var yaxes = plot.getYAxes();
    if (min != null || max != null) {
      for (i = 0; i < yaxes.length; ++i) {
        yaxes[i].datamin = min;
        yaxes[i].datamax = max;
      }
    }
  };

  var setXMaxAboveXMinIfNeeded = function(plot/*, offset*/) {
    var ax = plot.getYAxes()[0].options;
    if (ax.min > ax.max) {
      ax.max = parseFloat(ax.min) * 2;
    }
  };

  var markTicks = function(plot, ctx) {
    var options = plot.getOptions().BSChart.xAxisTickMarks;
    if (plot.getXAxes().length < 2 || plot.getXAxes()[1].box == null) return;
    var xAxisYPos = plot.getXAxes()[1].box.top;

    if (BS.Chart._def(options.marks) && options.marks.length > 0) {
      for (var i = 0; i < options.marks.length; ++i) {
        var point = options.marks[i];
        if (typeof point === 'object') {
          var xCenterByObject = plot.getXAxes()[1].p2c(point.point) + plot.getPlotOffset().left;
          var func = findSymbolFunction(point.symbol, triangle);
          func(ctx, xCenterByObject, xAxisYPos + options.xAxisOffset, options.width);
        } else {
          var xCenter = plot.getXAxes()[1].p2c(point) + plot.getPlotOffset().left;
          ctx.fillStyle = "grey";
          ctx.strokeStyle = "grey";
          ctx.beginPath();
          triangle(ctx, xCenter, xAxisYPos + options.xAxisOffset, options.width);
          ctx.closePath();
        }
      }
    }
  };

  var extractXAxisMarkings = function(plot, series, data/*, datapoints*/) {
    if (typeof plot.getOptions().BSChart.xAxisTickMarks.marks === 'function') {
      return;
    }
    if (!BS.Chart._def(plot.getOptions().BSChart.xAxisTickMarks.marks) || plot.getOptions().BSChart.xAxisTickMarks.marks == null) {
      plot.getOptions().BSChart.xAxisTickMarks.marks = [];
    }

    var points = [];
    for (var i = 0; i < data.length; ++i) {
      if (data[i].current) {
        if (jQuery.inArray(plot.getOptions().BSChart.xAxisTickMarks.marks, data[i][0]) < 0) {
          points.push(data[i][0]);
        }
      }
    }

    plot.getOptions().BSChart.xAxisTickMarks.marks = plot.getOptions().BSChart.xAxisTickMarks.marks.concat(points);
  };

  this.color = null;

  this.init = function (plot) {
    plot.hooks.processOptions.push(setSymbolFunction);
    plot.hooks.processRawData.push(extractXAxisMarkings);
    plot.hooks.processOffset.push(patchMinMaxAccordingXFiltering, setXMaxAboveXMinIfNeeded);
    plot.hooks.drawSeries.push(drawSeriesHook);
    plot.hooks.drawOverlay.push(markTicks);
    //plot.hooks.drawBackground.push(increasePixelDensity);
  };

  this.options = {
    BSChart: {
      xAxisTickMarks: {
        width: 6,
        xAxisOffset: 5,
        marks: []
      }
    }
  };
};

BS.Chart.FlotAveragePlugin = function () {
  this.init = function (plot) {
    plot.hooks.processRawData.push(function (plot, currentSerie, currentData, datapoints) {
      if (currentSerie.average) {
        datapoints.format = [
            {x: true, number: false, required: true},
            {y: true, number: true, required: true},
            {number: true, required: true},
            {number: true, required: true},
            {number: false, required: true}
        ];
      }
    });
    plot.hooks.processDatapoints.push(function (plot, currentSerie, datapoints) {
      if (currentSerie.average) {
        var points = /*Array*/ datapoints.points;
        for (var i = 0; i < points.length; i += datapoints.pointsize) {
          points[i + 1] = points[i + 1] / points[i + 3];
        }
      }
    });
  };

  BS.Chart.FlotAveragePlugin.options = {
    defaultSerie: {
      min: -0.9,
      color: "#008021",
      tickDecimals: 0,
      tickColor: "grey",
      tickLength: 5,
      label: "Average",
      labelId: -1,
      average: true
    },
    allowed: true,
    enabled: false,
    disableOtherSeries: true
  };
};

BS.Chart.FlotHoverHighlighter = function () {
  var setUp = function (plot, options) {
    var chartHolder = plot.getPlaceholder();
    var previousPoint = null;
    var previousSeriePoint = null;
    var previousItem = null;
    var updating = false;
    var toolTip = BS.Chart.toolPopup;
    var currentItems = [];
    var isBeingSelected = false;
    chartHolder.bind("mousedown", function() {
      isBeingSelected = true;
    });
    $j(window).bind('mouseup', function() {
      isBeingSelected = false;
    });
    chartHolder.bind("plothover", function (event, pos, item) {
      if (plot == null || !plot.getOptions().grid.hoverable) {
        return;
      }

      currentItems.push(item);

      if (!item && plot.getOptions().series.bars.show && plot.p2c(pos).top > 0 && plot.p2c(pos).top < plot.height() && plot.p2c(pos).left < plot.width()) {
        var serie = plot.getData()[0];
        var ps = serie.datapoints.pointsize;
        var j = Math.round(pos.x);
        if (j >= 0 && j < serie.datapoints.points.length / ps) {
          item = {
            datapoint: serie.datapoints.points.slice(j * ps, (j + 1) * ps),
            dataIndex: j,
            series: serie,
            seriesIndex: 0,
            pageX: pos.pageX,
            pageY: pos.pageY
          };
        }
      }

      if (item) {
        document.body.style.cursor = "pointer";

        if (previousItem != item) {
          if (previousItem != null) {
            plot.unhighlight(previousItem.seriesIndex, previousItem.dataIndex);
            plot.unhighlightSerie(previousItem.series);
          }
          previousItem = item;
          plot.highlight(item.seriesIndex, item.dataIndex);
          options.BSChart.onHighlightSerie(item.series);
          plot.draw();
        }
      } else {
        if (previousItem != null) {
          plot.unhighlight(previousItem.seriesIndex, previousItem.dataIndex);
          plot.unhighlightSerie(previousItem.series);
          plot.draw();
          previousItem = null;
        }
        document.body.style.cursor = "default";
      }

      if (isBeingSelected) return;

      var time = 0;
      if (previousPoint) {
        time = BS.Chart.hidingDelay;
      }
      setTimeout(function () {
        if (currentItems.indexOf(item) < 0) return;
        currentItems = [];
        if (item) {
          if ((previousPoint != item.dataIndex || previousSeriePoint != item.seriesIndex) && !updating) {
            updating = false;
            previousPoint = item.dataIndex;
            previousSeriePoint = item.seriesIndex;

            plot.showToolTip(item);
          } else {
            // the same point - still showing the tip
          }
        } else {
          if (BS.Chart._def(plot.getOptions().BSChart.xAxisTickMarks.marks) && plot.getOptions().BSChart.xAxisTickMarks.marks.length > 0) {
            var got = false;
            var options = plot.getOptions().BSChart.xAxisTickMarks;
            var xAxisYPos = plot.getXAxes()[1].box.top;
            for (var i = 0; i < options.marks.length; ++i) {
              var point = options.marks[i];
              var xCenter;
              if (typeof point === 'object') {
                xCenter = plot.getXAxes()[1].p2c(point.point);
              } else {
                xCenter = plot.getXAxes()[1].p2c(point);
              }
              if (Math.abs(xCenter - plot.getXAxes()[1].p2c(pos.x)) < options.width / 2 && Math.abs(xAxisYPos - plot.getYAxes()[0].p2c(pos.y)) < options.width) {
                got = true;
                if (previousPoint == point) continue;
                previousPoint = point;
                BS.Chart.toolPopup.showTipAtPagePoint(plot.getPlaceholder(), "Current build", pos.pageX, pos.pageY);
              }
            }
          }

          if (!got) {
            toolTip.hideText();
            previousPoint = null;
          }
          previousSeriePoint = null;
        }
      }, time);
    });
  };

  this.init = function(plot) {
    plot.hooks.processOptions.push(setUp);
  };

  this.options = {
    grid: {
      hoverable: true,
      shouldShowTooltip: true
    }
  };
};

BS.Chart.ConfigureChartPopup = function (id, yAxisType, yIncludeZero, yMin, yMax, typeEnabled, zeroEnabled, maxEnabled, minEnabled, nonDefault) {
  this.myId = id;

  if (yMax == null || yMax == 'null') yMax = "";
  if (yMin == null || yMin == 'null') yMin = "";

  this.data = {
    "axis.y.type": {value: yAxisType, enabled: typeEnabled, checked: function() {return this.value == 'logarithmic';}},
    "axis.y.includeZero": {value: yIncludeZero, enabled: zeroEnabled, checked: function() {return this.value;}},
    "axis.y.max": {value: yMax, enabled: maxEnabled},
    "axis.y.min": {value: yMin, enabled: minEnabled}
  };

  this.nonDefault = nonDefault;

  this.attachTo = function (popup) {
    popup.data("chartConfigPopup", this);
    var othis = this;
    popup.find(".cancel").click(function() {othis.hide(); return false;});
    popup.find(".submitButton").click(function() {othis.submit(); return false;});
    popup.find("input[type='text']").keydown(function(event) {if (event.keyCode == 13) othis.submit('${id}');});
  };

  this.hideAllPopups = function () {
    $j("div[id$='PopupW']").hide();
  };

  this.show = function (element) {
    function setIfAvailable(popupDiv, selector, data) {
      var input = popupDiv.find(selector);
      if (BS.Chart._def(input)) {
        input.val(BS.Chart._def(data.tempvalue) ? data.tempvalue : data.value);
        if (BS.Chart._def(data.checked)) {
          input.attr('checked', data.checked());
        }
        if (!data.enabled) {
          input.attr('disabled', 'disabled');
        } else {
          input.removeAttr('disabled');
        }
      }
    }

    this.hideAllPopups();
    var popupDiv = $j("#" + this.myId + "PopupW");
    popupDiv.show();
    BS.Util.placeNearElement(this.myId + "PopupW", element, {x: element.offsetWidth + 10, y: 0});

    for (var prop in this.data) {
      setIfAvailable(popupDiv, "input[id='" + prop + "']", this.data[prop]);
    }

    BS.Hider.showDivWithTimeout(this.myId + 'PopupW', {hideOnMouseOut: false, hideOnMouseClickOutside: true});
  };

  this.apply = function () {
    this.hide();
    var popup = $j("#" + this.myId + "PopupW").find(".graphSettingsPopup");

    for (var prop in this.data) {
      var input = popup.find("input[id='" + prop + "']");
      if (typeof input !== 'undefined') {
        this.data[prop].value = input.val();
      }
    }
  };

  this.hide = function () {
    BS.Hider.hideDiv(this.myId + 'PopupW');
  };

  this.submit = function () {
    this.apply();
    BS.Chart.submitForm(this.myId);
  };

  this.reset = function () {
    var popup = $j("#" + this.myId + "PopupW").find(".graphSettingsPopup");

    for (var prop in this.data) {
      this.data[prop].value = null;
      var input = popup.find("input[id='" + prop + "']");
      if (typeof input !== 'undefined') {
        input.val(null);
      }
    }
  };

  this.plotSelected = function(yMin, yMax) {
    this.data["axis.y.min"].tempvalue = yMin;
    this.data["axis.y.max"].tempvalue = yMax;
  };

  this.plotUnselected = function() {
    delete this.data["axis.y.min"].tempvalue;
    delete this.data["axis.y.max"].tempvalue;
  };
};

BS.Chart.reset = function (chartId) {
  var $form = jQuery("#" + chartId + "Form");
  if ($form.find("input[name='_resetDefaults']").length > 0) return;
  var lastInForm = $form.find("input[type=hidden]:last");
  lastInForm.after("<input type='hidden' name='_resetDefaults' value='true'/>");
  BS.Chart.submitForm(chartId);
};

BS.Chart.resetYAxis = function (chartId) {
  var $form = jQuery("#" + chartId + "Form");
  if ($form.find("input[name='_resetYAxisDefaults']").length > 0) return;
  var popup = $j('#' + chartId + 'PopupW').data('chartConfigPopup');
  if (popup) {
    popup.reset();
  }
  var lastInForm = $form.find("input[type=hidden]:last");
  lastInForm.after("<input type='hidden' name='_resetYAxisDefaults' value='true'/>");
  BS.Chart.submitForm(chartId);
};

BS.Chart.applyFilter = function (graphKey, rawGraphKey, url) {
  var popup = jQuery("#" + graphKey + "PopupW").data("chartConfigPopup");

  if (popup) {
    for (var prop in popup.data) {
      BS.Chart.setInputValueOrCreate(graphKey, prop, popup.data[prop].value);
    }
  }

  BS.Chart.collectAgentFilter(graphKey);
  Form.disable(graphKey + 'Form');
  $j("#" + graphKey + "Form").find(".agentsList .checkbox_unchecked_value input[type='checkbox']").each(function(idx, item) {
    var $item = $j(item);
    var name = $item.attr("name");
    var value = $item.attr("value");
    $item.after($j('<input/>', {
        type: 'hidden',
        name: name,
        value: value
      }));
    $item.removeAttr("name");
  });

  var moreParameters = BS.Util.serializeForm($(graphKey + 'Form'));
  var containerId = graphKey + 'Container';

  var $currentDiv = $j("#" + containerId);

  var $chartHolder = $currentDiv.find("div[id='chartHolder" + graphKey + "']");

  var spinner = BS.Chart.showSpinner($chartHolder);

  var initScrollPos = $j("#" + graphKey + "Container_i .agentsFilterInner").scrollTop();
  var tableHeight = $j("#" + graphKey + "Container_i .agentsFilterInner .agentsFilterTable").height();

  $(graphKey + "Container_i").refresh(spinner[0], moreParameters, function() {
    if ($j("#" + graphKey + "Container_i .agentsFilterInner .agentsFilterTable").height() == tableHeight) {
      $j("#" + graphKey + "Container_i .agentsFilterInner").scrollTop(initScrollPos);
    }
  });
};

BS.Chart.collectAgentFilter = function (graphKey) {
  var form = jQuery("#" + graphKey + "Form");
  var checked = form.find('input[name="@filter.s"]:checked');
  var unchecked = form.find('input[name="@filter.s"]:not(:checked)');
  if (unchecked.length == 0) {
    jQuery(form).append("<input type='checkbox' style='display: none' name='@filter.s' checked value=''/>")
  } else {
    unchecked.each(function (i, e) {
      jQuery(e).after(jQuery('<input/>', {
          type: 'checkbox',
          style: 'display: none',
          name: '@filter.s',
          checked: 'checked',
          value: e.value
        }));
    });
  }
  checked.removeAttr("name");
};

BS.Chart.setInputValueOrCreate = function (chartId, property, newValue) {
  var form = jQuery("#" + chartId + "Form");
  var input = jQuery("input[name='" + property + "']", form);
  if (input.length == 0) {
    jQuery("input[type=hidden]:last", form).after(jQuery('<input/>', {
        type: 'hidden',
        name: property,
        value: newValue
      }));
  } else {
    input.val(newValue);
  }
};

BS.Chart.submitForm = function (chartId) {
  var form = $j("#" + chartId + "Form");
  form.trigger('onsubmit');
};

BS.Chart.bindFilterListeners = function($chartHolder, chartId, projectId, buildTypeId) {
  $chartHolder.on("dataLoaded", function() {
    $j("#agentsFilter" + chartId +" input[name='@filter.s']").parent().mouseenter(function (/*event*/) {
      $chartHolder.data("chart").onHighlightSerie(this.id);
    }).mouseleave(function (/*event*/) {
      $chartHolder.data("chart").onUnhighlightSerie(this.id);
    });
  });

  var $personalFilter = $j("input[id='@filter.showPersonal" + chartId + "']");
  $personalFilter.on("click", {chartId: chartId}, function(e) {
    var showPersonal = !(($personalFilter.attr("data-value") + "").toLowerCase() === "true");
    $j("#" + chartId + "Container .chartHolder").data("chart").togglePersonal(!showPersonal);

    $personalFilter.attr("data-value", showPersonal);

    var $container = $personalFilter.parents(".GraphContainer");

    $j.ajax({type: "POST",
              url: window['base_uri'] + "/exportchart.html",
              data: {
                saveState: true,
                key: "@filter.personal",
                value: !showPersonal,
                graphKey: e.data.chartId,
                projectId: $container.data("project-id"),
                buildTypeId: $container.data("buildtype-id")
              }
            });

    $chartHolder.trigger("filtersChanged");
  });
  $chartHolder.on("dataLoaded", function(e, params) {
    var $personalFilterHolder = $j("#" + chartId + "Container .personalBuildFilter");
    if (params.data && params.data.builds) {
      var builds = params.data.builds;
      for (var buildIdx in builds) {
        if (builds.hasOwnProperty(buildIdx)) {
          if (builds[buildIdx].isPersonal) {
            $personalFilterHolder.show();
            return;
          }
        }
      }
    }

    // hiding filter if no data or if no personal in data
    $personalFilterHolder.hide();
  });
  var $averageFilters = $j("input[id='@filter.average" + chartId + "']");
  $averageFilters.on("click", function(event) {
    var $chart = $chartHolder.data("chart");
    $chart.getOptions().BSChart.average.enabled = event.currentTarget.checked;
    event.currentTarget.value = event.currentTarget.checked;
    event.currentTarget.setAttribute('data-value', event.currentTarget.value);
    $chart.rerenderBuildChart();

    $j.ajax({type: "POST",
              url: window['base_uri'] + "/exportchart.html",
              data: {
                saveState: true,
                key: "@filter.average",
                value: $chart.getOptions().BSChart.average.enabled,
                graphKey: chartId,
                projectId: projectId,
                buildTypeId: buildTypeId
              }
            });

    $chartHolder.trigger("filtersChanged");
  });
  $j("#agentsFilter" + chartId).on("click", "input[name='@filter.s']", function (event) {
    var chart = $chartHolder.data("chart");
    chart.toggleSerie(this.value);

    event.currentTarget.setAttribute('data-value', event.currentTarget.checked);

    var form = jQuery("#" + chartId + "Form");
    var res = [];
    form.find('input[name="@filter.s"]:not(:checked)').each(function(idx, e) {res.push(e.value);});

    $j.ajax({
              type: "POST",
              url: window['base_uri'] + "/exportchart.html",
              traditional: true,
              data: {
                saveState: true,
                key: "@filter.s",
                value: res,
                graphKey: chartId,
                projectId: projectId,
                buildTypeId: buildTypeId
              }
            });

    $chartHolder.trigger("filtersChanged");
  });
  $j("#agentsFilter" + chartId).on("click", "a", function() {
    var form = jQuery("#" + chartId + "Form");
    var res = [];
    form.find('input[name="@filter.s"]:not(:checked)').each(function(idx, e) {res.push(e.value);});

    $j.ajax({
              type: "POST",
              url: window['base_uri'] + "/exportchart.html",
              traditional: true,
              data: {
                saveState: true,
                key: "@filter.s",
                value: res,
                graphKey: chartId,
                projectId: projectId,
                buildTypeId: buildTypeId
              }
            });

    $chartHolder.trigger("filtersChanged");
  });

  var onPlotSelectedHooks = [];
  var onPlotUnselectedHooks = [];
  var rangeFilter = $j("#rangeFilter" + chartId);

  function round(number) {
    return (parseInt(number * 10)) / 10;
  }

  if (rangeFilter != null && rangeFilter.length > 0) {
    var init = -1;
    onPlotSelectedHooks.push(function (event, range) {
      var options = rangeFilter.find("option");
      var selectedI = -1;
      for (var i = 0; i < options.length - 1; ++i) {
        if (options[i].selected) {
          selectedI = i;
          break;
        }
      }
      if (selectedI == -1) {
        selectedI = options.length - 1;
      }
      init = selectedI;
      options[selectedI].selected = false;
      options[options.length - 1].selected = true;
      options[options.length - 1].value = options[selectedI].value;
      options[options.length - 1].text = 'Custom - ' + round(range.xaxis.from + 1) + '-' + round(range.xaxis.to + 1);
      options[options.length - 1].show();
    });
    onPlotUnselectedHooks.push(function (/*event, range*/) {
      if (init == -1) return;
      var options = rangeFilter.find("option");
      var value = options[options.length - 1].value;
      var selectedI = -1;
      for (var i = 0; i < options.length - 1; ++i) {
        if (options[i].value == value) {
          selectedI = i;
          break;
        }
      }
      if (selectedI != -1) {
        options[options.length - 1].selected = false;
        options[selectedI].selected = true;
        options[selectedI].value = options[options.length - 1].value;
        options[options.length - 1].value = null;
        options[options.length - 1].text = '';
        options[options.length - 1].hide();
      } else {
        options[options.length - 1].selected = false;
        options[init].selected = true;
      }
    });
  }

  var popup = jQuery("#" + chartId + "PopupW");
  if (popup != null && popup.length > 0) {
    var data = popup.data("chartConfigPopup");
    if (BS.Chart._def(data)) {
      onPlotSelectedHooks.push(function (event, range) {
        if (event.isYSelection) {
          data.plotSelected(round(range.yaxis.from), round(range.yaxis.to));
        }
      });
      onPlotUnselectedHooks.push(function (/*event, range*/) {
        data.plotUnselected();
      });
    }
  }

  var resetLink = $j("#" + chartId + "resetLink");
  if (resetLink.css("display") == "none") {
    onPlotSelectedHooks.push(function(/*event, range*/) {
      resetLink.show();
    });
    onPlotUnselectedHooks.push(function(/*event, range*/) {
      resetLink.hide();
    });
  }

  var yAxisResetLink = $j("#" + chartId + "Container .yAxisResetLink");
  if (yAxisResetLink.css("display") == "none") {
    onPlotSelectedHooks.push(function() {yAxisResetLink.show()});
    onPlotUnselectedHooks.push(function() {yAxisResetLink.hide()});
  }

  if (onPlotSelectedHooks.length > 0) {
    $chartHolder.bind("plotselected", function (event, range) {
      if ($chartHolder.data("plot").getOptions().selection.mode == "both") {
        event.isYSelection = true;
      }
      for (var i = 0; i < onPlotSelectedHooks.length; ++i) {
        onPlotSelectedHooks[i](event, range);
      }
    });
  }
  if (onPlotUnselectedHooks.length > 0) {
    $chartHolder.bind("plotunselected", function (event, range) {
      for (var i = 0; i < onPlotUnselectedHooks.length; ++i) {
        onPlotUnselectedHooks[i](event, range);
      }
    });
  }
};

BS.Chart.unbindAll = function(chartHolder) {
  chartHolder.unbind("plotselected");
  chartHolder.unbind("plotunselected");
  chartHolder.unbind("plotclick");
  chartHolder.unbind("plothover");
};

BS.Chart.hideFilters = function(id) {
  $j('.agentsList#' + id + ' .posRel').hide();
  $j('.agentsList#' + id + ' .showLink').show();
  $j('.agentsList#' + id + ' .hideLink').hide();
};

BS.Chart.showFilters = function(id) {
  $j('.agentsList#' + id + ' .posRel').show();
  $j('.agentsList#' + id + ' .hideLink').show();
  $j('.agentsList#' + id + ' .showLink').hide();
};

BS.Chart.CtrlKeyEventListeners = [];

$j(function() {
  function isCtrlEvent(evt) {
    return evt.ctrlKey || evt.which == 17;
  }

  if (BS.Chart._def(jQuery.plot)) {
    $j(window).keydown(function(evt) {
      if (isCtrlEvent(evt)) {
        for (var i = 0; i < BS.Chart.CtrlKeyEventListeners.length; ++i) {
          var plot = $j(BS.Chart.CtrlKeyEventListeners[i]).data('plot');
          var options = plot && plot.getOptions();
          if (options && !options.BSChart.ctrlIsPressed) {
            options.selection.mode_temp = plot.getOptions().selection.mode;
            options.selection.mode = "both";
            options.grid.shouldShowTooltip = false;
            options.BSChart.ctrlIsPressed = true;
          }
        }
      }
    }).keyup(function(evt) {
      if (isCtrlEvent(evt)) {
        for (var i = 0; i < BS.Chart.CtrlKeyEventListeners.length; ++i) {
          var plot = $j(BS.Chart.CtrlKeyEventListeners[i]).data('plot');
          var options = plot && plot.getOptions();
          if (!options) {
            continue;
          }
          if (options.BSChart.ctrlIsPressed) {
            options.selection.mode = plot.getOptions().selection.mode_temp;
            options.grid.shouldShowTooltip = true;
          }
          options.BSChart.ctrlIsPressed = false;
        }
      }
    });

    jQuery.plot.plugins.push(new BS.Chart.FlotAveragePlugin(), new BS.Chart.FlotPlugin(), new BS.Chart.FlotHoverHighlighter(), new BS.Chart.SmartYAxisLimitsFlotPlugin());
    new BS.Chart.MarkedData();
  } else {
    BS.Log.warn("Cannot initialize Plot plugins: Plot not found");
  }
});

BS.Chart.bindAgentFilterListener = function(gid) {
  var $chartHolder = $j("div[id='chartHolder"  + gid + "']");
  $chartHolder.on("dataLoaded", function(event, params) {
    var $agentFilter = $j("#" + gid + "Container .agentsFilterTable");
    var json = params.data;

    if ($agentFilter) {
      $agentFilter.hide();
      $agentFilter.find("tr:visible").remove();
      var $proto = $agentFilter.find("tr#proto");
      var i = 0;
      var temp = [];
      var anyFound = false;
      for (var seriesId in json.series) {
        anyFound = true;
        var $newtr = $proto.clone();
        $newtr.removeAttr("id");
        var id = gid + "agentName" + i++;
        var $label = $newtr.find("label");
        $label.append(json.series[seriesId].name);
        $label.attr("id", seriesId);
        $label.attr("for", id);
        var $cb = $newtr.find(".agentCheckbox");
        $cb.attr("id", id);
        $cb.attr("value", seriesId);
        $cb.attr("name", "@filter.s");
        $cb.attr("data-value", json.series[seriesId].enabled);
        if (json.series[seriesId].enabled) {
          $cb.prop("checked", true);
        }
        var $img = $newtr.find(".color-bullet");
        $img.css({"background-color": json.colors[seriesId]});
        temp.push($newtr);
        $newtr.show();
      }
      if (anyFound) {
        $agentFilter.append(temp);
        $agentFilter.show();
        $j('#agentsFilter' + gid).show();
      } else {
        $j('#agentsFilter' + gid).hide();
      }
    }
  });
};

BS.Chart.showSpinner = function($chartHolder) {
  var spinner = BS.Chart.chartMessage($chartHolder, ' Loading data', 'spinner');
  spinner.prepend(BS.loadingIcon);
  return spinner;
};

BS.Chart.chartMessage = function($chartHolder, message, additionalClass) {
  var $message = $j('<div/>', {style: 'display: none', class: 'no_data_label ' + additionalClass});
  $message.text(message);
  $chartHolder.append($message);
  return $message;
};

BS.Chart.showChart = function (id, json, styles, showBranches, showBuildType, options, projectId, buildTypeId) {
  var $chartHolder = $j("div[id='chartHolder" + id + "']");
  var $resetLink = $j("#" + id + " .resetLink");

  $chartHolder.on("errorOccurred", function(event, error) {
    $chartHolder.find(".spinner").hide();
    var $message;
    switch (error.type) {
      case "exception":
        $message = BS.Chart.chartMessage($chartHolder, "Exception occurred " + error.exception, "error");
        break;
      case "project not found":
        $message = BS.Chart.chartMessage($chartHolder, "Project not found for " + error.initialData.projectId + "; " + error.initialData.buildTypeId, "error");
        break;
      default:
        $message = BS.Chart.chartMessage($chartHolder, "Error \"" + error.type + "\": " + error.message, "error");
        break;
    }
    $message.show();
  });
  BS.Chart.bindFilterListeners($chartHolder, id, projectId, buildTypeId);
  $chartHolder.on("dataLoaded", function(e, additional) {
    var json = additional.data;

    var found = false;
    for (var serieName in json.data) {
      for (var pointIdx in json.data[serieName]) {
        if (json.data[serieName][pointIdx][1] != null) {
          $j("#" + id + "ChartLink").show();
          found = true;
          break;
        }
      }
      if (found) {
        break;
      }
    }

    $chartHolder.trigger("filtersChanged");
  });
  $chartHolder.on("filtersChanged", function() {
    var $form = $j("#" + id + "Form");

    // noinspection SpellCheckingInspection
    var n = Number($resetLink.data("server-nondefaults"));
    $form.find(".chartFilter").each(function(idx, elt) {
      var def = elt.getAttribute('data-default');
      var val = elt.getAttribute('data-value');
      if (def != val) {
        ++n;
      }
    });
    // noinspection SpellCheckingInspection
    $resetLink.data("nondefaults", n);

    if (n != 0) $resetLink.show();
    else $resetLink.hide();

    var d = $j("div[id='" + id + "Container']").data("filters");

    if (!d) {
      throw new Error('could not get filters for the #' + id + 'Container');
    }

    var arr = [];

    $j("#agentsFilter" + id).find("input[type='checkbox']:not(:checked)").filter(function(idx, e) {return e.name != 'agentFilterProto';}).each(function(idx, e) {arr.push(e.value);});
    d['@filter.s'] = arr;
    d['@filter.average'] = ($j("input[id='@filter.average" + id + "']").attr("data-value") + "").toLowerCase() === 'true';
    d['@filter.personal'] = !(($j("input[id='@filter.showPersonal" + id + "']").attr("data-value") + "").toLowerCase() === 'true');

    $j("a[id='" + id + "ChartLink']").attr("href", window['base_uri'] + "/exportchart.html?type=text&" + $j.param($j.extend(true, d, {flotChart: false}), true));
  });

  BS.Chart.showSpinner($chartHolder).show();
  if (json) {
    BS.Chart.createBuildChart($chartHolder, json, id, styles, {series: json.colors}, showBranches, showBuildType, options);
    $chartHolder.trigger("dataLoaded", {data: json});
  }

  var rtime = new Date(1, 1, 2000, 12,00,00);
  var timeout = false;
  var delta = 200;
  $j(window).resize(function() {
    rtime = new Date();
    if (timeout === false) {
      timeout = true;
      setTimeout(resizeEnd, delta);
    }
  });

  function resizeEnd() {
    if (new Date() - rtime < delta) {
      setTimeout(resizeEnd, delta);
    } else {
      if ($chartHolder.data("chart")) {
        timeout = false;
        BS.Chart.unbindAll($chartHolder);
        $chartHolder.data("chart").renderChart();
      }
    }
  }
};

BS.Chart.doBulkRequestForData = function () {
  if (BS.Chart.loadedCharts) {
    var temp = BS.Chart.loadedCharts;
    BS.Chart.loadedCharts = [];
    if (temp && temp.length > 0) {
      $j.ajax({type: "POST",
               url: window['base_uri'] + "/exportchart.html",
               data: {data: JSON.stringify(temp), type: "json", bulk: true, "flotChart": true},
               dataType: "json"
             }).done(function (allChartsData) {
        for (var idx = 0; idx < allChartsData.length; ++idx) {
          var $chartHolder = $j("div[id='chartHolder" + allChartsData[idx].id + "']");
          if ($chartHolder.length > 0) {
            var json = allChartsData[idx].data;
            if (json) {
              BS.Chart.createBuildChart($chartHolder, json, allChartsData[idx].id, BS.Chart.chartsStyles[allChartsData[idx].id], {series: json.colors},
                                        allChartsData[idx].showBranches, allChartsData[idx].showBuildType, {
                                          BSChart: {
                                            average: {
                                              enabled: ($j("input[id='@filter.average" + allChartsData[idx].id + "']").attr("value") + "").toLowerCase() === 'true',
                                              groupBy: $j("div[id='rangeFilter" + allChartsData[idx].id + "']").find("option:selected").val().toLowerCase()
                                            },
                                            hidePersonal: !$j("input[id='@filter.showPersonal" + allChartsData[idx].id + "']").data("value")
                                          }
                                        });
              $chartHolder.trigger("dataLoaded", {data: json});
            } else {
              $chartHolder.trigger("errorOccurred", allChartsData[idx].error);
            }
          }
        }
      });
    }
  }
};

BS.Chart.loadedCharts = BS.Chart.loadedCharts || [];
BS.Chart.chartsStyles = BS.Chart.chartsStyles || {};