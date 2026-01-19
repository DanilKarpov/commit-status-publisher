/*
 * Copyright (C) 2005 SilverStripe Limited
 * http://www.silverstripe.com/blog
*/

/*
 * Initialise all trees identified by <ul class="tree">
 */
(function() {
  function autoInit_trees() {
    $j('ul.tree').each(function() {
      initTree(this);
      this.className = this.className.replace(/ ?unformatted ?/, ' ');
    });
  }

  /*
   * Initialise a tree node, converting all its LIs appropriately
   */
  function initTree(el) {
    var i, j;
    var spanA, spanB, spanC;
    var startingPoint, stoppingPoint, childUL;

    // Find all LIs to process
    for (i = 0; i < el.childNodes.length; i++) {
      if (el.childNodes[i].tagName && el.childNodes[i].tagName.toLowerCase() == 'li') {
        var li = el.childNodes[i];

        // Create our extra spans
        spanA = document.createElement('span');
        spanB = document.createElement('span');
        spanC = document.createElement('span');
        spanA.appendChild(spanB);
        spanB.appendChild(spanC);
        spanA.className = 'a ' + li.className.replace('closed', 'spanClosed');
        spanA.onmouseover = function() {};
        spanB.className = 'b';
        spanB.onclick = treeToggle;
        spanC.className = 'c';


        // Find the UL within the LI, if it exists
        stoppingPoint = li.childNodes.length;
        startingPoint = 0;
        childUL = null;
        for (j = 0; j < li.childNodes.length; j++) {
          if (li.childNodes[j].tagName && li.childNodes[j].tagName.toLowerCase() == 'div') {
            startingPoint = j + 1;
            continue;
          }

          if (li.childNodes[j].tagName && li.childNodes[j].tagName.toLowerCase() == 'ul') {
            childUL = li.childNodes[j];
            stoppingPoint = j;
            break;
          }
        }

        // Move all the nodes up until that point into spanC
        for (j = startingPoint; j < stoppingPoint; j++) {
          spanC.appendChild(li.childNodes[startingPoint]);
        }

        // Insert the outermost extra span into the tree
        if (li.childNodes.length > startingPoint) {
          li.insertBefore(spanA, li.childNodes[startingPoint]);
        }
        else {
          li.appendChild(spanA);
        }

        // Process the children
        if (childUL != null) {
          if (initTree(childUL)) {
            $j(li).addClass('children');
            $j(spanA).addClass('children');
          }
        }
      }
    }

    if (li) {
      // li and spanA will still be set to the last item
      $j(li).addClass('last');
      $j(spanA).addClass('last');
      return true;
    } else {
      return false;
    }

  }

  /*
   * +/- toggle the tree, where el is the <span class="b"> node
   * force, will force it to "open" or "close"
   */
  function treeToggle(el, force) {
    el = this;

    while (el != null && (!el.tagName || el.tagName.toLowerCase() != "li")) el = el.parentNode;

    // Get UL within the LI
    var $el = $j(el);
    var childSet = $el.children('ul').get(0);
    var topSpan = $el.children('span').get(0);

    if (force != null) {

      if (force == "open") {
        treeOpen(topSpan, el)
      }
      else if (force == "close") {
        treeClose(topSpan, el)
      }

    }

    else if (childSet != null) {
      // Is open, close it
      if (!el.className.match(/(^| )closed($| )/)) {
        treeClose(topSpan, el);
        // Is closed, open it
      } else {
        treeOpen(topSpan, el);
      }
    }
  }

  function treeOpen(a, b) {
    $j(a).removeClass('spanClosed');
    $j(b).removeClass('closed');
  }

  function treeClose(a, b) {
    $j(a).addClass('spanClosed');
    $j(b).addClass('closed');
  }

  // Export
  window.autoInit_trees = autoInit_trees;
})();

