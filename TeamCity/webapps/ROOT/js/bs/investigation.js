/*
 * Copyright (c) 2006-2013, JetBrains, s.r.o. All Rights Reserved.
 */

// See TW-18828.
BS.ResponsibilityCommon = {
  checkUserPermissionsOnChange: function(warningContainer, investigatorDropdown, projectExternalId) {
    investigatorDropdown.change(function() {
      var option = this.options[this.selectedIndex];
      var userId = option ? option.value : 0;

      if (userId) {
        warningContainer.html("");
        var loading = $j(BS.loadingIcon).appendTo("body").css({
          zIndex: 100
        }).position({
          my: "left+4",
          at: "right",
          of: $j('#reactui-investigate').length ? $j('#reactui-investigate') : investigatorDropdown.parent()
        });

        BS.ajaxRequest(window['base_uri'] + "/investigationWarning.html", {
          method: "get",
          parameters: {
            projectId: projectExternalId,
            userId: userId
          },
          onComplete: function(transport) {
            warningContainer.html(transport.responseText);
            loading.remove();
          }
        })
      }
    });
  }
};

BS.ResponsibilityDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {

  formElement: function() {
    return $('investigationForm');
  },

  getContainer: function() {
    return $('investigationFormDialog');
  },

  getUrl: function() {
    return window['base_uri'] + "/buildTypeInvestigationDialog.html";
  },

  showDialog: function(buildTypeId, buildTypeFullName, presetFix, withoutReload, submitHandler) {
    this._withoutReload = withoutReload;
    this._submitHandler = submitHandler;
    var title = "Investigate \"" + buildTypeFullName.escapeHTML() + "\"" + (buildTypeFullName.length > 20 ? "" : " build configuration");
    $j("#investigationFormTitle").html(title);

    var bodyElement = $j("#investigationForm .modalDialogBody");
    bodyElement.html(BS.loadingIcon + "&nbsp;Loading...");
    this.showCentered();
    this.bindCtrlEnterHandler(this.submit.bind(this));
    function highlight(radio) {
      radio = $j(radio);
      if (!radio.prop("checked")) {
        radio.click().trigger("change");
        new Effect.Highlight(radio.next("label")[0]);  // highligh animation
      }
    }

    function highlightStickyOptionIfNeeded() {
      if ($j("#currentBuildType").data('successful')) {
        var dropdown = $j("#bt-remove-investigation");
        dropdown.prop("selectedIndex", 1).trigger("change");
        new Effect.Highlight(dropdown.parent().parent().find("label")[0]);  // highligh animation
      }
    }

    var that = this;
    BS.ajaxUpdater(bodyElement[0], this.getUrl(), {
      method: "get",
      evalScripts: true,
      parameters : {buildTypeId: buildTypeId},
      onComplete: function() {
        that.showCentered();
        that._handleDefaults();
        that.hideMoreLinkIfNeeded();

        // Preset "fixed" if needed.
        if (presetFix) {
          highlight("#bt-fix-investigate");
        } else if ($j("#bt-responsible option:selected").text() == "me" && $j("#bt-giveup-investigate").is(":checked")) {
          highlight("#bt-assign-investigate");
          highlightStickyOptionIfNeeded();
        }
      }
    });

    return new Promise(function (resolve, reject) {
      this._resolve = resolve;
      this._reject = reject;
    }.bind(this));
  },

  _handleDefaults: function() {
    var investigateCheckbox = $j("#do-bt-investigate"),
        investigateRadio = $j("#bt-investigate-section input[name=investigate]"),
        assign = $j("#bt-assign-investigate"),
        investigator = $j("#bt-responsible"),
        removeInvestigation = $j("#bt-remove-investigation");

    investigateRadio.change(function() {
      check(investigateCheckbox);
    });
    investigateCheckbox.change(function() {
      if (!$j(this).is(":checked")) {
        uncheck(investigateRadio);
      } else {
        check(assign);
      }
    });
    investigator.add(removeInvestigation).change(function() {
      check(assign);
      check(investigateCheckbox);
    });

    function check(input) {
      return input.prop("checked", true);
    }
    function uncheck(input) {
      return input.prop("checked", false);
    }
    function enable(input) {
      input.prop("disabled", false);
    }
    function disable(input) {
      input.prop("disabled", true);
    }

    function enableOrDisable() {
      if (investigateCheckbox.is(":checked")) {
        enable($j("#bt-submit"));
      } else {
        disable($j("#bt-submit"));
      }
    }

    // Handle defaults

    var investigateDefault = {};
    var investigateSection = $j("#bt-investigate-section");

    function saveDefault(map, section) {
      section.find("select, input[type=text]").each(function() {
        map[this.id] = $j(this).val();
      });
      section.find("input[type=radio], input[type=checkbox]").each(function() {
        map[this.id] = $j(this).is(":checked");
      });
    }
    function restoreDefault(map, section) {
      section.find("select, input[type=text]").each(function() {
        $j(this).val(map[this.id]).trigger("change");
      });
      section.find("input[type=radio], input[type=checkbox]").each(function() {
        if (map[this.id]) {
          check($j(this));
        } else {
          uncheck($j(this));
        }
      });

      if (BS.ResponsibilityDialog.resetReactUiInvestigator) {
        BS.ResponsibilityDialog.resetReactUiInvestigator();
      }
    }

    saveDefault(investigateDefault, investigateSection);

    // Show / hide [reset]

    var investigationReset = $j("#bt-reset-investigate");

    investigateRadio.add(investigator).add(removeInvestigation).change(function() {
      investigationReset.show()
                        .parent().addClass("modifiedParam");
    });
    investigationReset.click(function() {
      restoreDefault(investigateDefault, investigateSection);
      investigationReset.hide()
                        .parent().removeClass("modifiedParam");
      uncheck(investigateCheckbox);
      enableOrDisable();
      return false;
    });

    // Enable / disable

    investigateRadio.add(investigator).add(removeInvestigation)
                    .change(function() {
                      enableOrDisable();
                    });
  },

  moreConfigurations: function() {
    $j('#allBuildTypes').show();
    $j('#moreBuildTypes, #currentBuildType').hide();
    this._fixElementPlacement();
    return false;
  },

  hideMoreLinkIfNeeded: function() {
    var count = $j('#allBuildTypes input[type=checkbox]').length;
    if (count <= 1) {
      $j('#moreBuildTypes').hide();
    }
  },

  checkUserPermissionsOnChange: function(projectExternalId) {
    BS.ResponsibilityCommon.checkUserPermissionsOnChange($j("#bt-investigation-warning"), $j("#bt-responsible"), projectExternalId);
  },

  submit: function() {
    //TODO: validation
    var that = this;

    $j('#moreBuildTypes').hide();
    var icon = $j('#responsibilityProgressIcon').show();

    BS.FormSaver.save(this, this.getUrl(), OO.extend(BS.ErrorsAwareListener, {
      onCompleteSave: function() {
        icon.hide();

        if (typeof that._submitHandler === 'function') {
          that._submitHandler();
        }
        if (that._resolve != null) {
          that._resolve();
        }

        if (that._withoutReload !== true) {
          BS.reload(true); // TODO: smart reload?
        } else {
          that.close();
        }
      },

      onFailure: function() {
        icon.hide();
        alert("Problem accessing server");
      }
    }));

    return false;
  },

  setButtonsEnabling: function() {
    var hasCheckedBuildType = $j("#allBuildTypes input[type=checkbox]:checked").length > 0;
    $j("#bt-submit").prop("disabled", !hasCheckedBuildType);
  }
}));

