// Contains projects and build types visibility dialogs.

BS.AbstractVisibleDialog = OO.extend(BS.AbstractModalDialog, {
  alwaysReload: false,

  show: function(progressIcon) {
    this.changed = false;
    var that = this;
    if (progressIcon) progressIcon.css("visibility", "visible");
    BS.ajaxUpdater(this.getDialogContainer(), this.getRequestUrl(), {
      method: 'post',
      parameters: {show: "true"},
      evalScripts: true,
      onComplete: function() {
        that.showCentered();
        that.bindCtrlEnterHandler(that.save.bind(that));
        that.updateButtons();
        if (progressIcon) progressIcon.css("visibility", "hidden");
      }
    });
  },

  save: function() {
    BS.Util.show(this.getLoadingElemId());
    var form = this.getFormElement();
    Form.disable(form);

    this.getObjectsOrder().value = this.getVisibleProjectsOrder();
    var options = this.getVisibleObjects().options;
    for (var i = 0; i < options.length; i++) {
      options[i].selected = true;
    }
    var params = BS.Util.serializeForm(form);
    var that = this;
    BS.ajaxRequest(form.action, {
      parameters: params + "&save=true",
      onComplete: function() {
        Form.enable(form);
        BS.Util.hide(that.getLoadingElemId());
        that.close();
        if (that.alwaysReload || that.changed) {
          BS.reload(true);
        }
      }
    });

    return false;
  },

  getVisibleProjects: function() {
    var visible = "";
    var options = this.getVisibleObjects().options;
    for (var i = 0; i < options.length; i++) {
      if (visible.length > 0) {
        visible += ",";
      }
      visible += options[i].getAttribute("value");
    }
    return visible;
  },

  getVisibleProjectsOrder: function() {
    var order = "";
    var options = this.getVisibleObjects().options;
    for (var i = 0; i < options.length; i++) {
      if (options[i].className.indexOf("moved") >= 0) {
        if (order.length > 0) {
          order += ",";
        }
        order += options[i].getAttribute("value");
      }
    }
    return order;
  },

  moveToVisible: function() {
    this.doMoveTo(this.getHiddenObjects(), this.getVisibleObjects(), this.visibleObjectsAreSorted());
  },

  moveToHidden: function() {
    var filterField = this.getHiddenObjectsFilter();
    var from = this.getVisibleObjects();
    var to = this.getHiddenObjects();
    if (filterField.value == filterField.defaultValue || filterField.value == "") {
      this.doMoveTo(from, to, true);
    } else {
      filterField.value = "";
      BS.InPlaceFilter.applyFilter(this.getHiddenObjectsId(), filterField, function() {
        this.doMoveTo(from, to, true);
        filterField.value = filterField.defaultValue;
      });
    }
  },

  moveUp: function() {
    this.moveSelected(this.getVisibleObjects(), -1);
  },

  moveDown: function() {
    this.moveSelected(this.getVisibleObjects(), 1);
  },

  /**
   * @param {DOMNode} from - visible projects conatainer
   * @param {DOMNode} to - hidden projects container
   * @param {boolean} sort
   */
  doMoveTo: function(from, to, sort) {
    for (var k = 0; k < from.length; ++k) {
      var option = from.options[k];
      if (option.selected && option.value == "") {
        this.selectChildrenIfNeeded(from);
        option.selected = false;
      }
    }
    this.selectChildrenIfNeeded(from);

    this.changed = true;
    this.selectAll(to, false);
    var toRemove = [];
    var that = this;
    this.iterateOptions(from, function(option) {
      if (option.selected) {
        var copy = that.createCopy(option);
        if (sort) {
          that.insertToSorted(copy, to);
        } else {
          to.appendChild(copy);
        }
        toRemove.push(option);
      }
    });
    for (var j = 0; j < toRemove.length; j++) {
      from.removeChild(toRemove[j]);
    }
    this.onChange();
    this.updateButtons();
    to.activate();
    this.expandMultiSelects();
  },

  selectChildrenIfNeeded: function(from) {
    var k, j,
        length = from.options.length;

    var alsoToSelect = [];
    for (k = 0; k < length; ++k) {
      var option = from.options[k];
      if (option.selected) {
        var depth = parseInt(option.getAttribute("data-filter-data") || "0");
        var children = [];
        for (j = k + 1; j < length; ++j) {
          var childOption = from.options[j],
              childDepth = parseInt(childOption.getAttribute("data-filter-data") || "0");

          if (childDepth > depth) {
            if (childOption.selected) {
              children = [];
              break;
            }
            childOption.selected = true;
            children.push(childOption);
          } else {
            break;
          }
        }

        alsoToSelect = alsoToSelect.concat(children);
      }
    }
  },

  selectAll: function(select, selected) {
    this.iterateOptions(select, function(option) {
      option.selected = selected;
    });
  },

  iterateOptions: function(select, handler) {
    for (var k = 0; k < select.options.length; k++) {
      handler(select.options[k]);
    }
  },

  insertToSorted: function(option, select) {
    if (option.className.indexOf("inplaceFiltered") == -1) {
      option.addClassName("inplaceFiltered");
    }
    var options = select.options;
    for (var i = 0; i < options.length; i++) {
      if (option.innerHTML.toLowerCase() < options[i].innerHTML.toLowerCase()) {
        select.insertBefore(option, options[i]);
        return;
      }
    }
    select.appendChild(option);
  },

  createCopy: function(option) {
    var newOption = document.createElement("option");
    newOption.value = option.value;
    newOption.innerHTML = option.innerHTML;
    newOption.selected = option.selected;
    newOption.className = option.className;
    newOption.setAttribute("data-filter-data", option.getAttribute("data-filter-data"));
    return newOption;
  },

  moveSelected: function(select, dir) {
    var options = select.options;
    var i = dir == 1 ? options.length-1 : 0;
    var canMove = false;
    for (var k = 0; k < options.length; k++) {
      var option1 = options[i];
      if (option1.selected) {
        if (option1.value == "") continue;
        if (canMove) {
          var option2 = this._findOption(option1, options, i, dir);
          if (!option2) continue;

          var copy1 = this.createCopy(option1);
          var copy2 = this.createCopy(option2);
          select.replaceChild(copy2, option1);
          select.replaceChild(copy1, option2);
          this.changed = true;

          var depth = parseInt(option1.getAttribute("data-filter-data") || "-1");

          for (var up = i; up >= 0; --up) {
            var upDepth = parseInt(options[up].getAttribute("data-filter-data") || "-1");
            if (upDepth == depth && options[up].className.indexOf("moved") < 0) {
              options[up].addClassName("moved");
            }
            if (upDepth < depth) break;
          }
          for (var down = i; down < options.length; ++down) {
            var depthDown = parseInt(options[down].getAttribute("data-filter-data") || "-1");
            if (depth == depthDown && options[down].className.indexOf("moved") < 0)
              options[down].addClassName("moved");
            if (depthDown < depth) break;
          }

          if (copy1.className.indexOf("moved") < 0)
            copy1.addClassName("moved");
          if (copy2.className.indexOf("moved") < 0)
            copy2.addClassName("moved");
        }
      } else {
        canMove = true;
      }
      i -= dir;
    }
    this.onChange();
    this.updateButtons();
  },

  removeMovedOnSelectedChildren: function(from, /*Boolean*/ onlyOneLevel) {
    var changed = false;

    var k, j,
        length = from.options.length;

    for (k = 0; k < length; ++k) {
      var option = from.options[k];
      if (option.selected) {
        var depth = parseInt(option.getAttribute("data-filter-data") || "0");
        for (j = k + 1; j < length; ++j) {
          var childOption = from.options[j],
              childDepth = parseInt(childOption.getAttribute("data-filter-data") || "0");

          if (childDepth > depth) {
            if (!onlyOneLevel || childDepth == depth + 1) {
              childOption.removeClassName("moved");
              changed = true;
            }
          } else {
            break;
          }
        }
      }
    }

    return changed;
  },

  // Finds the next option that can be swapped with current.
  _findOption: function(option, options, i, dir) {
    var data1 = parseInt(option.getAttribute("data-filter-data") || "0");
    for (var j = 1; j < options.length; ++j) {
      var idx = i + j * dir;
      if (idx < 0 || idx >= options.length) return null;

      var candidate = options[idx],
          data2 = parseInt(candidate.getAttribute("data-filter-data") || "0");
      if (dir < 0 && data1 > data2) {
        return null;
      }
      if (dir > 0 && data1 > data2 && data1 > 0) {
        return null;
      }
      if (data1 == data2) {
        return candidate;
      }
      // else continue.
    }

    return null;
  },

  updateButtons: function() {
    this.getMoveToVisible().disabled = !this.hasSelection(this.getHiddenObjects());
    var visibleSelected = this.hasSelection(this.getVisibleObjects());
    this.getMoveToHidden().disabled = !visibleSelected;
    if (!this.visibleObjectsAreSorted()) {
      this.getMoveVisibleUp().disabled = !visibleSelected;
      this.getMoveVisibleDown().disabled = !visibleSelected;
    }
  },

  visibleObjectsAreSorted: function() {
    return false;
  },

  hasSelection: function(select) {
    var options = select.options;
    for (var i = 0; i < options.length; i++) {
      if (options[i].selected) {
        return true;
      }
    }
    return false;
  },

  getContainer: function() {
    return $(this.getPrefix() + 'visibleFormDialog');
  },

  getFormElement: function() {
    return $(this.getPrefix() + 'visibleForm');
  },

  getDialogContainer: function() {
    return $(this.getPrefix() + 'visibleDialogContainer');
  },

  getVisibleObjects: function() {
    return $(this.getPrefix() + 'visible');
  },

  getHiddenObjectsId: function() {
    return this.getPrefix() + 'hidden';
  },

  getHiddenObjects: function() {
    return $(this.getHiddenObjectsId());
  },

  getHiddenObjectsFilter: function() {
    return this.getHiddenObjectsId() + '_filter';
  },

  getObjectsOrder: function() {
    return $(this.getPrefix() + 'order');
  },

  getLoadingElemId: function() {
    return this.getPrefix() + 'savingVisible';
  },

  getMoveToVisible: function() {
    return $(this.getPrefix() + 'moveToVisible');
  },

  getMoveToHidden: function() {
    return $(this.getPrefix() + 'moveToHidden');
  },

  getMoveVisibleUp: function() {
    return $(this.getPrefix() + 'moveVisibleUp');
  },

  getMoveVisibleDown: function() {
    return $(this.getPrefix() + 'moveVisibleDown');
  },

  getPrefix: function() {
  },

  getRequestUrl: function() {
  },

  onChange: function() {
  },

  expandMultiSelects: function () {
    BS.expandMultiSelect($j(this.getHiddenObjects()));
    BS.expandMultiSelect($j(this.getVisibleObjects()));
  }
});