BS.VCS = {
  _vcsTreeHandlers : [],
  _vcsTreeCallbacks : [],

  registerTreePopup: function(vcsTreeId, buildFormId, callback, fieldId, controlElementId, additionalOptions) {
    var that = this;
    this.registerCallback(vcsTreeId, callback, fieldId);
    this._vcsTreeHandlers[vcsTreeId] = function() {
      BS.LazyTree.ignoreHashes = true;

      var url = window['base_uri'] + "/buildTypeVcsBrowser.html?lazy-tree-update=true&id=" + buildFormId + "&treeId=" + vcsTreeId;
      BS.LazyTree.treeUrl = that._applyAdditionalOptions(url, additionalOptions);

      var popup = new BS.Popup("vcsTreePopup", {
        hideOnMouseOut: false,
        hideOnMouseClickOutside: true,
        shift: {x: 0, y: 20},
        url: BS.LazyTree.treeUrl
      });
      popup.showPopupNearElement($(controlElementId), {
        onShown() {
          BS.LazyTree.injectIcons(popup.element());
        }
      });
    };
    if (fieldId) {
      var visibilityHandler = {
        updateVisibility: function() {
          if ($j(BS.Util.escapeId(fieldId)).is(':disabled')) {
            $j(BS.Util.escapeId(controlElementId)).hide();
          } else {
            $j(BS.Util.escapeId(controlElementId)).show();
          }
        }
      };
      BS.VisibilityHandlers.attachTo(fieldId, visibilityHandler);
    }
  },

  showTree: function(vcsTreeId) {
    (this._vcsTreeHandlers[vcsTreeId])();
  },

  registerTree: function(container, vcsTreeId, buildFormId, callback, additionalOptions) {
    var that = this;
    this.registerCallback(vcsTreeId, callback);
    this._vcsTreeHandlers[vcsTreeId] = function() {
      BS.LazyTree.ignoreHashes = true;
      BS.LazyTree.treeUrl = window['base_uri'] + "/buildTypeVcsBrowser.html?lazy-tree-update=true&id=" + buildFormId + "&treeId=" + vcsTreeId;
      BS.LazyTree.treeUrl = that._applyAdditionalOptions(BS.LazyTree.treeUrl, additionalOptions);

      BS.LazyTree.loadTree(container);
    };
  },

  _applyAdditionalOptions: function(url, options) {
    if (options.vcsRootId) {
      url += '&vcsRootId=' + options.vcsRootId;
    }
    if (options.dirsOnly) {
      url += '&dirsOnly=' + options.dirsOnly;
    }
    if (options.rootDirName) {
      url += '&rootDirName=' + encodeURIComponent(options.rootDirName);
    }

    return url;
  },

  fileChosen: function(file, vcsTreeId, treeElement) {
    var callback = this._vcsTreeCallbacks[vcsTreeId];
    if (callback) {
      callback(file, treeElement);
    }
  },

  registerCallback: function(vcsTreeId, callback, fieldId) {
    if (fieldId) {
      this._vcsTreeCallbacks[vcsTreeId] = function(chosenFile, treeElement) {
        $j(BS.Util.escapeId(fieldId)).val(chosenFile);
        BS.Highlight(treeElement, {restorecolor: 'var(--ring-content-background-color, #fff)'});
      };
    } else {
      this._vcsTreeCallbacks[vcsTreeId] = function(chosenFile, treeElement) {
        var withnamespace = callback.indexOf('.') != -1;
        if (withnamespace) {
          var parts = callback.split(".");
          var method = parts[parts.length-1];
          var obj = window;
          for (var i = 0; i < parts.length-1; i++) {
            obj = obj[parts[i]];
          }
          obj[method](chosenFile, vcsTreeId, treeElement);
        } else {
          window[callback](chosenFile, vcsTreeId, treeElement);
        }
      };
    }

    return "BS.VCS.fileChosen";
  }
};

