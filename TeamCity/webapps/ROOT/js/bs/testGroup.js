BS.TestGroup = {
  _data: {},
  _projectData: {},

  /**
   * @param {String} groupId the unique <code>id</code> of the test group.
   * @param {Array.<Array.<String>>} data array of string pairs. The CAR in each
   *        pair is <code>testNameId</code>, while the CDR is the
   *        comma-separated list of <code>buildId</code>'s the test is failing
   *        in, e.&nbsp;g.: <code>[["-105815409583110515", "1088179,"],
   *        ["-7691647651072431595", "1088179,1088180"]]</code>. Build
   *        <code>id</code>'s are optional (used to determine the context
   *        project and/or build configuration if this information is otherwise
   *        unavailable).
   * @param {String} projectExternalId the external <code>id</code> of the
   *        parent project.
   */
  initialize: function(groupId, data, projectExternalId) {
    BS.TestGroup.initEventHandlers(groupId);

    if (!data) { return; }

    var result = this._data[groupId] = {};
    for (var i = 0; i < data.length; ++i) {
      var testEntry = data[i];
      if (!testEntry) { continue; }
      //noinspection UnnecessaryLocalVariableJS
      var testNameId = testEntry[0],
          builds = testEntry[1];
      result[testNameId] = builds;
    }

    this._projectData[groupId] = projectExternalId || "_Root";    // See TW-28928.
  },

  initEventHandlers: function(group_id) {
    var group = jQuery(BS.Util.escapeId(group_id));

    var hide_group_checkboxes_for_packages_when_needed = function(group) {
      // Hide group checkboxes for groups which have no tests under them
      // (because all tests are under group with failures in multiple configurations)
      group.find("table.testList").each(function() {
        var table = jQuery(this);
        if (table.find("input").length == 0) {
          var groupNameDiv = table.prev();
          groupNameDiv.find(".multi-select").css({visibility: "hidden"});
        }
      });
    };

    var hide_group_checkboxes_for_build_types_when_needed = function(group) {
      // Hide group checkboxes for buildType groups which have no visible package groups tests under them
      // (because all tests are under group with failures in multiple configurations)
      group.find("div.subgroups").each(function() {
        var grp = jQuery(this);
        var _hide = true;
        grp.find(".multi-select").each(function() {
          var checkbox = jQuery(this);
          if (_hide && checkbox.css("visibility") != "hidden") {
            _hide = false;
          }
        });
        if (_hide) {
          var groupNameDiv = grp.prev();
          groupNameDiv.find(".multi-select").css({visibility: "hidden"});
        }
      });
    };

    hide_group_checkboxes_for_packages_when_needed(group);
    hide_group_checkboxes_for_build_types_when_needed(group);

    group.on("click", ".multi-select", function(event) {
      var self = jQuery(this),
          container = self.parent().next(),
          checked = self.find('.custom-checkbox_input').prop('checked'),
          inputs = container.find(".custom-checkbox").not(self);

      inputs.find('.custom-checkbox_input').prop('checked', !!checked);
      inputs.change();
    });

    group.on("change", "input[type=checkbox]", function() {
      var bulkToolbar = jQuery(BS.Util.escapeId(group_id) + "-actions-docked");
      var checkbox = jQuery(this);

      _.delay(function() {
        var hasSelectedCheckboxes = jQuery(BS.Util.escapeId(group_id)).find(".checkbox.custom-checkbox_checked").length > 0;
        if (hasSelectedCheckboxes) {
          BS.blockRefreshPermanently('test');
          if (!bulkToolbar.is(':visible')) {
            bulkToolbar.css('bottom', '-100px').show().animate({bottom: 0});
          }
        } else {
          BS.unblockRefresh('test');
          bulkToolbar.css({bottom: '-100px'}).hide();
        }

        // Highlight selected tests
        var isChecked = checkbox.prop('checked');
        if (checkbox.parent().hasClass('multi-select')) {
          var group = checkbox.closest('.group-name').next('.testList');
          group.toggleClass('testListSelected', isChecked);
          if (!isChecked) {
            group.find('.testRowSelected').removeClass('testRowSelected');
          }
        } else {
          checkbox.closest('tr').toggleClass('testRowSelected', isChecked);
        }
      }, 10);
    });
  },

  findProjectIdByGroupId: function(groupId) {
    return groupId ? this._projectData[groupId] : null;
  },

  /**
   * @param {String} group CSS selector.
   * @param {Boolean} [fixMode] <code>true</code> if the "Fix" mode of the
   *                            dialog is requested.
   */
  investigateSelected: function(group, fixMode) {
    var /**Object<Number, String>*/ testsData = this._getSelectedData(group);
    if (testsData) {
      this.hideError();

      // TW-23629. Always include the project id into a request.
      var groupId = $j(group).attr("id");
      var projectExternalId = groupId ? this._projectData[groupId] : 0;
      if (projectExternalId) { testsData["projectId"] = projectExternalId; }

      var /**Object<Number, Boolean>*/ flakyTestIds = this._getFlakyTestIds(group);

      BS.BulkInvestigateMuteTestDialog.show(testsData, fixMode, flakyTestIds);
    } else {
      this.error(group, "Nothing is selected");
    }
    return false;
  },

  error: function(group, msg) {
    if (jQuery("#test-group-error").length == 0) {
      jQuery("body").append("<div class='successMessage' id='test-group-error'></div>");
    }
    jQuery("#test-group-error").html(msg).css({
      position: "absolute",
      display: "block"
    }).position({
      my: "top",
      at: "top",
      of: jQuery(group),
      offset: "0 5"
    });

    var that = this;
    setTimeout(function() {
      that.hideError();
    }, 10000);
  },

  hideError: function() {
    jQuery("#test-group-error").fadeOut();
  },

  /**
   * @param {String} group CSS selector.
   * @return {Object<Number, String>}
   * @private
   */
  _getSelectedData: function(group) {
    group = $j(group);
    var data = this._data[group.attr("id")];
    if (!data) {
      alert("Failed to get tests group data");
      return null;
    }

    var /**jQuery*/ inputs = group.find("div.group-div").filter(":visible").find(".custom-checkbox_checked").filter(":not(.multi-select)");
    if (inputs.length === 0) {
      return null;
    }

    var testsData = {};
    inputs.each(function() {
      var /**jQuery*/ self = $j(this);
      var /**Number*/ testNameId = self.find('.custom-checkbox_input').attr("data-testId");
      if (testNameId) {
        /*
         * TW-4264: For the Flaky Tests report, the "select-all" checkbox may
         * reside in the same container and have no "data-testId" attribute on
         * it.
         */
        testsData[testNameId] = data[testNameId];
      }
    });

    return testsData;
  },

  /**
   * <p>Returns a set of flaky test <code>name_id</code>'s within a test group.
   * </p>
   *
   * @param {String} group CSS selector.
   * @returns {Object<Number, Boolean>}
   * @private
   * @see #_getSelectedData
   */
  _getFlakyTestIds: function(group) {
    "use strict";
    var /**jQuery*/ inputs = $j(group).find("div.group-div").filter(":visible").find(".custom-checkbox_checked").filter(":not(.multi-select)");
    if (inputs.length === 0) {
      return {};
    }

    var /**Object<Number, Boolean>*/ flakyTestIds = {};
    inputs.each(function(/**Number*/ index, /**HTMLElement*/ element) {
      var /**jQuery*/ checkbox = $j(element).find('.custom-checkbox_input');
      var /**Number*/ testNameId = checkbox.attr("data-testId");
      /*
       * We can only convert a string to a boolean using string comparison, as
       * "false" will evaluate to true, too.
       */
      var /**Boolean*/ flaky = checkbox.attr("data-flaky") === "true";
      if (flaky) {
        flakyTestIds[testNameId] = true;
      }
    });

    return flakyTestIds;
  },

  _getProjectExternalId: function(group) {
    group = jQuery(group);
    return this._projectData[group.attr("id")];
  },

  highlight_multiple_bt_group: function(link, package_id) {
    var group = $(link).up("div.group-div");

    // Expand parent node: Problems in multiple build configurations
    group.down("div")._simple_block.changeState("", true, true);

    // Find groups and select one with the same package
    var groups = group.select('div.subgroups div.group-name');
    for(var i = 0; i < groups.length; i ++) {
      var div = groups[i];
      if (div.getAttribute('data-blockId') == package_id) {
        new Effect.ScrollTo(div);
        div.highlight({duration: 2});
        return;
      }
    }
  },

  regroup: function(groupId, userKey, selector) {
    BS.User.setProperty(userKey, selector.options[selector.selectedIndex].value);

    // Fixes TW-17228 as well as a memory leak.
    BS.CollapsableBlocks.unregisterBlocks('expand_' + groupId);

    var group = jQuery(BS.Util.escapeId(groupId)),
        state = this.saveState(group),
        that = this;
    $(groupId + "Refresh").refresh(groupId + "_loading", null, function() {
      group = jQuery(BS.Util.escapeId(groupId));      // the element is changed!
      that.restoreState(group, state);
    });

    return true;
  },

  saveState: function(group) {
    return {
      selected: _.keys(this._getSelectedData(group) || {})
    }
  },

  restoreState: function(group, state) {
    var selected = state.selected;
    for (var i = 0; i < selected.length; ++i) {
      group.find("input[data-testId=" + selected[i] + "]").prop("checked", true).parent().change();
    }
  },

  toggleSelectAll: function(groupId, checkbox) {
    var group = jQuery(groupId),
        inputs = group.find(".custom-checkbox");

    var el = jQuery(checkbox),
        checked = el.prop("checked");

    /*
     * TW-4264: do not select disabled checkboxes.
     */
    inputs.find('.custom-checkbox_input:enabled').not(el).prop("checked", !!checked);
    inputs.not(el.parent()).change();
  },

  expandDeepFunction: function(el, expand) {
    if (expand) {
      var subnodes = $j(this.getBlockContentElement()).children(".group-name");

      if (subnodes.length == 1 && subnodes[0]._simple_block) {
        subnodes[0]._simple_block.showBlock();
      }
    }
  }
};
