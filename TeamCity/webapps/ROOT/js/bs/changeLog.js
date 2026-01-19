/*
 * Taken from buildType.js to be reused in projectChangeLog.jsp
 */
(function ($) {
  BS.ChangeLog = OO.extend(BS.AbstractWebForm, {
    changesTableSelector: null,
    refreshCallback: null,

    formElement: function () {
      return $('#changeLogFilter').get(0);
    },

    changeLogTable: function() {
      return $('#changeLogTable');
    },

    sanitizeFilter: function () {
      var fromBuild = this.formElement().from;
      var toBuild = this.formElement().to;

      if (fromBuild) {
        fromBuild.value = fromBuild.value.replace(/^#/, '');
      }

      if (toBuild) {
        toBuild.value = toBuild.value.replace(/^#/, '');
      }
    },

    submitFilter: function (trigger) {
      var self = this;

      // Hide visible sections without a full refresh
      if (trigger && trigger.type == 'checkbox' && !trigger.checked && trigger.name != 'showChangesFromDependencies') {
        this.hideSections(trigger.name);
        this._saveFilterSettingsInSession();
        if (trigger.name === 'showFiles') {
          $j('#changesTable .changedFiles .toggle').show();
        }
        BS.ChangeLogGraph.redrawGraph();
        return false;
      }

      this.handleResetLink();
      this.setSaving(true);
      this.sanitizeFilter();
      this.disable();
      BS.ChangeLogGraph.setGraphData(null);
      BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.SimpleListener, {
        onCompleteSave: function () {
          self.changeLogTable().get(0).refresh(self.savingIndicator(), null, function () {
            self.enableFilter();
            self.setSaving(false);
            if (trigger && trigger.name === 'showFiles' && trigger.checked) {
              $j('#changesTable .changedFiles .toggle').hide();
            }
            BS.ChangeLogGraph.redrawGraph();

            if (self.refreshCallback) {
              self.refreshCallback();
            }
          });
        }
      }));

      return false;
    },

    enableFilter: function () {
      this.enable(function (element) {
        //enable 'showGraph' checkbox only if path is empty
        return (element.id !== 'showGraph') || $('#path').val() === '';
      });
    },

    resetFilter: function () {
      // For some mysterious reason it doesn't work properly in Chrome without a timeout...
      setTimeout(function () {
        $("#comment, #path, #revision").val("");
        $("#from, #to").val("<build #>");
        $("#userDropDown").val("").trigger("change");
      }, 50);
    },

    handleResetLink: function () {
      var reset = $(".resetLink a");

      if ($("#userDropDown").val()) {
        reset.show();
        return;
      }

      if (!$("#advanced-fields").is(":visible")) {
        reset.hide();
        return;
      }

      var placeholder = "<build #>";
      if ($("#comment").val() ||
          $("#path").val() ||
          $("#revision").val() ||
          ($("#from").val() && $("#from").val() != placeholder) ||
          ($("#to").val() && $("#to").val() != placeholder)) {
        reset.show();
      } else {
        reset.hide();
      }
    },

    toggleAdvanced: function (toggle) {
      $('#advanced-fields').removeClass('hidden');
      $(toggle).addClass('hidden');
      return false;
    },

    initChangeLogTable: function (changesTableSelector) {
      this.changesTableSelector = changesTableSelector;
      var changesTable = $(changesTableSelector),
          artifactDescriptionCaptions = changesTable.find('.artifactDescriptionCaption');

      artifactDescriptionCaptions.click(function () {
        var caption = $(this);

        caption.toggleClass('expanded').toggleClass('collapsed');
        caption.parent('tr').nextUntil(":not(.artifacts-row)").toggleClass('hidden');

        BS.ChangeLogGraph.redrawGraph();
      });

      artifactDescriptionCaptions.mousedown(function () {
        return false;
      });
    },

    hideSections: function (sectionName) {
      var changesTable = $(this.changesTableSelector);

      if (sectionName == 'showBuilds') {
        changesTable.find('.modification-row-header').remove();
      }

      if (sectionName == 'showFiles') {
        changesTable.find('.files-row').remove();
      }
    },

    toggleGraph: function () {
      var graph = $('#graph'),
          graphToggle = $('#showGraph');

      BS.ChangeLogGraph.graphContainer = graph;

      if (graphToggle.prop('checked')) {
        if (BS.ChangeLogGraph.isEmptyGraph()) {
          this.submitFilter();
        } else {
          this._saveFilterSettingsInSession();
          graph.show();
          graph.parent().show();
        }
      } else {
        this._saveFilterSettingsInSession();
        graph.hide();
        graph.parent().hide();
      }
    },

    _saveFilterSettingsInSession: function () {
      //post request just saves filter settings and doesn't do any calculations, it should be fast
      BS.FormSaver.save(this, this.formElement().action, BS.SimpleListener);
    },

    showNextBigPage: function (url) {
      var params = {
        __fragmentId: "changeLogTableInner",
        addToSamePage: "true"
      };

      BS.Util.show("progress");
      var self = this;

      BS.ajaxRequest(url, {
        method: "get",
        parameters: params,
        onComplete: function (transport) {
          BS.Util.hide("progress");

          var response = transport.responseText;
          self.insertNewRows(response);
          self.updateNumbersOnPage(response);
        }
      });
    },

    insertNewRows: function (response) {
      if (response.indexOf("<table") >= 0) {
        var changesTable = $(this.changesTableSelector);
        if (changesTable.length == 0) {
          // Insert the whole table.
          var table = $(response).find(this.changesTableSelector);
          this.changeLogTable().find(".resultsTitle:first").after(table);
        } else {
          // Insert the rows only.
          $(response).find(this.changesTableSelector).find('tbody tr').each(function (index, tr) {
            if ($(tr).hasClass("modification-row-header") || $(tr).hasClass("modification-row")) {
              changesTable.append(tr);
            }
          });
        }
      }
    },

    updateNumbersOnPage: function (response) {
      var fromIdx, toIdx, num;

      var changesNumFound = $("#changes-num-found");

      // Changes found.
      fromIdx = response.indexOf('<strong id="changes-num-found">') + 31;
      toIdx = response.indexOf('</strong>', fromIdx);
      num = parseInt(response.substring(fromIdx, toIdx)) + parseInt(changesNumFound.text());
      changesNumFound.text(num);

      fromIdx = response.indexOf('<strong class="changes-total">');
      if (fromIdx == -1) {
        BS.Util.hide("search-more");
        return;
      }

      fromIdx += 30;
      toIdx = response.indexOf('</strong>', fromIdx);
      num = response.substring(fromIdx, toIdx);
      $(".changes-total").text(num);
    }
  });
})(jQuery);