BS.LazyTree = {
  treeUrl : null,
  ignoreHashes: false,
  options: {},

  getUrl: function() {
    var url = (this.treeUrl) ? this.treeUrl : document.location.href;
    var hashIdx = url.indexOf('#');
    if (hashIdx >= 0) {
      url = url.substring(0, hashIdx);
    }
    return url;
  },

  getHash: function() {
    var hash = window.location.hash;
    if (hash) {
      if (this.ignoreHashes || !hash.startsWith("#!")) {
        // The hash may be not related to the tree (TW-20305).
        return "";
      }
      hash = hash.substring(2);
    }
    return hash;
  },

  setHash: function(hash) {
    if (!this.ignoreHashes) {
      window.location.hash = '#!' + hash;
    }
  },

  injectIcons: function(container) {
    container.querySelectorAll('span.c').forEach(span => {
      if (span.hasAttribute('data-icon-added')) {
        return
      }
      const icon = document.createElement('span');
      span.prepend(icon);
      const isFile = span.closest('.leaf') != null;
      icon.outerHTML = ReactUI.createAndRenderStatic(ReactUI.FileTreeIcon, {
        className: isFile ? 'fileIcon' : 'folderIcon',
        icon: isFile
              ? 'file'
              : span.classList.contains('archive') ? 'archive' : 'folder'
      });
      span.setAttribute('data-icon-added', 'true');
    });
  },

  loadTree: function(containerId) {
    var that = this;

    containerId = $(containerId);
    this.initNavigation(containerId);

    // If the tree is loaded quickly (less than 100ms), nobody's going to notice the loading icon.
    // But for long requests, it will appear. For more details see TW-14027.
    $j("<span>", {
      css: {display: "none"},
      html: BS.loadingIcon + "&nbsp;Loading...",
      appendTo: containerId
    }).fadeIn("slow");

    BS.ajaxRequest(that.getUrl(), {
      parameters: "lazy-tree-update=1&lazy-tree-open=" + that.getHash(),
      method : "get",
      onComplete: function(transport) {
        containerId.innerHTML = "";
        containerId.insert(transport.responseText);
        BS.LazyTree.injectIcons(containerId);

        var $container = $j(containerId);
        if (that.options.fullWidthClick) {
          $container.addClass('tree-full-width-click');
        }

        $container.find("a:first").focus();

        $j(document).trigger("bs.treeLoaded", [containerId, that.options]);
      }
    });
  },

  toggleShow: function(id) {
    var elem = $('U' + id);
    if (elem) {
      if (elem.visible()) {
        elem.hide();
        this.updateClass(id, "open", "closed");
        this.removeHash(id);
        if (this.isErrorNode(elem)) {       // In case of error, remove the node, so it will requested again
          elem.remove();
        }
      } else {
        elem.show();
        this.updateClass(id, "closed", "open");
        this.addHash(id);
      }
    } else {
      if (this.updateClass(id, "closed", "open")) {   // Open for the first time
        this.loadSubtree(id);
        this.addHash(id);
      }
    }
  },

  updateClass: function(id, prevValue, newValue) {
    id = $(id);

    var classes = id.className.split(" ");
    if (classes.indexOf(prevValue) == -1 && classes.indexOf(newValue) != -1) {
      // Already opened.
      return false;
    }

    classes.splice(classes.indexOf(prevValue), 1);
    classes.push(newValue);
    id.className = classes.join(" ");
    return true;
  },

  addHash: function(id) {
    var current = this.getHash();
    if (!current) {
      this.setHash(id);
    } else {
      this.setHash(current + "," + id);
    }
  },

  removeHash: function(id) {
    var current = this.getHash();
    if (!current) {
      return;
    }
    var ids = current.split(",");
    var idx = ids.indexOf(id);
    if (idx >= 0) {
      ids.splice(idx, 1);
    }
    this.setHash(ids.join(","));
  },

  loadSubtree: function(id) {
    var elem = $(id);
    var that = this;

    var loading = $j("<i/>").css({
      marginLeft: "16px",
      display: "none"
    }).append(BS.loadingIcon).append("&nbsp;Loading...").appendTo(elem);

    setTimeout(function() {
      loading.show();
    }, 200);

    var path = [];
    while (elem && elem.className.lastIndexOf("lazy-tree") == -1) {
      if (elem.className.lastIndexOf("lazy-subtree") == -1) {
        path.push(elem.id);
      }
      elem = elem.parentNode;
    }
    path.reverse();

    BS.ajaxRequest(this.getUrl(), {
      parameters: "lazy-tree-update=1&lazy-tree-root=" + id + "&lazy-tree-path=" + path.join(","),
      method : "get",
      onComplete: function(transport) {
        loading.remove();

        var el = $(id);
        if (el) {
          $(id).insert(transport.responseText);
          BS.LazyTree.injectIcons(el);

          $j(document).trigger("bs.subtreeLoaded", [$(id), that.options]);
        }
      }
    });
  },

  isErrorNode: function(elem) {
    var children = elem.childNodes;
    return children && children.length == 1 && children[0].className == "tree-error";
  },

  initNavigation: function(container) {
    container = $j(container);
    var containerId = container.attr("id");

    function isOpen(div) {
      return div.hasClass("open");
    }
    function isLeaf(div) {
      return div.hasClass("leaf");
    }

    function down(div, lookChildren) {
      if (div.attr("id") == containerId) return null;
      var result;

      if (lookChildren && isOpen(div)) {
        result = div.children("div:visible:first");
        if (result.length) return result;
      }

      result = div.next();
      if (result.length) return result;

      return down(div.parents("div:visible:first"), false);
    }

    function up(div) {
      var result = div.prev();
      if (result.length) {
        var lastChild = result.find("div:visible:last");
        if (lastChild.length) return lastChild;
        return result;
      }

      result = div.parents("div.open:visible:first");
      if (result.length) return result;

      return null;
    }

    function right(div) {
      if (!isOpen(div) && !isLeaf(div)) {
        var id = div.attr("id");
        if (id) BS.LazyTree.toggleShow(id);
      }
      return null;
    }

    function left(div) {
      if (isOpen(div) && !isLeaf(div)) {
        var id = div.attr("id");
        if (id) BS.LazyTree.toggleShow(id);
      }
      return null;
    }

    container.on("keydown", function(e) {
      var keyCode = e.keyCode;
      if (keyCode != Event.KEY_DOWN && keyCode != Event.KEY_UP &&
          keyCode != Event.KEY_RIGHT && keyCode != Event.KEY_LEFT) {
        return true;
      }

      var focused = container.find(":focus");
      if (!focused.length) return true;
      var div = focused.closest("div");

      var newDiv;

      switch (keyCode) {
        case Event.KEY_DOWN: newDiv = down(div, true); break;
        case Event.KEY_UP: newDiv = up(div); break;
        case Event.KEY_RIGHT: newDiv = right(div); break;
        case Event.KEY_LEFT: newDiv = left(div); break;
      }

      if (newDiv) {
        newDiv.find("a:first").focus();
      }

      return false;
    });

    if (this.options.fullWidthClick) {
      container.on("click", ".a", function (e) {
        var $target = $j(e.target);
        if ($target.prop("tagName") !== "A" && !$target.attr("onclick")) {
          var $currentTarget = $j(e.currentTarget);
          if (!$currentTarget.attr("onclick")) {
            var $fileLink = $currentTarget.find("a:first");
            if ($fileLink.length) {
              var href = $fileLink.attr('href');
              if (href) {
                window.location.href = href;
              }
            }
          }
        }
      });
    }
  }
};

