BS.JvmStatusForm = OO.extend(BS.AbstractWebForm, {
  formElement: function() {
    return $('jvmStatusForm');
  },

  savingIndicator: function() {
    return $('progressIndicator');
  },

  threadDumpsErrorsAwareListener: function() {
    return OO.extend(BS.ErrorsAwareListener, {
      threadDumpFailed: function(elem) {
        $('errorsHolder').innerHTML = elem.firstChild.nodeValue;
      },

      onCompleteSave: function(form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
        if (!err) {
          BS.reload(true);
        }
      }
    });
  },

  takeMemoryDump: function() {
    if (!confirm("This operation can take up to several minutes.\nDuring this period TeamCity will not respond to any requests.\nAre you sure you want to continue?")) return;

    this.formElement().actionName.value = 'memoryDump';
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      memoryDumpFailed: function(elem) {
        $('errorsHolder').innerHTML = elem.firstChild.nodeValue;
      },

      onCompleteSave: function(form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
        if (!err) {
          BS.reload(true);
        }
      }
    }));
  },

  takeThreadDump: function() {
    this.formElement().actionName.value = 'threadDump';
    BS.FormSaver.save(this, this.formElement().action, this.threadDumpsErrorsAwareListener());
  },

  loadPreset: function() {
    this.formElement().actionName.value = 'loadPreset';
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      loadPresetFailed: function(elem) {
        $('errorsHolder').innerHTML = elem.firstChild.nodeValue;
      },

      onCompleteSave: function(form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
        if (!err) {
          BS.reload(true);
        }
      }
    }));
  }
});

BS.ThreadDumpAdvanced = OO.extend(BS.JvmStatusForm, {
  takeThreadDumpPopup: new BS.Popup('takeThreadDumpPopup', {
    delay: 0,
    hideDelay: -1,
    backgroundColor: 'white'
  }),
  formElement: function() {
    return $('threadDumpAdvancedForm');
  },
  close: function() {
    this.takeThreadDumpPopup.hidePopup();
  },
  showNear: function(element) {
    this.takeThreadDumpPopup.showPopupNearElement(element, {
      afterShowFunc: function() {
      }
    });
  },

  threadDumpsErrorsAwareListener: function() {
    return OO.extend(BS.ErrorsAwareListener, {
      threadDumpFailed: function(elem) {
        $j('#threadDumpAdvancedForm #errorsHolder').text(elem.firstChild.nodeValue);
      },

      onCompleteSave: function(form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
        if (!err) {
          BS.reload(true);
        }
      }
    });
  }
});

