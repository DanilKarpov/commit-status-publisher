BS.HealthStatusReport = OO.extend(BS.AbstractWebForm, {

  _existingCategories: [],
  _selectedCategoryId: '',

  _categoryExists: function(categoryId) {
    return $j.inArray(categoryId, this._existingCategories) >= 0;
  },

  formElement: function() {
    return $('filterForm');
  },

  savingIndicator: function() {
    return $('progressIndicator');
  },

  progressStepContainer: function() {
    return $('progressStep');
  },

  showProgress: function() {
    this.setSaving(true);
    var progressContainer = this.progressStepContainer();
    if (!this.progress) {
      this.progress = new BS.DelayedShow(progressContainer);
    }
    this.progress.start();
  },

  hideProgress: function() {
    this.setSaving(false);
    if (this.progress) {
      this.progress.stop();
    }
  },

  updateProgress: function(currentStep, totalSteps, stepDescription) {
    var progressStep = this.progressStepContainer();
    progressStep.innerHTML = "Step " + currentStep + " of " + totalSteps;
    this.progressStepContainer().title = stepDescription;
    this.savingIndicator().title = stepDescription;
  },

  submitScopeForm: function() {
    this.saveParamsInHash();
    this.generateReport();
    return false;
  },

  generateReport: function() {
    this.collectItems(true);
  },

  updateReport: function() {
    this.collectItems(false);
  },

  collectItems: function(cleanItems) {
    var that = this;
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.SimpleListener, {
      onBeginSave: function() {
        if(cleanItems){
          that.clearItems();
        }
        that.disable();
        that.showProgress();
      },
      onCompleteSave: function() {
        that.startWatchingProgress();
      }
    }));
  },

  clearItems: function() {
    var reportSummary = $j('#reportSummary');
    if(reportSummary) reportSummary.empty();
    var reportCategories = $j('#reportCategories');
    if(reportCategories) reportCategories.empty();
  },

  setHealthItemVisibility: function(type, categoryId, itemId, visible, applyGlobally) {
    var that = this;
    return BS.AdminActions.setHealthItemVisibility(type, categoryId, itemId, visible, applyGlobally, function() {
      that.refreshContent();
    });
  },

  startWatchingProgress: function() {
    var that = this;
    var updater = new BS.PeriodicalUpdater(null, window['base_uri'] + "/ajax.html?getHealthAnalysisProgress=1", {
      frequency: 1,
      evalScripts: true,
      onSuccess: function(transport){
        var root = BS.Util.documentRoot(transport);
        if (!root) return;
        var isFinished = root.getElementsByTagName('isFinished').length !== 0;
        if(isFinished) {
          updater.stop();
          that.enable();
          that.hideProgress();
          that.refreshContent();
        } else {
          if (root.getElementsByTagName('progress').length === 0) {
            return;
          }
          var progress = root.getElementsByTagName('progress')[0];
          var currentReport = progress.getAttribute('currentReport');
          var totalCount = progress.getAttribute('totalReportsCount');
          var currentIndex = progress.getAttribute('currentReportIndex');
          that.updateProgress(currentIndex, totalCount, currentReport);
        }
      }
    });
    return false;
  },

  refreshContent: function(){
    var reportSummary = $('reportSummary');
    if(reportSummary) reportSummary.refresh();
    var reportCategories = $('reportCategories');
    if(reportCategories) reportCategories.refresh();
    return false;
  },

  newCategoriesLoaded: function(categories){
    this._existingCategories = categories;
    this.selectCategory(this._selectedCategoryId);
  },

  selectCategory: function(categoryId, event) {
    if (event && event.target) { //ignore clicks on help icons.
      var target = $j(event.target);
      if (target.is("img") || (target.is("a") && target.attr("href"))) {
        return true;
      }
    }

    if (!this._categoryExists(categoryId)) {
      categoryId = this._existingCategories[0] || '';
    }

    if (this._selectedCategoryId != categoryId) {
      this._selectedCategoryId = categoryId;
      this.saveParamsInHash();
    }

    $j('.category-list .active').each(function() {
      $j(this).removeClass("active");
    });
    $j('#' + categoryId).addClass("active");

    var url = window['base_uri'] + "/admin/healthStatusItems.html?categoryId=" + categoryId;
    $j('#update_progress').html('<div class="resultsTitle"><i class="icon-refresh icon-spin ring-loader-inline"></i> Retrieving content of selected category...</div>');
    $j('#selectedCategoryItems').empty();
    BS.ajaxUpdater($('selectedCategoryItems'), url, {
      method: 'get',
      evalScripts: true,
      onComplete: function() {
        $j('#update_progress').empty();
      }
    });
    return false;
  },

  readParamsFromHash: function () {
    var parsedHash = BS.Util.paramsFromHash('&');
    var scopeFromHash = parsedHash['scopeProjectId'];
    var categoryFromHash = parsedHash['selectedCategoryId'];
    var severityFromHash = parsedHash['minSeverity'];

    if (scopeFromHash === $j('#scopeProjectId option:selected').val() &&
        severityFromHash === $j('#minSeverity option:selected').val() &&
        categoryFromHash === this._selectedCategoryId) {
      return; //hash contains the same params as we have
    }

    var regenerateReport = false;

    if (scopeFromHash) {
      var scopeProjectIdSelector = $('scopeProjectId');
      for (var i = 0; i < scopeProjectIdSelector.options.length; i++) {
        if (scopeProjectIdSelector.options[i].value == scopeFromHash && !scopeProjectIdSelector.options[i].selected) {
          scopeProjectIdSelector.selectedIndex = i;
          BS.jQueryDropdown(scopeProjectIdSelector).ufd("changeOptions");
          regenerateReport = true;
          break;
        }
      }
    }

    if (severityFromHash) {
      var severitySelector = $('minSeverity');
      for (var j = 0; j < severitySelector.options.length; j++) {
        if (severitySelector.options[j].value == severityFromHash && !severitySelector.options[j].selected) {
          severitySelector.selectedIndex = j;
          BS.jQueryDropdown(severitySelector).ufd("changeOptions");
          regenerateReport = true;
          break;
        }
      }
    }

    if (categoryFromHash) {
      if (!this._categoryExists(categoryFromHash)) {
        regenerateReport = true;
      }
      this._selectedCategoryId = categoryFromHash;
    } else {
      this._selectedCategoryId = this._existingCategories[0] || '';
    }

    this.saveParamsInHash(); //fill missing params in hash

    if (regenerateReport) {
      this.generateReport();
    } else {
      this.updateReport();
      this.selectCategory(this._selectedCategoryId);
    }
  },

  /**
   * We have to ensure that selected scope, severity and category are saved in the URL hash.
   * It allows to support links to the specific health report.
   */
  saveParamsInHash: function() {
    BS.Util.setParamsInHash(['minSeverity', $j('#minSeverity option:selected').val(),
                              'scopeProjectId', $j('#scopeProjectId option:selected').val(),
                              'selectedCategoryId', this._selectedCategoryId],
                            '&', true);
  }
});
