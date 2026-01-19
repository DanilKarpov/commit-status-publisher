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

BS.TreeNode = Class.create({

  initialize: function(elementId, expanded) {
    this._id = elementId;
    this._children_ids = [];
    this._parent_id = null;

    this._expanded = expanded;
  },

  setTree: function(tree) {
    this.tree = tree;
  },

  onExpandChange: function() {},


  getId: function() { return this._id; },
  getChildren: function() { return this._children_ids; },
  getParent: function() { return this._parent_id; },
  isExpanded: function() { return this._expanded },

  getParentNode: function() {
    return this.tree.getNode(this.getParent());
  },

  getSiblings: function() {
    var parent = this.getParentNode();
    return parent == null ? this.tree.getChildren() : parent.getChildren();
  },

  addChild: function(tree_node) {
    if (this._children_ids.indexOf(tree_node.getId()) == -1) {
      this._children_ids.push(tree_node.getId());
    }

    tree_node._parent_id = this.getId();

    if (this.tree) {
      this.tree.registerNode(tree_node);
    }
  },

  destroy: function() {
    if (this.getParentNode()) {
      this.removeMeFrom(this.getParentNode().getChildren());
    }
    this.tree.unregisterNode(this);

    this.forEach(function(child) {
      child.destroy();
    }, false);
  },

  removeMeFrom: function(ids_array) {
    var pos = ids_array.indexOf(this.getId());
    if (pos >= 0) {
      ids_array.splice(pos, 1);
    }
  },

  toggle: function() {
    this.setExpanded(!this._expanded);
  },

  setExpanded: function(expanded) {
    if (expanded != this._expanded) {

      if (expanded) {
        this.expandParent();
      }

      this._expanded = expanded;
      this.onExpandChange();

      if (this.tree) {
        this.tree.onExpandChange(this);
      }
    }
  },

  expandParent: function() {
    var parent = this.getParentNode();
    if (parent) {
      parent.setExpanded(true);
    }
  },

  forEach: function(handler, runHandlerForThis) {
    if (runHandlerForThis) {
      handler(this);
    }
    $A(this.getChildren()).each(function(child_id) {
      var child = this.tree.getNode(child_id);
      if (child) {
        child.forEach(handler, true);
      }
    }, this);
  },

  getNext: function() {
    if (this.isExpanded() && this._children_ids.length > 0) {
      return this._children_ids[0];
    }

    var siblings = this.getSiblings();
    for (var i = 0; i < siblings.length; i ++) {
      if (this._id == siblings[i]) {
        if (i + 1 < siblings.length) {
          return siblings[i + 1];
        }
        else {
          var parentNode = this.getParentNode();
          if (!parentNode) return null;

          // recursive hack:
          var orig = parentNode._expanded;
          parentNode._expanded = false;
          var res = parentNode.getNext();
          parentNode._expanded = orig;
          return res;
        }
      }
    }
    
    return null;
  },

  getPrev: function() {
    
    var siblings = this.getSiblings();
    for (var i = 0; i < siblings.length; i ++) {
      if (this._id == siblings[i]) {
        if (i > 0) {
          var prevNode = this.tree.getNode(siblings[i - 1]);
          if (prevNode.isExpanded()) {
            var children = prevNode.getChildren();
            if (children.length > 0) {
              return children[children.length - 1];
            }
          }
          return prevNode.getId();
        }
        else {
          return this.getParent();
        }
      }
    }

    return null;
  },

  _f: null
});



BS.Tree = Class.create({

  initialize: function() {
    this._root_sequence = [];
    this._nodes = {};

    this._listeners = [];
  },

  dispose: function() {
    this.forEachNode(function(node) {
      node.destroy();
    });
  },

  addNodeIfNotExists: function(tree_node) {
    // add node to the end of node sequence
    if (this._root_sequence.indexOf(tree_node.getId()) == -1) {
      this._root_sequence.push(tree_node.getId());
    }

    // add node to node map
    this.registerNode(tree_node);
  },

  /*
  * Methods of the listener:
  * onNodeAdded(node) - when information about node is added to the tree the first time
  * onExpandChange(node) - when expand/collapse state of the node is changed
  * onNodeDestroyed(node) - after node was removed from tree
  *
  * onSelectionChange(oldSelectionId, newSelectionId) - when selection changed in tree
  * onSelectionRepaint(selectionId) - when selection should be repainted
  *
  * */
  addListener: function(listener) {
    this._listeners.push(listener);
  },

  getNode: function(node_id) {
    return this._nodes[node_id];
  },

  setNodeSequence: function(ids_of_top_level_nodes) {
    // Optionally, specify explicit sequence of top level nodes
    this._root_sequence = ids_of_top_level_nodes;
  },

  getFirstNode: function() {
    return this._root_sequence.length > 0 ? this._root_sequence[0] : null;
  },

  getChildren: function() {
    return this._root_sequence;
  },

  registerNode: function(node) {
    var previousNode = this._nodes[node.getId()];
    if (!previousNode) {
      this._nodes[node.getId()] = node;
      node.setTree(this);

      this._notify("onNodeAdded", node);
    }
  },

  unregisterNode: function(node) {
    delete this._nodes[node.getId()];

    node.removeMeFrom(this._root_sequence);

    this._notify("onNodeDestroyed", node);
    node.setTree(null);
  },

  onExpandChange: function(changed_node) {
    this._notify('onExpandChange', changed_node);
  },

  collectExpandedNodes: function() {
    var res = "";
    this.forEachNode(function(node) {
      if (node.isExpanded()) {
        res += node.getId() + ":";
      }
    });
    return res;
  },

  forEachNode: function(handler) {
    $A(this._root_sequence).each(function(node_id) {
      var node = this.getNode(node_id);
      if (node) {
        node.forEach(handler, true);
      }
    }, this);
  },

  _notify: function(method) {
    var args = $A(arguments);
    args.shift();

    $A(this._listeners).each(function(listener) {
      if (listener[method]) {
        listener[method].apply(this, args);
      }
    }, this);

  },

  f_: null
});