BS.Responsibilities = OO.extend(BS.AbstractWebForm, {
  formElement: function() {
    return $('responsibilitiesFilter');
  },

  savingIndicator: function() {
    return $('respRefreshProgress');
  },

  submitFilter: function() {
    var that = this;
    this.setSaving(true);
    this.disable();
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.SimpleListener, {
      onCompleteSave: function() {
        if ($('responsibilitiesTable')) {
          $('responsibilitiesTable').refresh('respRefreshProgress', null, function() {
            that.setSaving(false);
            that.enable();
          });
        }
      }
    }));

    return false;
  }
});

BS.Mutes = OO.extend(BS.AbstractWebForm, {
  formElement: function() {
    return $('mutesFilter');
  },

  savingIndicator: function() {
    return $('mutesRefreshProgress');
  },

  submitFilter: function() {
    var that = this;
    this.setSaving(true);
    this.disable();
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.SimpleListener, {
      onCompleteSave: function() {
        if ($('mutesTable')) {
          $('mutesTable').refresh('mutesRefreshProgress', null, function() {
            that.setSaving(false);
            that.enable();
          });
        }
      }
    }));

    return false;
  }
});

BS.BulkInvestigateDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  _submitUrl: null,

  getContainer: function() {
    return $('muteTestsFormDialog');
  },

  formElement: function() {
    return $('muteTestsForm');
  },

  getInnerContainer: function() {
    return $('mute-dialog-container');
  },

  getLoadingElement: function() {
    return $('mute-dialog-inner-progress') || $('mute-dialog-progress');
  },

  enableSaveOnScopeChange: function() {
    $j("#commentOrScopeChanged").prop("checked", true);
    this._enableOrDisable();
  },

  prepareOnShow: function(assignAutomatically, contextBuildTypeId) {
      // Utils
      function check(input) {
        return input.prop("checked", true);
      }
      function uncheck(input) {
        return input.prop("checked", false);
      }
      function enable(input) {
        input.prop("disabled", false);
      }
      function disable(input) {
        input.prop("disabled", true);
      }

      // Basic investigation

      var that = this;
      var investigateCheckbox = $j("#do-investigate"),
          investigateRadio = $j("#muteTestsForm input[name=investigate]"),
          assign = $j("#assign-investigate"),
          investigator = $j("#investigator"),
          removeInvestigation = $j("#remove-investigation");

      investigateRadio.change(function() {
        check(investigateCheckbox);
      });
      investigateCheckbox.change(function() {
        if (!$j(this).is(":checked")) {
          uncheck(investigateRadio);
        } else {
          check(assign);
        }
      });
      investigator.add(removeInvestigation).change(function() {
        check(assign);
        check(investigateCheckbox);
      });

      // Basic mute

      var muteCheckbox = $j("#do-mute"),
          muteRadio = $j("#muteTestsForm input[name=mute]"),
          mute = $j("#mute-mute"),
          muteOptions = $j("#mute-scope, #unmute, #unmute-time, #mute-in-bt-list input");

      muteRadio.change(function() {
        check(muteCheckbox);
      });
      muteCheckbox.change(function() {
        if (!$j(this).is(":checked")) {
          uncheck(muteRadio);
        } else {
          check(mute);
        }
      });
      muteOptions.change(function() {
        check(mute);
        check(muteCheckbox);
      });

      // Other controls

      $j("#investigate-comment").on("keydown", function() {
        that.enableSaveOnScopeChange();
      });

      // Advanced mute

      $j("#unmute-time").placeholder({text: "Click to select the date"});
      $j("#unmute-time").focus(function() {
        $j("#unmute-time").placeholder("hide");
      });

      $j("#mute-scope").change(function() {
        if (this.selectedIndex == 1) {
          $j("#mute-in-bt-list").show();
          if (contextBuildTypeId) {
            var buildTypeCheckbox = $j("#mute-in-bt-" + contextBuildTypeId);
            if (buildTypeCheckbox.length && !buildTypeCheckbox.is(":checked")) {
              check(buildTypeCheckbox);
              $j("#mute-in-bt-list").animate({scrollTop: buildTypeCheckbox.position().top}, function() {
                new Effect.Highlight(buildTypeCheckbox.parent()[0]);
              });
            }
          }
        } else {
          $j("#mute-in-bt-list").hide();
        }
        $j("#unmute-time").placeholder("refresh");
      });

      $j("#unmute").change(function() {
        if (this.selectedIndex == 2) {
          $j("#unmute-row").show();
        } else {
          $j("#unmute-row").hide();
        }
        $j("#unmute-time").datepicker(this.selectedIndex == 2 ? 'show' : 'hide');
        $j("#unmute-time").placeholder("refresh");
      });

      $j("#unmute-time").datepicker({
        minDate: +1,
        dateFormat: "dd.mm.yy",
        defaultDate: +7
      }).css({marginTop: 4});

      // Handle defaults

      var investigateDefault = {},
          muteDefault = {};
      var investigateSection = $j("#investigate-section"),
          muteSection = $j("#mute-section");

      function saveDefault(map, section) {
        section.find("select, input[type=text]").each(function() {
          map[this.id] = $j(this).val();
        });
        section.find("input[type=radio], input[type=checkbox]").each(function() {
          map[this.id] = $j(this).is(":checked");
        });
      }
      function restoreDefault(map, section) {
        section.find("select, input[type=text]").each(function() {
          $j(this).val(map[this.id]).trigger("change");
        });
        section.find("input[type=radio], input[type=checkbox]").each(function() {
          if (map[this.id]) {
            check($j(this));
          } else {
            uncheck($j(this));
          }
        });
      }

      saveDefault(investigateDefault, investigateSection);
      saveDefault(muteDefault, muteSection);

      // Show / hide [reset]

      var investigationReset = $j("#reset-investigate"),
          muteReset = $j("#reset-mute");

      investigateRadio.add(investigator).add(removeInvestigation).change(function() {
        investigationReset.show()
                          .parent().addClass("modifiedParam");
      });
      investigationReset.click(function() {
        restoreDefault(investigateDefault, investigateSection);
        investigationReset.hide()
                          .parent().removeClass("modifiedParam");
        uncheck(investigateCheckbox);
        that._enableOrDisable();
        return false;
      });

      muteRadio.add(muteOptions).change(function() {
        muteReset.show()
                 .parent().addClass("modifiedParam");
      });
      muteReset.click(function() {
        restoreDefault(muteDefault, muteSection);
        muteReset.hide()
                 .parent().removeClass("modifiedParam");
        uncheck(muteCheckbox);
        that._enableOrDisable();
        return false;
      });

      if (assignAutomatically) {
        check(investigateCheckbox);
        check(assign);
        investigationReset.show()
                          .parent().addClass("modifiedParam");
      }

      // Enable / disable submit button
      investigateRadio.add(investigator).add(removeInvestigation)
                      .add(muteRadio).add(muteOptions).change(function() {
        that._enableOrDisable();
      });
      that._enableOrDisable();
  },

  _enableOrDisable: function() {
    if ($j('.investigate-no-permission').length > 0) {
      $("submit").disabled = true;
      return;
    }

    var investigateCheckbox = $j("#do-investigate"),
        muteCheckbox = $j("#do-mute"),
        commentOrScopeChanged = $j("#commentOrScopeChanged");

    var changed = investigateCheckbox.is(":checked") || muteCheckbox.is(":checked") || commentOrScopeChanged.is(":checked");
    $("submit").disabled = !changed;
  },

  /**
   * @param {String} title
   * @param {Object} params
   * @param {Boolean} [fixMode] <code>true</code> if the "Fix" mode of the
   *                            dialog is requested.
   * @param {Boolean} [reloadMode]
   * @param {Boolean} [withoutReload]
   * @param {Function} [submitHandler]
   * @return {Boolean}
   * @private
   */
  _doShow: function(title, params, fixMode, reloadMode, withoutReload, submitHandler) {
    this.setTitle(title);
    this._dialogClass(true, "wideDialog");

    this._withoutReload = withoutReload;
    this._submitHandler = submitHandler;

    this.showAtFixed($(this.getContainer()));
    this.bindCtrlEnterHandler(this.submit.bind(this));

    this._lastShowArgs = { title: title, params: params, fixMode: fixMode };

    if (!reloadMode) {
      // Avoid storing 'init' in _lastShowArgs
      params = Object.extend({}, params);
      params['init'] = 1;
    }
    this._loadContent(window['base_uri'] + this._submitUrl, params, fixMode);
    return false;
  },

  submit: function() {
    if (this.validate()) {
      return this._submit(window['base_uri'] + this._submitUrl + "?post=true");
    }
    return false;
  },

  validate: function() {
    var scope = $j("#mute-scope").val(),
        unmute = $j("#unmute").val(),
        comment = $j("#investigate-comment").val();

    $j("#mute-dialog-container div.error-msg").html("");  // clear previous errors

    if ($j("#mute-mute").is(":checked")) {
      if (scope == "C") {
        if ($j("#mute-in-bt-list input:checked").length == 0) {
          return this.validationError("#bt-list-error", "Please choose the build type");
        }
      }
      if (unmute == "T") {
        var time = $j("#unmute-time").val();
        if (time.length == 0) {
          return this.validationError("#unmute-time-error", "Please specify the unmute date");
        } else if (!/^\d{1,2}\.\d{1,2}\.\d{4}$/.match(time)) {
          return this.validationError("#unmute-time-error", "Please specify the correct unmute date");
        }
      }
    }

    if (comment.length > 4096) {
      return this.validationError("#comment-error", "The comment is too long (" + comment.length + "), only 4096 characters are possible.");
    }

    return true;
  },

  validationError: function(errorElement, message) {
    $j(errorElement).html(message);
    return false;
  },

  _reenable: function(title) {
    BS.Util.reenableForm(this.formElement());
    this.setTitle(title);

    // Do not clear the dialog in case of reloading (project scope changed).
    if (!$j($(this.getContainer())).is(":visible")) {
      this.getInnerContainer().innerHTML = "";
    }
  },

  _loadContent: function(url, params, fixMode) {
    var that = this;
    BS.Util.show(this.getLoadingElement());
    BS.ajaxRequest(url, {
      method: "POST",
      parameters: params,
      onComplete: function(transport) {
        BS.Util.hide(that.getLoadingElement());
        $j(that.getInnerContainer()).html(transport.responseText);   // TW-22300
        that.showCentered();

        if (that._savedState) {
          that._restoreForm();
          return;
        }

        if (fixMode) {
          setTimeout(function() {
            that._updateToFixedState();
          }, 500);
        }
      }
    });
  },

  _updateToFixedState: function() {
    var selectFixOption = function(el_id) {
      var checked = $j(el_id).prop("checked");
      if (!checked) {
        $j(el_id).click();
        $j(el_id).trigger("change");
        var label = $j(el_id).next("label")[0];
        label && new Effect.Highlight(label);  // highligh animation (same as "mute in build type")
      }
    };

    selectFixOption('#fix-investigate');
    selectFixOption('#unmute-mute');

    $j('#investigate-comment').focus();

    $("submit").enable();
  },

  _submit: function(url) {
    var that = this,
        loadingIcon = $j("#investigate-saving");

    loadingIcon.show();
    BS.FormSaver.save(this, url, OO.extend(BS.ErrorsAwareListener, {
      onSuccessfulSave: function() {
        loadingIcon.hide();
        that.close();
        if (!that._withoutReload) {
          that.smartReload();
        }
        if (typeof that._submitHandler === 'function') {
          that._submitHandler()
        }
      },
      onGeneralError: function(elem) {
        alert(elem.firstChild.nodeValue);
      }
    }));
    return false;
  },

  _dialogClass: function(add, className) {
    var dialog = $j(this.getContainer());
    if (add) {
      dialog.addClass(className);
    } else {
      dialog.removeClass(className);
    }
  },

  setTitle: function(title) {
    $j('#muteTestsFormTitle').html(title);
  },

  /**
   * @return {Object}
   */
  getQuery: function() {
    var query = window.location.search.substring(1),
        vars = query.split("&"),
        map = {};
    for (var i = 0; i < vars.length; i++) {
      var pair = vars[i].split("=");
      map[pair[0]] = pair[1];
    }
    return map;
  },

  // @return true if build results popup was reopened
  reopenBuildResultsPopup: function() {
    var currentPopup = $j("div.summaryContainer").filter(":visible").parent();
    if (!currentPopup.length) {
      return false;
    }

    var id = currentPopup.attr("id");
    var position = currentPopup.position();
    if (!id || !position) {
      return false;
    }

    var popup = BS.BuildResultsPopupTracker(id.substr("popupRes".length)).getPopup();
    if (!popup) {
      return false;
    }

    // Close the popup and open it again (exactly at position it was).
    BS.Hider.hideAll(); // For TW-29818
    popup._showWithDelay(position.left, position.top);
    return true;
  },

  /**
   * @return {undefined}
   */
  // See TW-13653
  smartReload: function() {
    var url = window.location.href,
        uri = window['base_uri'];
    if (!url.startsWith(uri)) {
      // Should never happen. No idea what to do in this case.
      return this.fallbackReload();
    }

    url = url.substr(uri.length);
    var /**Object*/ query = this.getQuery(),
        /**String*/ tab = query["tab"];

    if (url.startsWith("/viewChain.html") || tab == 'buildTypeChains' || tab == 'projectBuildChains' || tab == 'dependencies' ) {
      // Chains list.
      return this.reloadSubtree("allChains");
    }

    if (url.startsWith("/viewLog.html")) {
      // Build results / build tests page.
      return this.reloadSubtree("buildResults");
    }

    if (url == "/" || url.startsWith("/overview.html") ||
        (url.startsWith("/project.html") && (!tab || tab == "projectOverview")) ||
        (url.startsWith("/viewType.html"))) {

      // Dashboard or project / build type overview page, build popup.
      if (this.reopenBuildResultsPopup()) {
        return;
      }

      return this.fallbackReload();
    }

    if (url.startsWith("/project.html")) {
      /*
       * TW-4264: refresh a particular container and attempt to preserve sort order.
       */
      if (tab === "flakyTests") {
        //noinspection JSUnresolvedVariable
        if (BS.FlakyTestDetector) {
          //noinspection JSUnresolvedVariable,JSUnresolvedFunction
          BS.FlakyTestDetector.refreshSortablesNoArgs();
          return;
        } else {
          BS.Log.warn("BS.FlakyTestDetector unavailable; sort order may not be preserved.");
          return this.reloadSubtree("flakyTests");
        }
      }

      // Some project page, except for overview and flaky tests.
      return this.reloadSubtree("projectContainer");
    }

    if (url.startsWith("/changes.html")) {
      // My changes page. Right now one can only investigate/mute just one test at a time.
      if (this._lastTestId) {
        var refreshable = $("testNameId" + this._lastTestId).up(".refreshable");
        return this.reloadSubtree(refreshable);
      }

      return this.fallbackReload();
    }

    // Some other page...
    return this.fallbackReload();
  },

  reloadSubtree: function(id) {
    // Show the large 'Loading...' block as we have nothing to attach the spinner to.
    var elem = $(id),
        loading = $('loadingWarning');

    if (loading) {
      loading.style.display = 'block';
    }

    elem.refresh(null, null, function() {
      if (loading) {
        loading.style.display = 'none';
      }
    });

    // Close opened popups.
    BS.Hider.hideAll();
  },

  fallbackReload: function() {
    BS.reload(true);
  },

  checkUserPermissionsOnChange: function(projectExternalId) {
    BS.ResponsibilityCommon.checkUserPermissionsOnChange($j("#test-investigation-warning"), $j("#investigator"), projectExternalId);
  }
}));

