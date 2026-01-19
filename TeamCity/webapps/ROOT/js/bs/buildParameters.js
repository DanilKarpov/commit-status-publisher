/**
 * Created by Andrey Titov on 9/10/14.
 */
BS.BuildParameters = {
  clearCheckBoxes: function () {
    $j(".valueTypeToggle").removeAttr("checked").removeAttr("disabled");
    BS.BuildParameters.toggleDock();
  },

  toggleDock: function () {
    $j("#add-to-chart-docked").trigger("toggleDock");
  },

  sharedChartPopup: new BS.Popup('chartDialogPopup', {
    delay: 0,
    hideDelay: -1,
    url: window['base_uri'] + "/buildGraph.html?jsp=buildLog/buildParametersChart.jsp",
    backgroundColor: 'transparent',
    loadingText: 'Loading chart...'
  }),

  initHandlers: function (projectId, buildTypeId) {
    var popup = BS.CustomChart.EditCustomChartPopup.init('editChartDialog', {reloadPageAfterSave: false});

    popup.getPopupElement().on("valueTypeAdded", function(e, data) {
      $j(".valueTypeToggle").filter(function(idx, elt) {return $j(elt).attr('data-vt-key') == data.key;}).not(":checked").attr("checked", "checked");
    });

    popup.getPopupElement().on("valueTypeRemoved", function(e, data) {
      $j(".valueTypeToggle:checked").filter(function(idx, elt) {return $j(elt).attr('data-vt-key') == data.key;}).removeAttr("checked");
    });

    popup.getPopupElement().on("populateData", function() {
      var chooser = popup.getPopupElement().find("#buildTypeChooser")[0];
      popup.projectId = chooser.options[chooser.selectedIndex].value;
    });


    popup.getPopupElement().on("chartSaved", function(e, data) {
      popup.hidePopup();
      BS.BuildParameters.clearCheckBoxes();
      if (data.chartGroup == "project-graphs") {
        var initHref = $j(".buildParameters .successMessage .projectLink").attr("href");
        $j(".buildParameters .successMessage .projectLink").attr("href", initHref.replace(/\?projectId=.*&/, "?projectId=" + data.projectId + "&")).show();
        $j(".buildParameters .successMessage .btLink").hide();
      } else {
        $j(".buildParameters .successMessage .projectLink").hide();
        $j(".buildParameters .successMessage .btLink").show();
      }
      $j(".buildParameters .successMessage").show();
    });

    $j("#add-to-chart-docked").on("toggleDock", function() {
      var dock = $j("#add-to-chart-docked");
      if ($j(".valueTypeToggle").filter(":checked").length > 0 || popup.isVisible()) {
        dock.show();
      } else {
        dock.hide();
      }
    });
    var groupToAddNewChart = "buildtype-graphs";
    $j(".addToNewProject").click(function () {
      groupToAddNewChart = "project-graphs";
      popup.getPopupElement().find(".projectChooser .smallNote").hide();
      popup.getPopupElement().find(".projectChooser .projectChartProjectChooserNote").show();
    });

    $j(".addToNewConfig").click(function () {
      groupToAddNewChart = "buildtype-graphs";
      popup.getPopupElement().find(".projectChooser .smallNote").hide();
      popup.getPopupElement().find(".projectChooser .configurationChartProjectChooserNote").show();
    });

    const select = document.getElementById('projectSelect');
    const chooseProjectSelect = document.getElementById('chooseProjectSelect');
    if (select != null && chooseProjectSelect != null) {
      const selected = select.value;
      ReactUI.renderConnected(chooseProjectSelect, ReactUI.ProjectBuildTypeSelect, {
        expandAll: true,
        projectsSelectable: true,
        buildTypesSelectable: false,
        includedProjects: [...select.options].map(option => option.value),
        selected: selected ? {nodeType: 'project', id: selected} : null,
        onSelect(item) {
          select.value = item.id;
          popup.projectId = item.id;
        }
      });
    }

    $j(".addNewChart").click(function () {
      popup.clear();


      var arr = [];
      var sourceBuildTypeId = groupToAddNewChart == "buildtype-graphs" ? null : $j("#buildTypeIdHolder").attr("data-build-type-id");
      $j(".valueTypeToggle:checked").each(function (idx, cb) {
        var $cb = $j(cb);
        var key = $cb.attr("data-vt-key");
        var descr = $cb.attr("data-vt-description");
        arr.push({key: key, title: descr, sourceBuildTypeId: sourceBuildTypeId});
      });

      $j(".buildParameters .successMessage").hide();
      popup.showData(null, projectId, buildTypeId, groupToAddNewChart, arr, "Chart title", "Serie", groupToAddNewChart == "buildtype-graphs" ? "New Build Configuration Chart" : "New Project Chart");
      BS.AbstractModalDialog.positionAtFixed(popup.getPopupElement());

      BS.VisibilityHandlers.updateVisibility('newChartsXml');
    });

    $j(".cancelEditChart").click(function () {
      popup.hidePopup();
    });

    $j("#cancelAddToNew").click(function () {
      popup.hidePopup();
      BS.BuildParameters.clearCheckBoxes();
      BS.BuildParameters.toggleDock();
    });

    $j(".runnerFormTable.statisticsTable").on("click", ".valueTypeToggle", function (e) {
      var $cb = $j(e.currentTarget);
      if ($cb.is(":checked")) {
        var key = $cb.attr("data-vt-key");
        var descr = $cb.attr("data-vt-description");
        popup.addValueType(key, descr);
      } else {
        popup.removeValueType($cb.attr("data-vt-key"));
      }

      BS.BuildParameters.toggleDock();
    });

    $j(".runnerFormTable.statisticsTable").on("click", "a.showChartLink", function (e) {
      var $link = $j(e.currentTarget);
      var key = $link.attr("data-key");
      var valuetype = $link.attr("data-valuetype");
      var buildId = $link.attr("data-build-id");

      var description = $link.attr("data-description");

      BS.BuildParameters.sharedChartPopup.showPopupNearElement(this, {
        parameters: {valueType: valuetype, createUnknownVT: true, buildId: buildId, buildTypeId: $j("#buildTypeIdHolder").attr("data-build-type-id")},
        afterShowFunc: function () {
          if (description) {
            $j("#chartDialog #chartDialogTitle").html(description);
          }
          if ($j("#chartDialog .chartHolder").length == 0) {
            $j("#chartDialog .modalDialogBody").html("No chart generated");
            $j("#chartDialog.buildParameters_chartPopup").height("auto");
            $j("#chartDialog.buildParameters_chartPopup").width("auto");
          }
        }
      }
      );

    });

    var $links = $j("a.showChartLink");
    var idx = 0;

    var callback = function () {
      if ($links.length > 0) {
        for (var i = 0; i < 300 && idx < $links.length; ++i) {
          var $link = $j($links[idx++]);

          var key = $link.attr("data-key");

          var format = $link.attr("data-format");
          var value = $j(document.getElementById(key));
          if (typeof format !== 'undefined' && typeof BS.Chart.Formats[format] !== 'undefined') {
            value.text(BS.Chart.Formats[format].yaxis.tickFormatter(value.text()));
          } else {
            // extra parseFloat gets rid of unnecessary tailing zeros
            value.text(parseFloat(parseFloat(value.text()).toFixed(2)));
          }
        }
        setTimeout(callback, 100);
      }
    };

    callback();
  },

  toggleModifiedOnly: function() {
    var checkbox = $('onlyModifiedProps');
    if (checkbox.checked) {
      document.location = document.location + "&onlyModified=true";
    }
    else {
      document.location = document.location.toString().replace("&onlyModified=true", "");
    }
  }
};