// In case upload is used, "derived" objects must define getContainer() and formElement() functions.
BS.FileBrowse = {

  onFileChanged: function(filename) {
  },

  error: function(msg) {
    this.setSaving(false);
    $j("#uploadError").text(msg).show();
  },

  clear: function() {
    var container = $j(this.getContainer());
    container.find("input[type=file]").val("");
    $j("#uploadError").hide();
  },

  show: function() {
    this.clear();
    this.showCentered();
    return false;
  },

  validate: function() {
    var fileName = $j("#fileName").val(),
        file = $j("#file\\:fileToUpload").val();

    if (fileName == "") {
      this.error("Please set the file name");
      return false;
    }

    var destination = $j("#destination");
    if ((!destination.length || destination.val() == destination.attr("default")) && !this.checkFileNotExists(fileName)) {
      return false;
    }

    if (file == "") {
      this.error("Please select a file to upload");
      return false;
    }

    this.setSaving(true);
    return true;
  },

  deleteFile: function(actionUrl, homeUrl, message, fileName) {
    var s = (!message) ? "Delete \"" + fileName + "\"?" :
                         message + "\n" + "Delete anyway?";
    if (!confirm(s)) {
      return false;
    }

    BS.ajaxRequest(actionUrl, {
      method: "post",
      parameters: {
        action: "delete",
        fileName: fileName
      },
      onComplete: function() {
        document.location.href = homeUrl;
      }
    });
    return false;
  },

  startEdit: function() {
    var area = this._toggleEdit();
    area.focus();
    return false;
  },

  _toggleEdit: function() {
    var area = $j("#edit-area").toggle()
                               .siblings(".fileContent").toggle().end();
    $j(".fileOperations").toggle();
    $j("#modifiedMessage").toggle();
    return area;
  },

  cancelEdit: function() {
    this._toggleEdit();
  },

  save: function(actionUrl, fileName) {
    BS.ajaxRequest(actionUrl, {
      method: "post",
      parameters: {
        action: "edit",
        fileName: fileName,
        content: $j("#edit-area").val()
      },
      onComplete: function() {
        BS.reload();
      }
    });
  },

  setFiles: function(files, caseInsensitive) {
    this.files = files;
    this.caseInsensitiveFileNames = caseInsensitive;
  },

  prepareFileUpload: function() {
    var onFileChangedHandler = this.onFileChanged;
    var container = $j(this.getContainer()),
        isFilenameChangedManually = false,
        oldValue = '';

    // prevent file input `change` event handler from replacing fileName if user edited it manually
    $j("#fileName").on('input', function () {
        oldValue = this.value; // required for IEs, see next handler
        isFilenameChangedManually = !!this.value.length;
        return false;
    });

    // - IE8 does not support `input` event
    // - IE9,10 do not trigger `input` event on removing content from input
    // (backspace, del, cut) so listen to keyup and change
    if (window.attachEvent) {
      $j("#fileName").on('keyup change', function () {
        if (!this.value.length) {
          isFilenameChangedManually = false;
        } else if (this.value !== oldValue) {
          isFilenameChangedManually = true;
          oldValue = this.value;
        }
      });
    }

    container.find("input[type=file]").change(function() {
      var fullPath = $j(this).val();
      if (fullPath && ! isFilenameChangedManually) {
        var startIndex = (fullPath.indexOf('\\') >= 0 ? fullPath.lastIndexOf('\\') : fullPath.lastIndexOf('/'));
        var filename = fullPath.substring(startIndex);
        if (filename.indexOf('\\') === 0 || filename.indexOf('/') === 0) {
          filename = filename.substring(1);
        }
        $j("#fileName").val(filename);
        onFileChangedHandler(filename);
      }
    });
  },

  checkFileNotExists: function(file) {
    for (var i = 0; i < this.files.length; ++i) {
      if (file == this.files[i] || (this.caseInsensitiveFileNames && file.toUpperCase() == this.files[i].toUpperCase())) {
        return confirm("File \"" + file + "\" already exists. Replace it?");
      }
    }
    return true;
  },

  closeAndRefresh: function(refreshParam) {
    this.setSaving(false);
    this.close();
    $j("#refreshing").show();
    this.refresh(refreshParam);
  },

  // Supports the following URL hash format: #<operation>!<nodes-to-expand>
  // The list of nodes is related to the tree browser and is not changed after the call. The operation is cut off.
  //
  // Nodes is generally a comma-separated list of either the decoded node id (default) or a path ":<path-to-node>".
  // Examples:
  // - "#!vntnbpq,yxczv2,20ib"
  // - "#!:config,:plugins"
  // For more information please see the `LazyTree.parseOpenElementsFromRequest()` method.
  //
  // Currently supported operations:
  // - edit ("#edit"): starts the file edit right after page load;
  // - upload ("#upload:<relative-path>"): pops up the upload dialog and presets the relative destination path if it is set.
  //   Just "#upload" is also a valid operation specification.
  // The call does not fail if operation is not available in HTML (e.g. edit or upload is forbidden for the directory),
  // but does nothing instead.
  //
  // Real examples of the URLs:
  // - http://server/admin/admin.html?item=serverConfigGeneral&tab=dataDir&file=config/internal.properties#edit!:config
  //   Means open the file "config/internal.properties" page, run edit, but also use ":config" node list (so that
  //   the config directory is expanded when user clicks "Back to files").
  // - http://server/admin/admin.html?item=serverConfigGeneral&tab=dataDir#upload:plugins!:plugins
  //   Means open the files list page, expand the "plugins" node and show the upload dialog with the relative path "plugins" preset.
  autoRunOperation: function(filename) {
    var hash = window.location.hash;
    if (hash && !hash.startsWith("#!")) {
      var that = this;
      $j(function() {
        if (filename && hash.startsWith("#edit")) {
          that.startEdit && that.startEdit(filename);
        }

        if (hash.startsWith("#upload")) {
          var destination = $j("#destination");
          var relativePath = hash.substr(7);          // trim '#upload'
          if (relativePath.startsWith(":")) {
            relativePath = relativePath.substr(1);    // trim ':'
          }
          if (relativePath.include("!")) {
            relativePath = relativePath.substr(0, relativePath.indexOf("!"));
          }
          if (relativePath) {
            var path = destination.val();
            if (!path.endsWith("/")) { path += "/"; }
            path += relativePath;
            destination.val(path);
          }
          that.show && that.show();
        }
      });

      if (hash.include("!")) {
        window.location.hash = "#" + hash.substr(hash.indexOf("!"));
      } else {
        window.location.hash = "";
      }
    }
  }
};