BS.BulkInvestigateMuteTestDialog = OO.extend(BS.BulkInvestigateDialog, {
  _submitUrl: "/tests/bulkInvestigate.html",

  /**
   * <p>Shows the dialog for a group of tests.</p>
   *
   * @param {Object} testsData
   * @param {String} [testsData.projectId] the <code>external_id</code> of a
   *                                       project.
   * @param {Boolean} [fixMode] <code>true</code> if the "Fix" mode of the
   *                            dialog is requested.
   * @param {Object.<Number, Boolean>} [flakyTestIds] a set of
   *                                   <code>name_id</code>'s of flaky tests.
   * @param {Boolean} [withoutReload]
   * @param {Function} [submitHandler]
   */
  show: function(testsData, fixMode, flakyTestIds, withoutReload, submitHandler) {
    var /**Number*/ size = _.size(testsData);
    if (testsData["projectId"]) --size;
    var /**String*/ title = (fixMode ? "Fix " : "Investigate / Mute ") + size + " Test" + (size == 1 ? "" : "s");

    if (flakyTestIds) {
      var /**Number*/ flakyTestCount = 0;
      for (var /**String*/ testNameId in testsData) {
        if (testsData.hasOwnProperty(testNameId) && flakyTestIds[testNameId]) {
          flakyTestCount++;
        }
      }
      if (flakyTestCount !== 0) {
        testsData["remove-investigation"] = 1;
        testsData["unmute"] = "M";
        testsData["comment"] = flakyTestCount === size
            ? (size == 1 ? "This test is flaky!" : "All these tests are flaky!")
            : "Some of these tests are flaky!";
      }
    }

    return this._doShow(title, testsData, fixMode, false, withoutReload, submitHandler);
  },

  /**
   * <p>Shows the dialog for an individual test.</p>
   *
   * @param {Number} testId test <code>name_id</code>.
   * @param {Number} buildId build id, or an empty string.
   * @param {String} testGroupId
   * @param {String} defaultProjectId the <code>external_id</code> of a project.
   * @param {Boolean} [fixMode] <code>true</code> if the "Fix" mode of the
   *                            dialog is requested.
   * @param {Object} [optionalArgs] optional arguments.
   * @param {Number} [optionalArgs.responsibilityRemovalMethod] the default
   *                 resolution mode for new investigations created for the test
   *                 identified by <code>testId</code>, either
   *                 &quot;Automatically when fixed&quot; (0) or
   *                 &quot;Manually&quot; (1). The default is -1 which means
   *                 &quot;no preference&quot;.
   * @param {String} [optionalArgs.unmuteOptionType] the requested unmute method
   *                 for new investigations, one of &quot;M&quot;,
   *                 &quot;F&quot;, &quot;T&quot;, or an empty string
   *                 (which means &quot;no preference&quot;).
   * @param {String} [optionalArgs.comment] the requested initial comment for new
   *                           investigations.
   * @param {String} [optionalArgs.investigatorId] the requested initial investigator
   *                 for new investigations.
   * @return {Boolean}
   */
  showForTest: function(testId, buildId, testGroupId, defaultProjectId, fixMode,
                        optionalArgs) {
    var /**String*/ title = fixMode ? "Fix 1 Test" : "Investigate / Mute 1 Test";
    var /**Object*/ params = {};
    params[testId] = buildId;
    params["projectId"] = defaultProjectId || BS.TestGroup.findProjectIdByGroupId(testGroupId);
    if (optionalArgs) {
      if (typeof optionalArgs.responsibilityRemovalMethod === "number") {
        params["remove-investigation"] = optionalArgs.responsibilityRemovalMethod;
      } else if (typeof optionalArgs.responsibilityRemovalMethod === "string") {
        params["remove-investigation"] = parseInt(optionalArgs.responsibilityRemovalMethod);
      }
      if (optionalArgs.unmuteOptionType) {
        params["unmute"] = optionalArgs.unmuteOptionType;
      }
      if (optionalArgs.investigatorId) {
        params["investigatorId"] = optionalArgs.investigatorId;
      }
      if (optionalArgs.comment) {
        params["comment"] = optionalArgs.comment;
      }
    }
    this._lastTestId = testId;
    return this._doShow(title, params, fixMode);
  },

  /**
   * @param problemId
   * @param buildId
   * @param {Boolean} [fixMode] <code>true</code> if the "Fix" mode of the
   *                            dialog is requested.
   * @param {Boolean} [withoutReload]
   * @param {Function} [submitHandler]
   * @return {Boolean}
   */
  showForBuildProblem: function(problemId, promoId, fixMode, withoutReload, submitHandler) {
    var /**String*/ title = fixMode ? "Fix 1 Build Problem" : "Investigate / Mute 1 Build Problem";
    var /**Object*/ params = {};
    params['BuiPro' + problemId] = promoId;
    return this._doShow(title, params, fixMode, false, withoutReload, submitHandler);
  },

  /**
   * <p>Shows the dialog for a group of problems.</p>
   *
   * @param {Object} testsData
   * @param {String} [testsData.projectId] the <code>external_id</code> of a
   *                                       project.
   * @param {Boolean} [fixMode] <code>true</code> if the "Fix" mode of the
   *                            dialog is requested.
   * @param {Boolean} [withoutReload]
   * @param {Function} [submitHandler]
   */
  showForBuildProblems: function(problemsData, fixMode, withoutReload, submitHandler) {
    var /**Number*/ size = _.size(problemsData);
    if (problemsData["projectId"]) --size;
    var /**String*/ title = (fixMode ? "Fix " : "Investigate / Mute ") + size + " Problem" + (size == 1 ? "" : "s");
    return this._doShow(title, problemsData, fixMode, false, withoutReload, submitHandler);
  },

  reloadDialog: function() {
    var args = this._lastShowArgs;
    args.params["projectId"] = $j("#scopeProjectId").val();
    args.params["origProjectId"] = $j("#scopeProjectId")[0].form.origProjectId.value;

    this._saveForm();
    BS.Util.disableFormTemp(this.formElement());
    return this._doShow(args.title, args.params, args.fixMode, true, this._withoutReload);
  },

  _saveForm: function() {
    var state = {};
    var container = $j("#mute-dialog-container");
    $j("select, textarea", container).not("#scopeProjectId").add("#unmute-time").each(function() {
      state[this.id] = $j(this).val();
    });
    $j("input[type=radio]", container).each(function() {
      state[this.id] = $j(this).is(":checked");
    });
    this._savedState = state;
  },

  _restoreForm: function() {
    var state = this._savedState;
    var container = $j("#mute-dialog-container");
    $j("select, textarea", container).not("#scopeProjectId").add("#unmute-time").each(function() {
      var self = $j(this),
          value = self.val(),
          newValue = state[this.id];
      if (value != newValue) {
        self.val(newValue).trigger("change");
      }
    });
    $j("input[type=radio]", container).each(function() {
      var self = $j(this),
          value = self.is(":checked"),
          newValue = state[this.id];
      if (value != newValue) {
        self.prop("checked", newValue).trigger("change");
      }
    });
    this._savedState = null;
  }
});
