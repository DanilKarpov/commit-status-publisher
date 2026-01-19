BS.BlocksWithHeader = Class.create(BS.Blocks, {

  blocksType: "blocks",
  collapsedByDefault: false,

// Constructor:
  initialize: function($super, elementId, dontRestorePreviousState) {
    $super();
    this.blocksType = "Block_" + elementId;

    var blockHeaderElement = $(elementId);
    if (!blockHeaderElement) return;

    this.headerId = elementId;
    if (!blockHeaderElement.title && blockHeaderElement.className.indexOf('no_title') == -1) {
      blockHeaderElement.title = "Click to expand/collapse this block";
    }

    this.collapsedByDefault = blockHeaderElement.className.indexOf("expanded") == -1;

    blockHeaderElement.on("click", this._onclick.bindAsEventListener(this));

    blockHeaderElement = null; // prevent memory leak

    if (!dontRestorePreviousState) {
      this.restoreSavedBlocks();
    }
  },

  getId: function() {
    return this.headerId;
  },

  show: function() {
    this.changeState(this.headerId, true, true);
    this._saveState();
  },

  _onclick: function(e) {
    this.toggleBlock(this.headerId, false);
  },

  getBlockContentElement: function(id) {
    var el = $(id);

    if (!el || !el.parentNode) return;

    $(el.parentNode).cleanWhitespace();
    var contentDiv = el.nextSibling;
    if (!contentDiv) alert("No contentDiv for " + el.id);
    return contentDiv;
  },

  /**
   * @param contentElement
   * @param {String|HTMLElement} id
   */
  onHideBlock: function(contentElement, id) {
    "use strict";
    this._setHandleExpanded(id, false);
  },

  /**
   * @param contentElement
   * @param {String|HTMLElement} id
   */
  onShowBlock: function(contentElement, id) {
    "use strict";
    this._setHandleExpanded(id, true);
  },

  /**
   * <p>Sets the expanded/collapsed state of the handle of a collapsible block.
   * </p>
   *
   * @param {String|HTMLElement} id the header of the collapsible block.
   * @param {Boolean} expanded the expanded/collapsed state.
   * @private
   * @since 2017.1.1
   */
  _setHandleExpanded: function(id, expanded) {
    "use strict";
    var $id = $(id);

    var oldClassSearchRegex = expanded ? /^collapsed_.+$/ : /^expanded_.+$/;
    var oldClassReplaceRegex = expanded ? /^collapsed/ : /^expanded/;
    var oldClassName = expanded ? "collapsed" : "expanded";
    var newClassName = expanded ? "expanded" : "collapsed";

    /*
     * Search for "expanded_xyz" and "collapsed_xyz" classes.
     *
     * TODO: use Element.classList
     */
    $id.classNames().filter(function(/**String*/ className) {
      return oldClassSearchRegex.test(className);
    }).each(function(/**String*/ className) {
      $id.addClassName(className.replace(oldClassReplaceRegex, newClassName));
      $id.removeClassName(className);
    });

    /*
     * Neither "expanded" nor "collapsed" class may be present initially, so we
     * add/remove them explicitly here instead of using filter()/each().
     */
    $id.addClassName(newClassName);
    $id.removeClassName(oldClassName);
  }
});
