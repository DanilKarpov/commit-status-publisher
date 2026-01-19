/*
 * Copyright 2000-2018 JetBrains s.r.o.
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

BS.TreeSelection = Class.create({

  /* Tree model is a class of BS.Tree */
  initialize: function(tree_model) {
    this._model = tree_model;
    this._selected = null;
  },

  getSelection: function() {
    return this._selected;
  },

  setSelection: function(id) {
    if (id == this._selected) {
      return;
    }
    
    if (this._model.getNode(id)) {
      var oldSelected;
      if ($(this._selected)) {
        oldSelected = this._selected;
        $(this._selected).removeClassName("selectedTreeNode");
      }
      this._selected = id;
      this._model._notify("onSelectionChange", id, oldSelected);
      this.repaintSelection();
    }
  },

  repaintSelection: function() {
    if ($(this._selected) && !$(this._selected).hasClassName("selectedTreeNode")) {
      $(this._selected).addClassName("selectedTreeNode");
      this._model._notify("onSelectionRepaint", this._selected);
    }
  },

  clickHandler: function(event) {
    var el = Event.element(event);
    while(el != null) {
      var node = this._model.getNode(el.id);
      if (node) {
        this.setSelection(node.getId());
        break;
      }
      el = $(el.parentNode);
    }
  },

  getCurrNode: function() {
    return this._model.getNode(this._selected);
  },

  getNext: function() {
    if (!this._selected) {
      return this._model.getFirstNode();
    }

    var currNode = this.getCurrNode();
    if (currNode == null) {
      return this._model.getFirstNode();
    }
    return currNode.getNext();
  },

  getPrev: function() {
    if (!this._selected) {
      return null;
    }

    var currNode = this.getCurrNode();
    return currNode.getPrev();
  }


});

BS.TreeKeyboardSupport = Class.create({

  /*  selection_model is BS.TreeSelection */
  initialize: function(root_element, selection_model) {
    this.model = selection_model;

    this._handlers = {};
    this._handlers[Event.KEY_DOWN] = this.down;
    this._handlers[Event.KEY_UP] = this.up;
    this._handlers[Event.KEY_LEFT] = this.left;
    this._handlers[Event.KEY_RIGHT] = this.right;

    this._handlers[107] = this.expand; // Gray '+'
    this._handlers[109] = this.collapse; // Gray '-'

    BS.Util.runWithElement(root_element, function() {
      jQuery(root_element).on('keydown', function(e) {
        if (BS.Hider.hasVisiblePopups()) return;
        var focused = document.activeElement;
        if (focused && (focused.tagName == 'INPUT' || focused.tagName == 'TEXTAREA'|| focused.tagName == 'SELECT'))
          return;

        if (this._handlers[e.keyCode] && this._handlers[e.keyCode].call(this, e)) {
          return false;
        }
      }.bind(this));
    }.bind(this), 3000);

  },

  addKeyHandler: function(keyCode, handler) {
    this._handlers[keyCode] = handler;
  },

  down: function() {
    var next = this.model.getNext();
    if (next) {
      this.model.setSelection(next);
      this.updateScrollingBySelection();
    }
    return true;
  },

  up: function() {
    var next = this.model.getPrev();
    if (next) {
      this.model.setSelection(next);
      this.updateScrollingBySelection();
    }
    return true;
  },

  updateScrollingBySelection: function() {
    var currNode = this.model.getCurrNode();
    if (!currNode) return;

    var selectedElement = $(this.model.getSelection());
    if (!selectedElement) return;

    var et = selectedElement.viewportOffset().top;
    var eb = et + selectedElement.getHeight();

    if (et < 0) {
      this.scrollSmooth(et - 20);
    }
    else {
      var diff = eb - this.viewHeight();
      if (diff > 0) {
        this.scrollSmooth(diff + 20);
      }
    }
  },

  scrollSmooth: function(yDiff) {
    Effect.ScrollTo(document.body, {offset: (document.viewport.getScrollOffsets().top + yDiff), duration: 0.2});
  },

  viewHeight: function() {
    return document.viewport.getHeight();
  },

  left: function() {
    var currNode = this.model.getCurrNode();
    if (!currNode) return;

    if (currNode.isExpanded()) {
      this.collapse();
    }
    else {
      this.up();
    }
    return true;
  },

  collapse: function() {
    this.setExpanded(false);
    return true;
  },

  expand: function() {
    this.setExpanded(true);
    return true;
  },

  setExpanded: function(state) {
    var currNode = this.model.getCurrNode();
    if (!currNode) return;
    currNode.setExpanded(state);
  },

  right: function() {
    var currNode = this.model.getCurrNode();
    if (!currNode) return;
    if (!currNode.isExpanded()) {
      this.expand();
    }
    else {
      this.down();
    }
    return true;
  },

  _f: null
});
