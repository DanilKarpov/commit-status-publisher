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

BS.CustomChart = {
  sendCreateNewChart: function (newData, projectId, btId, chartGroup, onSuccess, onFail, listener) {
    if (listener) {
      BS.FormSaver.save(
          { serializeParameters: function() {return {action: "addChart", newXml: newData, projectId: projectId, buildTypeId: btId, chartGroup: chartGroup};}},
          window['base_uri'] + '/editChart.html', listener
      );
    } else {
      BS.ajaxRequest(window['base_uri'] + '/editChart.html', {
        method: "post",
        parameters: {
          action: "addChart", newXml: newData, projectId: projectId, buildTypeId: btId, chartGroup: chartGroup
        },
        onComplete: function (transport) {
          if (transport.responseXML && transport.responseXML.firstChild) {
            var response = transport.responseXML.firstChild;
            var status = response.getElementsByTagName("status")[0];
            if (status && status.firstChild.data == "ok") {
              if (typeof onSuccess === "function") {
                onSuccess(response);
              }
            } else {
              if (typeof onFail === "function") {
                onFail(response);
              }
            }
          }
          return false;
        }
      });
    }
  },

  getChartXmlByAJAX: function (projectId, btId, chartGroup, chartId, onSuccess, onFail) {
    BS.ajaxRequest(window['base_uri'] + '/editChart.html', {
      method: "post",
      parameters: {
        action: "getChartXml", projectId: projectId, buildTypeId: btId, chartGroup: chartGroup, graphKey: chartId
      },
      onComplete: function (transport) {
        if (transport.responseXML && transport.responseXML.firstChild) {
          var response = transport.responseXML.firstChild;
          var status = response.getElementsByTagName("status")[0];
          if (status && status.firstChild.data == "ok") {
            if (typeof onSuccess === "function") {
              onSuccess(response);
            }
          } else {
            if (typeof onFail === "function") {
              onFail(response);
            }
          }
        }
        return false;
      }
    });
  },

  sendEditChart: function (newData, projectId, btId, idEscaped, chartGroup, onSuccess, onFail, listener) {
    if (listener) {
      BS.FormSaver.save(
          { serializeParameters: function() {return {action: "editChart", newXml: newData, projectId: projectId, buildTypeId: btId, graphKey: idEscaped, chartGroup: chartGroup};}},
          window['base_uri'] + '/editChart.html', listener
      );
    } else {
      BS.ajaxRequest(window['base_uri'] + '/editChart.html', {
        method: "post",
        parameters: {
          action: "editChart", newXml: newData, projectId: projectId, buildTypeId: btId, graphKey: idEscaped, chartGroup: chartGroup
        },
        onComplete: function (transport) {
          if (transport.responseXML && transport.responseXML.firstChild) {
            var response = transport.responseXML.firstChild;
            var status = response.getElementsByTagName("status")[0];
            if (status.firstChild.data == "ok") {
              if (typeof onSuccess === "function") {
                onSuccess(response);
              }
            } else {
              if (typeof onFail === "function") {
                onFail(response);
              }
            }
          }
          return false;
        }
      });
    }
  },

  EditCustomChartPopup: OO.extend(BS.AbstractModalDialog, {
    data: null,
    initData: null,
    projectId: null,
    projectExtId: null,
    projectName: null,
    sourceProjectId: null,
    buildTypeId: null,
    groupId: null,
    chartId: null,
    cache: [],
    forceShowCentered: false,
    reloadPageAfterSave: true,
    init: function(elementId, dialogOptions) {
      this.getContainer = function() {
        return $(elementId);
      };

      var that = this;
      var $p = this.getPopupElement();
      var shouldUpdateXMLBeforeSubmit = true;
      this.initData = "<graph>\n</graph>";
      this.data = $j.parseXML(this.initData);
      if (!Object.isUndefined(dialogOptions)) {
        this.forceShowCentered = !Object.isUndefined(dialogOptions.forceShowCentered) ? dialogOptions.forceShowCentered : this.forceShowCentered;
        this.reloadPageAfterSave = !Object.isUndefined(dialogOptions.reloadPageAfterSave) ? dialogOptions.reloadPageAfterSave : this.reloadPageAfterSave;
      }

      $p.on("valueTypeAdded", function() {
        $p.find(".valueTypeHeader").show();
      });
      $p.on("valueTypeRemoved", function() {
        if ($p.find(".valueType").not(".proto").length == 0) {
          $p.find(".valueTypeHeader").hide();
        }
      });
      $p.on("click", ".simpleTabs .tabs li", function(e) {
        var $tabHandle = $j(e.currentTarget);
        var $currentTabHandle = $p.find(".simpleTabs .tabs .selected");

        $currentTabHandle.removeClass("selected");
        $tabHandle.addClass("selected");

        var $tabToOpen = $p.find("#" + $tabHandle.attr("id") + "-content");
        var $tabToHide = $p.find("#" + $currentTabHandle.attr("id") + "-content");

        $tabToHide.hide();
        $tabToOpen.show();

        $p.trigger("tabOpened", {openedTabId: $tabHandle.attr("id"), closedTabId: $currentTabHandle.attr("id")});
      });
      $p.on("tabOpened", function(e, params) {
        switch (params.openedTabId) {
          case 'xmlTab':
            shouldUpdateXMLBeforeSubmit = false;
            that.updateXMLValue();
            that.hideMessages();
            break;
          case 'generalTab':
            shouldUpdateXMLBeforeSubmit = true;
            that.data = $j.parseXML($p.find(".editChart.data").val());
            that.clear();
            that.populateData();
            break;
        }
      });
      $p.on("click", ".removeValueType", function(e) {
        var $elt = $j(e.currentTarget);
        that.removeValueTypeByIdx($elt.parent().index());
        return false;
      });
      $p.on("click", ".closeWindowLink", function (/*e*/) {
        that.hidePopup();
        BS.CustomChart.unlockProject();
      });
      $p.on("click", ".cancelEditChart", function (/*e*/) {
        delete that.cache[that.getChartId()];
        that.data = that.initData = null;
        that.hidePopup();
        BS.CustomChart.unlockProject();
      });
      $p.on("click", ".deleteChartXml", function() {
        var message = "Chart will be permanently deleted. Proceed?";

        BS.confirm(message, function () {
          var id = that.chartId;
          var idEscaped = BS.Util.escapeId(id);
          var btId = that.buildTypeId;
          var projectId = that.projectId;
          var chartGroup = that.groupId;

          BS.ajaxRequest(window['base_uri'] + '/editChart.html', {
            method: "post",
            parameters: {
              action: "deleteChart", projectId: projectId, buildTypeId: btId, graphKey: idEscaped.substring(1), chartGroup: chartGroup
            },
            onComplete: function (transport) {
              if (transport.responseXML && transport.responseXML.firstChild) {
                var response = transport.responseXML.firstChild;
                var status = response.getElementsByTagName("status")[0];
                if (status.firstChild.data == "ok") {
                  that.hidePopup();
                  BS.reload(false);
                }
              }
              return false;
            }
          });

        });
        return false;
      });
      $p.on("popupHidden", function (/*e*/) {
        if (that.data != null && that.initData != null) {
          var unsaved = false;
          var data = null;
          if (shouldUpdateXMLBeforeSubmit) {
            that.updateXMLValue();
            if (BS.CustomChart.xmlToString(that.data) != BS.CustomChart.xmlToString($j.parseXML(that.initData))) {
              unsaved = true;
              data = BS.CustomChart.xmlToString(that.data);
            }
          } else {
            var val = $p.find(".editChart.data").val();
            if (BS.CustomChart.xmlToString($j.parseXML(val)) != BS.CustomChart.xmlToString($j.parseXML(that.initData))) {
              unsaved = true;
              data = val;
            }
          }
          that.cache[that.getChartId()] = data;
          if (unsaved) {
            var $t = $j(".graphHeader[id='" + that.chartId + "TT']");
            if ($t.find(".unsaved").length == 0) {
              $t.find(".editChartToggle").before("<span class='unsaved'>Changes are not saved</span>");
            }
          } else {
            $j(".graphHeader[id='" + that.chartId + "TT'] .unsaved").remove();
          }
        } else if (that.chartId) {
          $j(".graphHeader[id='" + that.chartId + "TT'] .unsaved").remove();
        }
      });
      $p.on("click", ".submitChartXml", function (/*e*/) {
        if (shouldUpdateXMLBeforeSubmit) that.updateXMLValue();
        that.submit();
      });
      $p.on("change", "select.valueTypeChooser", function (e) {
        if (e.currentTarget.options[e.currentTarget.selectedIndex]) {
          var $chooser = $j(e.currentTarget);
          var key = $chooser.val();
          var $option = $j("select.valueTypeChooser option").filter(function(idx, elt) {return elt.value == key});
          var title = $option.attr("data-filter-data");
          that.addValueType(key, title);

          e.currentTarget.selectedIndex = 0;
          $j(e.currentTarget).ufd("changeOptions");
        }
      });
      $p.on('keyup', '#manualVtChooserInput', function (e) {
        $j('#manualVtChooserError').text('').hide();
        if (e.keyCode == 13) {
          $j('#manualAddValueType').fire('click');
        }
      });
      $p.on('click', '#manualAddValueType', function (e) {
        var $manualChooser = $j('#manualVtChooserInput');
        var value = $manualChooser.val();
        if ($manualChooser[0].customData) {
          if (value) {
            if ($manualChooser[0].customData[value]) {
              that.addValueType(value, $manualChooser[0].customData[value].description);
              $manualChooser.val('');
            } else {
              $j('#manualVtChooserError').text('Value type \'' + value + '\' not found').show();
            }
          } else {
            $j('#manualVtChooserError').text('Please type a key').show();
          }
        } else {
          $j('#manualVtChooserError').text('Value types are not loaded yet').show();
        }
      });


      return this;
    },
    getChartId: function() {
      return this.chartId != null ? this.chartId : "<new chart>";
    },
    updateXMLValue: function () {
      var $data = $j(this.data);
      $data.find("valueType").remove();
      $data.find("valueTypes").remove();
      var $p = this.getPopupElement();
      var that = this;
      $p.find(".editValueTypes .valueType").not(".proto").not(".pattern").each(function (idx, item) {
        var $vt = $j(item);
        that.createValueTypeElement($vt.find(".key").text(), $vt.find(".title").val(), $vt.find("#sourceBuildTypeId").val());
      });
      $p.find(".editValueTypes .valueType").filter(".pattern").each(function (idx, item) {
        var $vt = $j(item);
        that.createValueTypeElement($vt.find(".key").get(0).lastChild.nodeValue, $vt.find(".title").val(), $vt.find("#sourceBuildTypeId").val(), true);
      });
      var seriesTitle = $p.find("#seriesTitle").val();
      var graph = $data.find("graph");
      var format = $p.find("#dataFormat").val();
      graph.attr("title", $p.find("#chartTitle").val());
      if (seriesTitle) {
        graph.attr("seriesTitle", seriesTitle);
      } else {
        graph.removeAttr("seriesTitle");
      }
      if (format) {
        graph.attr("format", format);
      } else {
        graph.removeAttr("format");
      }
      this.getPopupElement().trigger("updateXMLValue");
      $p.find(".data").val(BS.CustomChart.xmlToString(this.data));
    },
    createValueTypeElement: function (key, title, sourceBT, pattern) {
      if (this.data == null) {
        this.initData = "<graph>\n</graph>";
        this.data = $j.parseXML(this.initData);
      }
      var newElement = pattern ? this.data.createElement("valueTypes") : this.data.createElement("valueType");
      if (key) {
        newElement.setAttribute(pattern ? "pattern" : "key", key);
      }
      if (title) {
        newElement.setAttribute("title", title);
      }
      if (sourceBT) {
        newElement.setAttribute("sourceBuildTypeId", sourceBT);
      }
      if (newElement.insertAdjacentText) {
        this.data.firstChild.appendChild(newElement);
        newElement.insertAdjacentText("beforeBegin", "  ");
        newElement.insertAdjacentText("afterEnd", "\n");
      } else {
        var spaces = this.data.createTextNode("  ");
        this.data.firstChild.appendChild(spaces);
        this.data.firstChild.appendChild(newElement);
        var newLine = this.data.createTextNode("\n");
        this.data.firstChild.appendChild(newLine);
      }
    },
    getPopupElement: function() {
      return $j("#editChartDialog");
    },
    removeValueType: function(key) {
      $j(this.data).find("valueType[key='" + key + "']").first().remove();
      this.getPopupElement().find(".data").val(BS.CustomChart.xmlToString(this.data));
      this.getPopupElement().find(".editValueTypes .valueType label[data-key='" + key + "']").parent().remove();
      this.getPopupElement().trigger("valueTypeRemoved", {key: key});
      if ($j(this.data).find("valueType").length == 0 && $j(this.data).find("valueTypes").length == 0) {
        this.getPopupElement().find(".submitButton").attr("disabled", "disabled");
      }
    },
    removeValueTypeByIdx: function(idx) {
      var found = $j(this.data).find("valueType:eq(" + idx + ")");
      if (found) {
        var key = found.attr("key");
        found.remove();
        this.getPopupElement().find(".data").val(BS.CustomChart.xmlToString(this.data));
        this.getPopupElement().find(".editValueTypes .valueType").not(".proto").filter(":eq(" + idx + ")").remove();
        this.getPopupElement().trigger("valueTypeRemoved", {key: key});
        if ($j(this.data).find("valueType").length == 0 && $j(this.data).find("valueTypes").length == 0) {
          this.getPopupElement().find(".submitButton").attr("disabled", "disabled");
        }
      }
    },
    addValueType: function(key, title, sourceBuildTypeId) {
      this._addValueType(key, title, sourceBuildTypeId);
      this.createValueTypeElement(key, title, sourceBuildTypeId);
      this.getPopupElement().find(".data").val(BS.CustomChart.xmlToString(this.data));
    },
    _addValueType: function(key, title, sourceBuildTypeId, isPatterned) {
      var $proto = $j(".editValueTypes .valueType.proto");
      var $new = $j(".editValueTypes .valueType:last").after($proto.clone());
      $new.find("#key").text(key).attr("data-key", key).on("mouseover", function(event) {
        BS.Tooltip.showMessage(event.currentTarget, {shift: {x: 100, y: 15}}, key.escapeHTML());
      }).on("mouseout", function() {
        BS.Tooltip.hidePopup();
      });
      if (isPatterned) {
        $new.addClass("pattern");
        $new.find("#key").prepend("<span class='patternNote greyNote'>pattern: </span>");
        $new.find(".removeValueType").remove();
      }
      $new.find("#title").val(title);
      $new.find("#sourceBuildTypeId").val(sourceBuildTypeId);
      $new.find("#sourceBuildTypeNote").text("From: " + sourceBuildTypeId);
      $new.removeClass("proto").show();
      this.getPopupElement().trigger("valueTypeAdded", {key: key});
      this.getPopupElement().find(".submitButton").removeAttr("disabled");
    },
    hideMessages: function() {
      this.getPopupElement().find('.status div').html("").hide();
    },
    clear: function() {
      this.hideMessages();
      this.getPopupElement().find(".valueTypeHeader").hide();
      this.getPopupElement().find('.editValueTypes .valueType').not(".proto").remove();
    },
    populateData: function() {
      var $dialog = this.getPopupElement();
      var $data = $j(this.data);
      var that = this;
      $data.find("valueType").each(function(idx, item) {
        var $item = $j(item);
        that._addValueType($item.attr("key"), $item.attr("title"), $item.attr("sourceBuildTypeId"));
      });
      $data.find("valueTypes").each(function(idx, item) {
        var $item = $j(item);
        that._addValueType($item.attr("pattern"), $item.attr("title"), $item.attr("sourceBuildTypeId"), true);
      });
      $dialog.find("#chartTitle").val($data.find("graph").attr("title"));
      $dialog.find("#seriesTitle").val($data.find("graph").attr("seriesTitle"));
      ($dialog.find("#dataFormat")[0]).setSelectValue($data.find("graph").attr("format"));
      $dialog.find(".data").val(BS.CustomChart.xmlToString(that.data));
      $dialog.trigger("populateData");
      var sourceProject = $dialog.find(".sourceProject");
      if (this.getPopupElement().find("input#currentProjectId").val() != this.sourceProjectId && this.sourceProjectId != null) {
        sourceProject.show();
      } else {
        sourceProject.hide();
      }
      if (this.projectExtId != "_Root") {
        sourceProject.find(".projectExtId").html("<a href='" + window['base_uri'] + "/project.html?projectId=" + this.projectExtId + "'>" +
          (this.projectName ? this.projectName.escapeHTML() : "&lt;Unknown project&gt;") + "</a>");
      } else {
        sourceProject.find(".projectExtId").text("Root");
      }
    },
    _showXml: function(xml, popupTitle) {
      if (xml == null || xml == "" || typeof xml === 'undefined') {
        xml = "<graph title=\"New chart title\" seriesTitle=\"Serie\">\n</graph>";
      }
      this.data = $j.parseXML(xml);
      this.populateData();
      var $e = this.getPopupElement();
      if (popupTitle) {
        $e.find(".dialogTitle").get(0).firstChild.nodeValue = popupTitle;
      }
      var $graph = $j(this.data).find("graph");
      if ($graph.attr("title")) {
        $e.find(".chartTitle").val($graph.attr("title"));
      }
      if ($graph.attr("seriesTitle")) {
        $e.find(".seriesTitle").val($graph.attr("seriesTitle"));
      }
    },
    hidePopup: function() {
      this.getPopupElement().trigger("popupHidden");
      BS.CustomChart.unlockProject();
      BS.Hider.hideDiv(this.getPopupElement().attr("id"));
    },
    showData: function(element, projectId, buildTypeId, groupId, valueTypes, chartTitle, seriesTitle, popupTitle) {
      this.hidePopup();
      this.initData = "<graph>\n</graph>";
      this.data = $j.parseXML(this.initData);
      this.projectId = projectId;
      this.buildTypeId = buildTypeId;
      this.groupId = groupId;
      this.sourceProjectId = null;
      var that = this;
      if (valueTypes && valueTypes.length > 0) {
        valueTypes.forEach(function (valueType) {
          that.addValueType(valueType.key, valueType.title, valueType.sourceBuildTypeId);
        });
      }
      var $e = this.getPopupElement();
      if (popupTitle) {
        $e.find(".dialogTitle").get(0).firstChild.nodeValue = popupTitle;
      }
      if (chartTitle) {
        $e.find("#chartTitle").val(chartTitle);
      }
      if (seriesTitle) {
        $e.find("#seriesTitle").val(seriesTitle);
      }
      this.updateXMLValue();
      this.showDialog(element);
    },
    showDialog: function(element) {
      var $p = this.getPopupElement();
      if (this.chartId) {
        $p.find(".deleteChartXml").show();
      } else {
        $p.find(".deleteChartXml").hide();
      }
      if ($j(this.data).find("valueType").length == 0 && $j(this.data).find("valueTypes").length == 0) {
        $p.find(".submitButton").attr("disabled", "disabled");
      } else {
        $p.find(".submitButton").removeAttr("disabled");
      }
      if (element && !this.forceShowCentered) {
        var xShift = this.chartId ? (-510 + element.width()) : 0;

        this.showAt(element[0].offset().x + xShift, element[0].offset().y + element.height() * 2);
      } else {
        this.showCentered();
      }
      BS.Hider.addHideFunction($p.attr("id"), function() {
        $p.trigger("popupHidden");
      });
      $p.find("#chartTitle").focus();
    },
    show: function(element, projectId, buildTypeId, groupId, chartId) {
      this.hidePopup();
      this.initData = "<graph>\n</graph>";
      this.data = $j.parseXML(this.initData);
      this.projectId = projectId;
      this.buildTypeId = buildTypeId;
      this.groupId = groupId;
      this.chartId = chartId;
      this.sourceProjectId = null;
      var $dialog = this.getPopupElement();
      this.clear();
      $dialog.find(".submitChartXml").attr("data-chart-id", chartId).attr("data-chart-group", groupId).attr("data-project-id", projectId).attr("data-buildtype-id", buildTypeId);

      if (chartId) {
        this.disable();
        this._showXml(null, "Edit Custom Chart");
        var that = this;
        BS.CustomChart.getChartXmlByAJAX(projectId, buildTypeId, groupId, chartId, function (response) {
          that.enable();
          if (that.cache[that.getChartId()] != null) {
            that.initData = response.getElementsByTagName("data")[0].firstChild.nodeValue;
            that._showXml(that.cache[that.getChartId()]);
            if (!element) {
              BS.AbstractModalDialog.positionAtFixed(that.getPopupElement());
            }
          } else {
            that.initData = response.getElementsByTagName("data")[0].firstChild.nodeValue;
            that.projectExtId = response.getElementsByTagName("data")[0].getAttribute("projectExtId");
            that.projectName = response.getElementsByTagName("data")[0].getAttribute("projectName");
            that.sourceProjectId = response.getElementsByTagName("data")[0].getAttribute("projectId");
            that._showXml(that.initData);
            if (!element) {
              BS.AbstractModalDialog.positionAtFixed(that.getPopupElement());
            }
          }
          if ($dialog.find(".chartTitle").val()) {
            $dialog.find(".dialogTitle").get(0).firstChild.nodeValue = "Edit Chart \"" + $dialog.find(".chartTitle").val() + "\"";
          }
        });
      } else {
        this._showXml(null, "Add Custom Chart");
      }
      this.showDialog(element);
    },
    disable: function() {
      this.getPopupElement().find(":enabled").attr("disabled", "disabled");
    },
    enable: function() {
      this.getPopupElement().find("*").removeAttr("disabled");
      if ($j(this.data).find("valueType").length == 0 && $j(this.data).find("valueTypes").length == 0) {
        this.getPopupElement().find(".submitButton").attr("disabled", "disabled");
      }
      this.getPopupElement().find("#chartTitle").focus();
    },
    submit: function() {
      var $dialog = this.getPopupElement();
      var newData = $dialog.find(".editChart").val();
      var idEscaped = this.chartId ? BS.Util.escapeId(this.chartId) : "";
      var id = this.chartId ? this.chartId : "";
      var that = this;

      var listener = OO.extend(BS.ErrorsAwareListener, {
        onBeginSave: function () {
          $dialog.find('.status div').html("").hide();
          that.disable();
        },
        onCompleteSave: function (form, responseXML, err/*, responseText*/) {
          that.enable();
          if (!err) {
            if (responseXML.getElementsByTagName("status") && responseXML.getElementsByTagName("status")[0].firstChild.data == "ok") {
              $dialog.find('.successMessage').text("Saved").show();
              that.getPopupElement().trigger("chartSaved", {chartId: id, chartGroup: that.groupId, buildTypeId: that.buildTypeId, projectId: that.projectId});
              if (id) {
                BS.Chart.applyFilter.call($(that.projectExtId + idEscaped.substring(1) + "Form .chartHolder"), that.projectExtId + idEscaped.substring(1), id, '');
              }
              delete that.cache[that.getChartId()];
              that.initData = null;
              that.hidePopup();
              if (that.chartId == null && that.reloadPageAfterSave) {
                BS.reload (false);
              }
            } else {
              that.getPopupElement().trigger("saveFailed", {chartId: id, chartGroup: that.groupId, buildTypeId: that.buildTypeId, projectId: that.projectId});
              $dialog.find('.error').text("Data was not saved").show();
            }
          }
        },
        xmlEditError: function (elem) {
          $dialog.find('.error').text(elem.firstChild.nodeValue).show();
        }
      });

      if (this.chartId) {
        BS.CustomChart.sendEditChart(newData, this.projectId, this.buildTypeId, idEscaped.substring(1), this.groupId, null, null, listener);
      } else {
        BS.CustomChart.sendCreateNewChart(newData, this.projectId, this.buildTypeId, this.groupId, null, null, listener);
      }
    }
  }),

  ReorderChartsDialog: OO.extend(BS.AbstractModalDialog, OO.extend(BS.AbstractWebForm, {
    getContainer: function () {
      return $('reorderChartsDialog');
    },

    formElement: function () {
      return $('reorderChartsDialogForm');
    },

    savingIndicator: function () {
      return $('saveOrderProgress');
    },

    fixPageScroll: function () {
      window.scrollTo(0, 0);
    },

    submitForm: function () {
      return false;
    }
  })),

  initEditListeners: function(currentProjectId, chartGroup) {
    var popup = BS.CustomChart.EditCustomChartPopup.init('editChartDialog', {forceShowCentered: true});

    $j(document).on("click", ".editChartToggle", function (e) {
      var $editToggle = $j(e.currentTarget);
      if (!$editToggle.is(".hold")) {
        $editToggle.addClass("hold");
        popup.show($editToggle, $editToggle.attr("data-project-id"), $editToggle.attr("data-buildtype-id"), $editToggle.attr("data-chart-group"),
                   $editToggle.attr("data-chart-id"));
        $j(".GraphContainer#" + $editToggle.attr("data-chart-id") + "Container").addClass("highlighted");
        BS.CustomChart.blockProject();
        BS.Hider.addHideFunction(popup.getPopupElement().attr("id"), function () {
          setTimeout(function() {$editToggle.removeClass("hold");}, 50);
        });
      }
    });

    popup.getPopupElement().on("popupHidden", function (/*e*/) {
      $j(".GraphContainer.highlighted").removeClass("highlighted");
    });

    $j(".createChartXml").click(function (e) {
      var $editToggle = $j(e.currentTarget);
      var btId = $editToggle.attr("data-buildtype-id");
      var projectId = $editToggle.attr("data-project-id");
      var chartGroup = $editToggle.attr("data-chart-group");
      var newData = $j(".addChartBlock .editChart").val();

      BS.CustomChart.sendCreateNewChart(newData, projectId, btId, chartGroup, function() {
        if (popup.reloadPageAfterSave) {
          BS.reload(true);
        }
      });

      return false;
    });

    var $dialog = $j("#reorderChartsDialog");
    var form = BS.createReorderDialog("reorderChartsDialog", $j("#sortableList"), function(newOrder) {
      form.setDisabled(true);
      BS.ajaxRequest(window['base_uri'] + '/editChart.html', {
        parameters: {action: "reorderCharts", projectId: currentProjectId, chartGroup: chartGroup, newOrder: newOrder},
        onComplete: function (/* transport */) {
          form.setDisabled(false);
          BS.CustomChart.ReorderChartsDialog.close();
          BS.reload(true);
        }
      });
    });
    if ($dialog) {
      $dialog.find(".cancel").on("click", function() {
        BS.CustomChart.ReorderChartsDialog.close();
      });
      $dialog.bind("saveDialog", function () {
      });

      $j("#sortableList").sortable({
                                     cancel: '.inherited',
                                     tolerance: 'pointer',
                                     scroll: true,
                                     axis: 'y',
                                     opacity: 0.7
                                   });
      $j(".reorderChartsButton").click(function() {
        $j("#sortableList").sortable("enable");
        BS.CustomChart.ReorderChartsDialog.showCentered();
      });
    }

    return popup;
  },

  updateValueTypes: function(/*BS.CustomChart.EditCustomChartPopup*/ popup, /*String*/ sourceBuildTypeId, /*Boolean*/ doClear) {
    function spawnValueTypes($vtChooser, valueTypes) {
      var $proto = $vtChooser.find("option");
      if (valueTypes.length == 0) {
        if ($proto.attr("data-init-text") == null) {
          $proto.attr("data-init-text", $proto.text());
        }
        $proto.text("No statistic values in this build");
        $vtChooser.attr("disabled", "disabled");
      } else {
        if ($proto.attr("data-init-text") != null) {
          $proto.text($proto.attr("data-init-text"));
        }
      }

      if (valueTypes.length < 10000) {
        var texts = [];
        for (var vtI = 0; vtI < valueTypes.length; ++vtI) {
          var vt = valueTypes[vtI];
          var key = vt.firstChild.data;
          var text = vt.getAttribute("description") != null ? vt.getAttribute("description") + " (" + key + ")" : key;
          var description = vt.getAttribute("description") != null ? vt.getAttribute("description") : key;
          texts.push({key: vt.firstChild.data, text: text, description: description});
        }
        texts.sort(function (a, b) {
          return (a.text).localeCompare(b.text)
        });

        var tempArr = [];
        for (vtI = 0; vtI < texts.length; ++vtI) {
          var t = texts[vtI];
          var $newElement = $proto.clone();
          $newElement.val(t.key).removeAttr("disabled").attr("data-title", t.key + " " + t.text).attr("data-filter-data", t.description).text(t.text);
          tempArr.push($newElement);
        }
        $vtChooser.find("option:last").after(tempArr);

        $j("#valueTypeChooser")[0].selectedIndex = 0;

        $j('#manualVtChooser').hide();
        $j("#vtChooser").show();

        $vtChooser.ufd("changeOptions");
      } else {
        var $manualChooser = $j('#manualVtChooserInput');

        var data = {};
        for (vtI = 0; vtI < valueTypes.length; ++vtI) {
          vt = valueTypes[vtI];
          key = vt.firstChild.data;
          data[key] = {text: vt.getAttribute('description') ? vt.getAttribute('description') + ' (' + key + ')' : key, description: vt.getAttribute('description') ? vt.getAttribute('description') : key};
        }

        $manualChooser[0].customData = data;

        $j('#manualVtChooser').show();
        $j("#vtChooser").hide();
        $vtChooser.ufd("changeOptions");
      }
    }

    popup.getPopupElement().find('*[id!=\'cancelEditChart\']').each(function(idx, elt) {
      var $elt = $j(elt);
      if (!$elt.attr('disabled')) {
        $elt.attr('disabled', 'disabled');
      }
    });
    popup.getPopupElement().find("#editCustomChartSpinner").show();
    BS.ajaxRequest(window['base_uri'] + '/editChart.html', {
      method: "post",
      parameters: {
        action: "getAvailableValueTypes", projectId: popup.projectId, buildTypeId: sourceBuildTypeId
      },
      onComplete: function (transport) {
        var $vtChooser = popup.getPopupElement().find("select.valueTypeChooser");
        popup.getPopupElement().find(".spinner").hide();
        if (transport.responseXML && transport.responseXML.firstChild) {
          var response = transport.responseXML.firstChild;
          var status = response.getElementsByTagName("status")[0];
          if (status && status.firstChild.data == "ok") {
            if (doClear) {
              popup.clear();
            }
            var $options = $vtChooser.find("option").not(":first");
            $options.remove();
            var valueTypes = response.getElementsByTagName("valueTypes")[0];
            if (!Object.isUndefined(valueTypes)) {
              var children = $j(valueTypes).children();
              spawnValueTypes($vtChooser, children);

              var $sortableList = $j(".sortableValueTypes");
              var initState = [];
              $sortableList.find(".smallSortable").each(function(idx, elt) { initState.push(elt.innerHTML); });

              $sortableList.sortable({
                                       //cancel: ".inherited",
                                       tolerance: "pointer",
                                       scroll: true,
                                       axis: "y",
                                       opacity: 0.7,
                                       cancel: 'input'
                                     });
            }
          } else {
            // cannot load available value types
          }
        }
        popup.getPopupElement().find("#editCustomChartSpinner").hide();
        $vtChooser.removeAttr("disabled");

        popup.getPopupElement().find('*[disabled=\'disabled\']').each(function(idx, elt) {
          var $elt = $j(elt);
          $elt.removeAttr('disabled');
        });

        return false;
      }
    });
  },

  initBuildTypeChooser: function (popup) {
    var chooser = popup.getPopupElement().find("#buildTypeChooser")[0];

    function getSelectedBuildTypeId() {
      return chooser.options[chooser.selectedIndex].value;
    }

    function updateBTLink(sourceBuildTypeId) {
      if (sourceBuildTypeId) {
        var btLink = popup.getPopupElement().find(".buildTypeChooser .btLink");
        var initHref = btLink.attr("href");
        btLink.attr("href", initHref.replace(/\?buildTypeId=.*&/, "?buildTypeId=" + sourceBuildTypeId + "&")).show();
      } else {
        popup.getPopupElement().find(".buildTypeChooser .btLink").hide();
      }
    }

    $j(popup.data).find("graph").attr("sourceBuildTypeId", getSelectedBuildTypeId());

    popup.getPopupElement().on("populateData", function () {
      const selected = $j(popup.data).find("graph valueType,valueTypes:first").attr("sourceBuildTypeId");
      const select = document.getElementById('buildTypeChooser');
      const options = [...select.options];
      ReactUI.renderConnected(document.getElementById('buildTypeChooserSelect'), ReactUI.ProjectBuildTypeSelect, {
        expandAll: true,
        includedBuildTypes: options.map(option => option.value),
        selected: selected != null ? {nodeType: 'bt', id: selected} : null,
        onSelect(item) {
          var sourceBuildTypeId = item.id;
          select.value = sourceBuildTypeId;
          popup.getPopupElement().find("select.valueTypeChooser").removeAttr("disabled");
          popup.sourceBuildTypeId = sourceBuildTypeId;
          popup.getPopupElement().find("select.valueTypeChooser").attr("disabled", "disabled");
          BS.CustomChart.updateValueTypes(popup, sourceBuildTypeId, true);
          updateBTLink(sourceBuildTypeId);
        }
      });
      if (!selected) {
        popup.getPopupElement().find("select.valueTypeChooser").attr("disabled", "disabled");
        updateBTLink();
      } else {
        if (popup.sourceBuildTypeId != selected) {
          popup.sourceBuildTypeId = selected;
          BS.CustomChart.updateValueTypes(popup, popup.sourceBuildTypeId, false);
        }
        updateBTLink(popup.sourceBuildTypeId);
      }
      popup.getPopupElement().find(".valueType").not(".proto").find(".sourceBuildTypeNote").each(function(idx, el) {$j(el).siblings("#sourceBuildTypeId").val() != getSelectedBuildTypeId() ? $j(el).show() : $j(el).hide();});
    });
    popup.getPopupElement().on("updateXMLValue", function () {
      $j(popup.data).find("graph valueType").filter(function(idx, el) {return !$j(el).attr("sourceBuildTypeId")}).attr("sourceBuildTypeId", getSelectedBuildTypeId());
    });

    popup.getPopupElement().find("select.valueTypeChooser").attr("disabled", "disabled");
  },

  blockProject: function() {
    BS.blockRefreshPermanently("chartEdit");
  },

  unlockProject: function() {
    BS.unblockRefresh("chartEdit");
  },

  addValueTypeToXml: function (xml, key, btId, title) {
    var endTag = xml.indexOf("</graph>");
    var patch = "";
    if (endTag < 0) {
      endTag = xml.indexOf("/>");
      patch = ">";
    }

    var vtTag;
    if (btId) {
      vtTag = "  <valueType key=\"" + key + "\" sourceBuildTypeId=\"" + btId + "\" title=\"" + title + "\"/>\n";
    } else {
      vtTag = "  <valueType key=\"" + key + "\" title=\"" + title + "\"/>\n";
    }
    return xml.substring(0, endTag) + patch + vtTag + "</graph>";
  },

  removeValueTypeFromXml: function (xml, key) {
    return xml.replace(new RegExp("^[ \t]*<valueType key=['\"]" + key + "['\"].*(\/>|<\/valueType>) *[\n\r]*", "mi"), "");
  },

  xmlToString: function (xml) {
    if (!xml) return xml;

    function removeEmptyLines(str) {
      return str ? str.replace(new RegExp("^\\s*$|\\s*$", "mg"), "") : "";
    }

    if (typeof window.XMLSerializer != "undefined") {
      return removeEmptyLines((new window.XMLSerializer()).serializeToString(xml));
    } else if (typeof xml.xml != "undefined") {
      return removeEmptyLines(xml.xml);
    } else {
      return removeEmptyLines($j(xml).children().html());
    }
  }
};