BS.VisibleProjectsDialog = OO.extend(BS.AbstractVisibleDialog, {
  getPrefix: function() {
    return "projects_";
  },

  getRequestUrl: function() {
    return window['base_uri'] + '/visibleProjects.html?init=1';
  },

  onChange: function() {
    var url = window['base_uri'] + "/visibleProjects.html";
    BS.ajaxRequest(url, {
      method: "POST",
      parameters: {
        refresh: true,
        projects: this.getVisibleProjects(),
        projects_order: this.getVisibleProjectsOrder()
      },
      onComplete: function(xhr) {
        var dialogHtml = xhr.responseText,
            newDialog = $j(dialogHtml);

        var hiddenValue = $j("#projects_hidden").val(),
            visibleValue = $j("#projects_visible").val(),
            filterValue = $j("#projects_hidden_filter").val();

        $j("#projects_visibleFormDialog .modalDialogBody").html(newDialog.find("#projects_visibleFormDialog .modalDialogBody").html());

        $j("#projects_hidden").val(hiddenValue);
        $j("#projects_visible").val(visibleValue);
        $j("#projects_hidden_filter").val(filterValue);

        BS.InPlaceFilter.prevKeyword = "";
        BS.InPlaceFilter.applyFilter('projects_hidden', $("projects_hidden_filter"));
      }
    });
  },

  resetAction: function() {
    if (this.removeMovedOnSelectedChildren(this.getVisibleObjects(), true)) {
      this.onChange();
    }
  }
});