BS.AdminDiagnostics = {
  installNodeDiagnostics: function () {
    var $nodes = $j(".remoteNodeDetailBlock");
    for (var i = 0; i < $nodes.length; ++i) {
      var node = $nodes[i];
      var serverId = node.attributes["data-server-id"].value;
      $j.ajax({
                url: window['base_uri'] + '/admin/nodeDiagnostic.html',
                data: {
                  serverId: serverId,
                  oneNodeMode: false
                },
                dataType: "html"
              }).done(function (data) {
        $j(node).html(data);
      });
    }
  },

  installChartsAutoUpdate: function() {
    BS.AdminDiagnostics.updateFunction = function () {
      var promises = [];
      $j(".chart").each(function (idx, elt) {
        var $element = $j(elt);
        if ($element.find(".chartHolder").data("plot") && $element.find(".chartHolder").data("plot").isSelected || ($element.find(".chartHolder").data("paused") + "").toLowerCase() === "true") return;

        var type = $element.data("type");
        var url = $element.data("update-url") || "/admin/diagnostic.html?type=" + type + "&actionName=chartData";
        promises.push($j.ajax({type: "GET",
                  url: window['base_uri'] + url,
                  dataType: "json"
                }).done(function (data) {
          var chartElt = $element.find(".chartHolder");
          if (!data) {
            chartElt.data("chart").renderChart({});
            chartElt.data("chart").setMessage("No data available");
          } else {
            if (data.error) {
              chartElt.data("chart").renderChart({});
              chartElt.data("chart").setMessage(data.error);
            } else {
              chartElt.trigger("updateChart", {data: data});
            }
          }
        }).fail(function(data) {
          var chartElt = $element.find(".chartHolder");
          chartElt.data("chart").renderChart({});
          chartElt.data("chart").setMessage("No data available");
        }));
      });

      $j(".chartsContainer").css({height: "auto"});

      return $j.when.apply($j, promises);
    };

    BS.periodicalExecutor(function () {
      BS.Chart.CtrlKeyEventListeners = [];
      var h = $j(".chartsContainer").height();
      $j(".chartsContainer").css({height: h});

      return BS.AdminDiagnostics.updateFunction();
    }, 10000).start();
  },

  renderChart: function (id, /*toolTipFunction, legendLabel, data, hooks, preprocessDataFunction, */parametersData) {
    parametersData = parametersData || {
          toolTipFunction: function(item, series) {},
          legendLabel: function(name, serie) {},
          data: null,
          flotHooks: {},
          preprocessDataFunction: function(data) {},
          preprocessSerieFunction: function(key, serie) {}
        };
    var data = parametersData.data;
    var $chartHolder = $j("#" + id);
    var chart = new BS.Chart($chartHolder, id,
        [
          "line",
          "percentBy1",
          "point",
          {
            BSChart: {
              toolTip: parametersData.toolTipFunction,
              customMax: true
            },
            series: {points: {radius: 0, selectedRadius: 2.5}},
            legend: {
              show: true, container: $j("#" + id + "Legend"), labelFormatter: function (name, serie) {
                return "<div class='serieLabel " + name + "' data-id='" + id + "' data-name='" + name +"' title='" + (serie.description || "") + "'>" + parametersData.legendLabel(name, serie) + "</div>";
              }
            },
            xaxes: [
              {show: false, min: 0},
              {
                min: 0,
                tickColor: "#dfe5eb",
                tickLength: null,
                mode: "time",
                timezone: "browser"
              }
            ],
            yaxis: {
              max: 1.0,
              labelWidth: 40,
              reserveSpace: true
            },
            hooks: parametersData.flotHooks
          }]);
    var initOnHighlightSerie = chart.onHighlightSerie;
    var initOnUnhighlightSerie = chart.onUnhighlightSerie;
    chart.onHighlightSerie = function(serieName) {
      $chartHolder.data("paused", true);
      initOnHighlightSerie(serieName);
    };
    chart.onUnhighlightSerie = function(serieName) {
      $chartHolder.data("paused", false);
      initOnUnhighlightSerie(serieName);
    };
    $chartHolder.data("chart", chart);
    $chartHolder.on("updateChart", function (e, additional) {
      var data = additional.data;
      parametersData.preprocessDataFunction(data);

      var $chartHolder = $j("#" + id);
      if (!(data && data[0])) {
        var t = [], i = 0;
        for (var key in data) {
          if (data.hasOwnProperty(key)) {
            t[i] = {};
            t[i].data = data[key];
            t[i].xaxis = 2;
            t[i].label = key;
            parametersData.preprocessSerieFunction(key, t[i]);
            ++i;
          }
        }
        t.push({data: [], xaxis: 1});
        data = t;
      }

      $chartHolder.data("chart").getOptions().xaxes[0].min = data[0].data[0][0];
      $chartHolder.data("chart").getOptions().xaxes[1].min = data[0].data[0][0];
      BS.Chart.unbindAll($chartHolder);
      $chartHolder.data("chart").renderChart(data);
    });
    if (data) $chartHolder.trigger("updateChart", {data: data});
    $chartHolder.parent().on("mouseout", ".chartLegend tr", function(e) {
      var $row = $j(e.currentTarget);
      var $label = $row.find(".serieLabel");
      var id = $label.data("id");
      var name = $label.data("name");
      $j("#" + id).data("chart").onUnhighlightSerie(name);
    });
    $chartHolder.parent().on("mouseover", ".chartLegend tr", function(e) {
      var $row = $j(e.currentTarget);
      var $label = $row.find(".serieLabel");
      var id = $label.data("id");
      var name = $label.data("name");
      $j("#" + id).data("chart").onHighlightSerie(name);
    });
  },

  renderMemoryChart: function (data, id, additionalData) {
    id = id || "";
    this.renderChart("memoryChart" + id, {
      toolTipFunction: function (item) {
        return item.series.labelId + ": " + (item.datapoint[1] * 100).toFixed(1) + "% (" + BS.Chart.Formats.size.yaxis.tickFormatter(item.datapoint[1] * item.series.totalSizeN) + ")";
      },
      legendLabel: function (name, serie) {
        if (name == 'TC_TOTAL_MEMORY_USAGE_KEY') name = "Total heap";
        return name + ": <strong>" + BS.Chart.Formats.size.yaxis.tickFormatter(serie.currentSize) + "</strong> (<strong>" + (serie.currentSize / serie.totalSizeN * 100).toFixed(1) + "%</strong> of maximum available <strong>" + BS.Chart.Formats.size.yaxis.tickFormatter(serie.totalSizeN) + "</strong>)";
      },
      data: data,
      flotHooks: {
        processDatapoints: function(plot, series, datapoints) {
          var points = datapoints.points, ps = datapoints.pointsize;

          if (points.length > 0) series['currentSize'] = points[points.length - 1];
          else series['currentSize'] = 0;
          if (additionalData && additionalData[series.label]) {
            series['totalSizeN'] = additionalData[series.label].max;
            series['totalSize'] = additionalData[series.label].max;
          }

          if (series.totalSizeN) {
            for (var i = 0; i < points.length; i += ps) {
              points[i + 1] /= series.totalSizeN;
            }
          }
        }
      },
      preprocessDataFunction: function(data) {},
      preprocessSerieFunction: function(key, serie) {
        serie.label = additionalData[key].title;
        serie.labelId = additionalData[key].title;
        serie.color = additionalData[key].color;
        serie.totalSize = additionalData[key].max;
        serie.totalSizeN = additionalData[key].max;
      }
    });
  },

  renderCPUChart: function (data, id) {
    id = id || "";
    this.renderChart("cpuChart" + id, {
      toolTipFunction: function (item) {
        return (item.datapoint[1] * 100).toFixed(1) + "%";
      },
      legendLabel: function(name) {
        return name;
      },
      data: data,
      flotHooks: {},
      preprocessDataFunction: function (data) {
        if (data['TC_STAMP_DURATION_KEY']) {
          var stamps = data['TC_STAMP_DURATION_KEY'];
          delete data['TC_STAMP_DURATION_KEY'];
        }
        if (stamps) {
          if (data['TC_GC_USAGE_KEY']) {
            for (var j = 0; j < data['TC_GC_USAGE_KEY'].length && j < stamps.length; ++j) {
              data['TC_GC_USAGE_KEY'][j][1] /= stamps[j][1];
            }
          }
          if (data['TC_JAVA_PROCESS_CPU_USAGE_KEY']) {
            for (j = 0; j < data['TC_JAVA_PROCESS_CPU_USAGE_KEY'].length && j < stamps.length; ++j) {
              data['TC_JAVA_PROCESS_CPU_USAGE_KEY'][j][1] /= stamps[j][1];
            }
          }
        }
      },
      preprocessSerieFunction: function(key, serie) {
        if (key == 'TC_GC_USAGE_KEY') {
          serie.label = serie.labelId = 'Garbage collection';
          serie.description = "Time spent on cleaning memory averaged over a period of time";
        }
        if (key == 'TC_JAVA_PROCESS_CPU_USAGE_KEY') {
          serie.label = serie.labelId = 'TeamCity process CPU usage';
          serie.description = "CPU time used by TeamCity process averaged over a period of time";
        }
        if (key == 'TC_SYSTEM_LOAD_KEY') {
          serie.label = serie.labelId = 'System load (1 min average)';
          serie.description = "The sum of the number of runnable entities queued to the available processors and the number of runnable entities running on the available processors averaged over a period of time (1 minute)";
        }
        if (key == 'TC_SYSTEM_CPU_USAGE_KEY') {
          serie.label = serie.labelId = 'Overall CPU usage';
          serie.description = "The \"recent cpu usage\" for the whole system. This value is in the [0.0,1.0] interval. A value of 0.0 means that all CPUs were idle during the recent period of time observed, while a value of 1.0 means that all CPUs were actively running 100% of the time during the recent period being observed";
        }
      }
    });
  }
};
