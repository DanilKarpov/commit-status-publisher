BS.RestProjectsPopup = new BS.Popup("restProjectsPopup", {
  delay: 0,
  hideOnMouseOut: false,
  doScroll: false,
  shift: {
    x: -100,
    y: 15
  },
  htmlProvider: function (popup) {
    ReactUI.performCleanups(popup.element().firstChild);
    popup.element().textContent = "";
    var container = document.createElement("div");
    container.style.minHeight = "160px";
    var settings = popup.options.restPopupSettings;
    var parentProjectId = settings.parentProjectId;
    var currentId = settings.currentId;
    var currentNodeType = settings.currentNodeType;
    if (parentProjectId != null) {
      BS.RestProjectsPopup.addUrlFormats(settings);
    }
    ReactUI.renderProjectsPopup(container, {
      parentProjectId: parentProjectId,
      editMode:
        parentProjectId != null &&
        BS.Navigation.discoverMode().adminPart == true,
      activeItem:
        currentId != null
          ? { nodeType: currentNodeType, id: currentId, group: "search" }
          : null,
      pipelineUrlFormat: settings.pipelineUrlFormat,
      buildTypeUrlFormat: settings.buildTypeUrlFormat,
      templateUrlFormat: settings.templateUrlFormat,
      projectUrlFormat: settings.projectUrlFormat,
      onClose: () => BS.RestProjectsPopup.hidePopup(),
    });
    BS.Hider.addHideFunction(popup._name, function () {
      ReactUI.performCleanups(container);
      popup.element().textContent = "";
    });

    return container;
  },
  backgroundColor: "white",
  loadingText: "Loading...",
  forceReload: true
});

BS.RestProjectsPopup.addUrlFormats = function (settings) {
  if (
    BS.Navigation.items == undefined ||
    settings == undefined ||
    settings.currentId == undefined ||
    settings.currentNodeType == undefined
  ) {
    settings.pipelineUrlFormat = undefined;
    settings.buildTypeUrlFormat = undefined;
    settings.templateUrlFormat = undefined;
    settings.projectUrlFormat = undefined;
    return;
  }
  for (var i = 0; i < BS.Navigation.items.length; i++) {
    var item = BS.Navigation.items[i];
    if (
      settings.currentNodeType === 'bt' && item.buildTypeId == settings.currentId ||
      settings.currentNodeType === 'template' && item.templateId == settings.currentId ||
      settings.currentNodeType === 'project' && item.projectId == settings.currentId
    ) {
      if (item.siblingsTree != undefined) {
        settings.pipelineUrlFormat = item.siblingsTree.pipelineUrlFormat;
        settings.buildTypeUrlFormat = item.siblingsTree.buildTypeUrlFormat;
        settings.templateUrlFormat = item.siblingsTree.templateUrlFormat;
        settings.projectUrlFormat = item.siblingsTree.projectUrlFormat;
      }
      break;
    }
  }
};

BS.RestProjectsPopup.quickNavigationOptions = function () {
  return {
    restPopupSettings: {
      parentProjectId: undefined,
      currentId: undefined,
    },
    doScroll: false
  };
};

BS.RestProjectsPopup.breadcrumbsOptions = function (
  parentId,
  currentId,
  currentNodeType,
  shiftX,
  shiftY
) {
  return {
    restPopupSettings: {
      parentProjectId: parentId,
      currentId: currentId,
      currentNodeType: currentNodeType,
    },
    doScroll: false,
    shift: {
      x: shiftX != undefined ? shiftX : -10,
      y: shiftY != undefined ? shiftY : 15
    }
  };
};

BS.RestProjectsPopup.hideCurrentPopIfAny = function () {
  if (BS.RestProjectsPopup.isShown()) {
    BS.RestProjectsPopup.hidePopup(0, true);
  }
};

BS.RestProjectsPopup.showQuickNavigation = function () {
  BS.RestProjectsPopup.hideCurrentPopIfAny();

  _.extend(this.options, BS.RestProjectsPopup.quickNavigationOptions());
  BS.RestProjectsPopup._showWithDelay(
    $j(document).width() / 2 - 230,
    $j(document).scrollTop() + 100,
    function () {}
  );
};

BS.RestProjectsPopup.register = function () {
  jQuery(document).on("keydown keyup", function (e) {
    var code = e.originalEvent && e.originalEvent.code;
    if (
      (e.type === "keyup" &&
        (code === "KeyQ" ||
          code === "KeyP" ||
          e.key === "q" ||
          e.key === "p") &&
        !BS.Util.isModifierKey(e)) ||
      (e.type === "keydown" &&
        (code === "KeyK" || e.key === "k") &&
        (e.ctrlKey || e.metaKey))
    ) {
      var element = jQuery(e.target);
      if (
        element.is("input") ||
        element.is("textarea") ||
        element.is("select") ||
        element.is(".cm-content") // TW-86963
      ) {
        return;
      }
      BS.RestProjectsPopup.showQuickNavigation();
    }
  });
};

BS.RestProjectsPopup.installRestBreadcrumbs = function () {
  var container = $j("#restBreadcrumbs");

  var spans = container.find("div[data-parentId], li[data-parentId]");

  var rootProjectSpan = container.find('[data-projectid="_Root"]');

  if (rootProjectSpan.length > 0) {
    spans.push(rootProjectSpan[0]);
  }

  var build_span = container.find("div[data-buildid]");

  if (build_span.length > 0) {
    spans.push(build_span[0]);
  }

  spans.each(function (index) {
    var parentId = $j(this).attr("data-parentId");

    var currentId = $j(this).attr("data-projectId");
    var currentNodeType = "project";

    if (parentId == undefined || parentId == "") {
      parentId = currentId; //happens for _Root project
    }

    if (currentId == undefined) {
      currentId = $j(this).attr("data-buildTypeId");
      currentNodeType = "bt";
    }

    if (currentId == undefined) {
      currentId = $j(this).attr("data-templateId");
      currentNodeType = "template";
    }

    var icon = $j(this);
    var anchor = icon.find(".iWrapper");
    anchor.find("i").removeClass("icon_disabled");
    anchor.on("click", function () {
      if (BS.RestProjectsPopup && !BS.RestProjectsPopup.isShown()) {
        BS.RestProjectsPopup.showPopupNearElement(
          anchor,
          BS.RestProjectsPopup.breadcrumbsOptions(
            parentId,
            currentId,
            currentNodeType,
            -2,
            anchor.height()
          )
        );
      } else {
        BS.RestProjectsPopup.stopHidingPopup();
      }
    });
  });
};