BS.VisibleBuildTypesDialog = OO.extend(BS.AbstractVisibleDialog, {
  projectExternalId: '',

  showForProject: function(projectExternalId) {
    this.projectExternalId = projectExternalId;
    var progressIcon = $j("#vp_" + projectExternalId);
    //wait until the this.getDialogContainer() is ready - in case when the action invoked during the main page loading
    if (progressIcon) progressIcon.css("visibility", "visible");
    this.showForProjectWithEnsuredPlaceholder(progressIcon);
  },

  showForProjectWithEnsuredPlaceholder: function(progressIcon) {
    var self = this;
    var pl = this.getDialogContainer();
    if (pl) {
      this.show(progressIcon);
    } else {
      window.setTimeout(
          function(){self.showForProjectWithEnsuredPlaceholder(progressIcon)}, 
          100);
    }
  },
  
  getPrefix: function() {
    return "bt_";
  },

  getRequestUrl: function() {
    return window['base_uri'] + '/visibleBuildTypes.html?projectId=' + this.projectExternalId;
  },

  resetAction: function() {
    BS.confirm("Your order settings will be reset to defaults. Are you sure?", function () {
      BS.Util.show(this.getLoadingElemId());
      var form = this.getFormElement();
      Form.disable(form);

      BS.ajaxRequest(form.action, {
        parameters: 'reset=true',
        onComplete: function () {
          Form.enable(form);
          BS.Util.hide(this.getLoadingElemId());
          this.close();
          BS.reload(true);
        }.bind(this)
      });
    }.bind(this));
  },

  showSingleBuildType: function(projectExternalId, buildTypeId) {
    var url = window['base_uri'] + '/visibleBuildTypes.html';
    BS.ajaxRequest(url, {
      parameters: {
        projectId: projectExternalId,
        bt_visible: buildTypeId,
        showOne: "true"
      },
      onComplete: function() {
        // For now just reload.
        BS.reload(true);
      }
    });
    return false;
  },

  _findOption: function(option, options, i, dir) {
    return options[i + dir];
  },

  onChange: function() {
    $j(this.getFormElement()).find(".reorderedMessage").show();
    $j(this.getFormElement()).find(".reorderedMessage").hide();
  }
});

BS.hideBuildType = function(projectId, projectExternalId, buildTypeId) {
  var url = window['base_uri'] + '/visibleBuildTypes.html';
  BS.ajaxRequest(url, {
    parameters: {
      projectId: projectExternalId,
      bt_visible: buildTypeId,
      hideOne: "true"
    },
    onComplete: function() {
      jQuery(BS.Util.escapeId(buildTypeId + "-div"))
          .add(BS.Util.escapeId("btb" + buildTypeId))
          .fadeOut(1000);
      var hiddenBuildTypesCounter = jQuery(BS.Util.escapeId("ph_" + projectId))
          .find(".hideProject .pc__label")
          .contents()
          .filter(function() { return this.nodeType == 3; });
      var text = hiddenBuildTypesCounter.text();
      var newText;
      if (text.indexOf("no") >= 0) {
        newText = "1 hidden";
      } else {
        var num = parseInt(text.split(" ")[0]);
        newText = (num + 1) + " hidden";
      }

      // Highlight.
      setTimeout(function() {
        var parent = hiddenBuildTypesCounter.parent();
        parent.prepend(newText);
        hiddenBuildTypesCounter.remove();

        new Effect.Highlight(parent[0]);
      }, 1100);
    }
  });
  return false;
};
