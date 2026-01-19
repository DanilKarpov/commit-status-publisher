BS.Point = function (x,y) {
  this.x = x;
  this.y = y;
};

BS.LayeredGraph = function() {
  this.layers = [];
  this.nodes = [];

  this.Layer = function() {
    this.nodes = [];
    this.width = 0;
  };

  this.Node = function(elem, layerIdx, fakeNode) {
    this.elem = $(elem);
    this.id = this.elem.id;
    this.layerIdx = layerIdx;
    this.dependencies = [];
    this.lineStyles = [];
    this.dependedOnMe = [];
    this.fakeNodeFlag = fakeNode;
    this.numDependedOnMe = 0;
    this.numDependencies = 0;
    this._outgoingLines = [];
    this._graph = null;

    this._cachedWidth = null;
    this._cachedHeight = null;
    this._cachedPos = null; // BS.Point

    this.fakeNode = function() {
      return this.fakeNodeFlag;
    };

    this.addDependency = function(id, lineStyle) {
      var node = this._graph.nodes[id];
      if (node == null) alert("Cannot find node for id: " + id);
      this.dependencies.push(node);
      this.lineStyles[id] = lineStyle;
      this.numDependencies++;
      node.dependedOnMe.push(this);
      node.numDependedOnMe++;
    };

    this.getDependencies = function() {
      return this.dependencies;
    };

    this.getLineStyles = function() {
      return this.lineStyles;
    };

    this.getDependedOnMe = function() {
      return this.dependedOnMe;
    };

    this.width = function() {
      if (this._cachedWidth) return this._cachedWidth;
      this._cachedWidth = this.elem.offsetWidth;
      return this._cachedWidth;
    };

    this.height = function() {
      if (this.fakeNode()) return 0;
      if (this._cachedHeight) return this._cachedHeight;
      this._cachedHeight = this.elem.offsetHeight;
      return this._cachedHeight;
    };

    this.position = function(pos) {
      if (pos != null) {
        this._cachedPos = pos;
        return pos;
      }

      if (this._cachedPos) return this._cachedPos;
      this._cachedPos = new BS.Point(this.elem.offsetLeft, this.elem.offsetTop);
      return this._cachedPos;
    }
  };

  this.addNode = function (elem, layerIdx, fakeNode) {
    var layer = this.layers[layerIdx];
    if (layer == null) {
      layer = new this.Layer();
      this.layers[layerIdx] = layer;
    }
    var node = new this.Node($(elem), layerIdx, fakeNode);
    node._graph = this;
    layer.nodes.push(node);
    this.nodes[node.id] = node;
    return node;
  };

  this.getNodes = function() {
    var res = [];
    for (var id in this.nodes) {
      if (!this.nodes.hasOwnProperty(id)) continue;
      res.push(this.nodes[id]);
    }
    return res;
  }
};

BS.LayeredGraphDrawer = function(graph, options) {
  this.options = {
    canvasPadding: [2, 2], // left & top only
    verticalSpacing: 15,
    arrowDimensions: [5, 5],
    trunkWidth: 5
  };

  _.extend(this.options, options);

  this.graph = graph;
  this.selectedNodes = [];
  this.layerGroups = [];

  this.paths = {
    absCubicBezier: function(x1, y1, x2, y2, end) {
      return "C" + x1 + " " + y1 + " " + x2 + " " + y2 + " " + end.x + " "+ end.y
    },

    absMove: function(point) {
      return "M" + point.x + " " + point.y;
    },

    absLine: function(point) {
      return "L" + point.x + " " + point.y;
    }
  };

  this.drawGraph = function(canvasElem, callback) {
    canvasElem = $(canvasElem);

    this._initGroups();
    this._repositionNodes();
    this._initCanvas($(canvasElem));
    this._drawEdges();
    this._attachEventHandlers();
    if (callback) {
      callback();
    }
  };

  this._initGroups = function() {
    for (var i=1; i<this.graph.layers.length; i++) {
      var layer = this.graph.layers[i];
      this.layerGroups[i] = this._computeGroups(layer);
    }
  };

  this._repositionNodes = function() {
    var xPos = this.options.canvasPadding[0];
    for (var i=0; i<this.graph.layers.length; i++) {
      var layer = this.graph.layers[i];
      var maxWidth = 0;
      var yPos = this.options.canvasPadding[1];
      for (var j=0; j<layer.nodes.length; j++) {
        var node = layer.nodes[j];
        if (j > 0 && node.fakeNode()) {
          // check if all nodes after that node are fake too
          var allFake = true;
          for (var k=j; k<layer.nodes.length; k++) {
            if (!layer.nodes[k].fakeNode()) {
              allFake = false;
              break;
            }
          }

          if (allFake) {
            var children = node.getDependencies();
            var averageChildrenPos = this._medianYPos(children);
            if (node.position().y < averageChildrenPos) {
              yPos = Math.max(averageChildrenPos, yPos);
            }
          }
        }

        maxWidth = Math.max(maxWidth, node.width());
        node.elem.style.left = xPos + 'px';
        node.elem.style.top = yPos + 'px';
        node.position(new BS.Point(xPos, yPos));

        yPos += node.height() + this.options.verticalSpacing;
      }

      layer.width = maxWidth;

      var groups = this.layerGroups[i+1];
      if (groups != null) {
        layer.width += 3*this.options.arrowDimensions[0] + groups.length * this.options.trunkWidth;
      }

      layer.height = yPos;
      layer.maxNodeWidth = maxWidth;
      xPos += layer.width;
    }

    // second iteration to process fake nodes one more time
    for (var i=0; i<this.graph.layers.length; i++) {
      var layer = this.graph.layers[i];
      var minPossibleYPos = 0;
      for (var j=0; j<layer.nodes.length; j++) {
        var node = layer.nodes[j];
        if (node.fakeNode()) {
          // check if all nodes after that node are fake too
          var allFake = true;
          for (var k=j; k<layer.nodes.length; k++) {
            if (!layer.nodes[k].fakeNode()) {
              allFake = false;
              break;
            }
          }

          if (allFake) {
            var parents = node.getDependedOnMe();
            var averageParentsPos = this._medianYPos(parents);
            if (node.position().y < averageParentsPos) {
              var yPos = Math.max(averageParentsPos, minPossibleYPos);
              minPossibleYPos = yPos + this.options.verticalSpacing;
              node.elem.style.top = yPos + 'px';
              node.position(new BS.Point(node.position().x, yPos));
            }
          }
        }
      }
    }

    for (var i=0; i<this.graph.layers.length; i++) {
      var groups = this.layerGroups[i];
      if (groups == null) continue;

      for (var j=0; j<groups.length; j++) {
        var group = groups[j];
        group.medianParentsYPos = this._medianYPos(group.parents);
        group.medianChildrenYPos = this._medianYPos(group.children);
      }
    }
  },

  this._initCanvas = function (canvasEl) {
    canvasEl.innerHTML = "";
    this.rootEl = canvasEl.parentNode;
    var height = 0;
    var width = 0;
    for (var i=0; i<this.graph.layers.length; i++) {
      var layer = this.graph.layers[i];
      width += layer.width;
      height = Math.max(height, layer.height);
    }

    //alert((width + 100) + ", " + (height + 100));
    this.paper = Raphael(canvasEl, width, height);
  };


  this._computeGroups = function(layer) {
    var groups = this._groupByParents(layer);
    while (true) { // eslint-disable-line
      var groupsChanged = false;
      for (var i=0; i<groups.length; i++) {
        var gr1 = groups[i];
        if (gr1 == null) continue;

        for (var j=i+1; j<groups.length; j++) {
          var gr2 = groups[j];
          if (gr2 == null) continue;

          var chIntersection = _.intersection(gr1.children, gr2.children);
          if (chIntersection.length == 0) continue;

          var factor = this._groupsFactor([gr1, gr2]);

          var newGroups = [];
          newGroups.push({
            children: chIntersection,
            parents: gr1.parents.concat(gr2.parents)
          });
          var gr1Group = this._extractGroup(gr1, _.difference(gr1.children, chIntersection));
          if (gr1Group != null) newGroups.push(gr1Group);
          var gr2Group = this._extractGroup(gr2, _.difference(gr2.children, chIntersection));
          if (gr2Group != null) newGroups.push(gr2Group);

          var newFactor = this._groupsFactor(newGroups);
          if (newFactor < factor) {
            delete groups[i];
            delete groups[j];
            groups = groups.concat(newGroups);
            groupsChanged = true;
            break;
          }
        }

        if (groupsChanged) break;
      }

      if (!groupsChanged) break;
    }

    var result = [];
    for (var i=0; i<groups.length; i++) {
      var group = groups[i];
      if (group != null) {
        result.push(group);
      }
    }

    return result;
  };

  this._extractGroup = function(origGroup, newChildren) {
    if (newChildren.length == 0) return null;
    var group = {
      children: newChildren,
      parents: []
    };
    for (var i=0; i<newChildren.length; i++) {
      var child = newChildren[i];
      var intersParents = _.intersection(origGroup.parents, child.getDependedOnMe());
      group.parents = group.parents.concat(intersParents);
    }
    return group;
  };

  this._groupByParents = function(layer) {
    var result = [];
    for (var i=0; i < layer.nodes.length; i++) {
      var parent = layer.nodes[i];
      var children = parent.getDependencies();
      result.push({
        parents: [parent],
        children: children,
        medianY: -1
      });
    }

    return result;
  };

  this._groupsFactor = function(groups) {
    var factor = 0;
    for (var i=0; i<groups.length; i++) {
      factor += groups[i].parents.length + groups[i].children.length;
    }
    return factor;
  };

  this._medianYPos = function(nodes) {
    var maxMedian = 0;
    var minMedian = 1000000;
    for (var m=0; m<nodes.length; m++) {
      var n = nodes[m];
      var curNodeCenter = n.position().y + n.height() / 2;
      maxMedian = Math.max(maxMedian, curNodeCenter);
      minMedian = Math.min(minMedian, curNodeCenter);
    }

    return minMedian + (maxMedian - minMedian) / 2;
  };

  this._drawEdges = function() {
    for (var i=1; i<this.graph.layers.length; i++) {
      var prevLayer = this.graph.layers[i-1];
      var layer = this.graph.layers[i];
      var groups = this.layerGroups[i];

      groups.sort(function(group1, group2) {
        var children1Ypos = group1.medianChildrenYPos;
        var parents1YPos = group1.medianParentsYPos;

        var children2Ypos = group2.medianChildrenYPos;
        var parents2YPos = group2.medianParentsYPos;

        if (children2Ypos == children1Ypos) {
          // same child
          var dist1 = Math.abs(parents1YPos - children1Ypos);
          var dist2 = Math.abs(parents2YPos - children1Ypos);
          if (dist1 < dist2) return 1;
          if (dist1 > dist2) return -1;
          return parents2YPos - parents1YPos;
        }

        if (parents1YPos == parents2YPos) {
          // same parent
          var dist1 = Math.abs(children1Ypos - parents1YPos);
          var dist2 = Math.abs(children2Ypos - parents1YPos);
          if (dist1 < dist2) return -1;
          if (dist1 > dist2) return 1;
          return children1Ypos - children2Ypos;
        }

        if (children1Ypos < parents1YPos && children2Ypos < parents2YPos) {
          // parents below children
          return children2Ypos - children1Ypos;
        }

        if (children1Ypos > parents1YPos && children2Ypos > parents2YPos) {
          // children below parents
          return children1Ypos - children2Ypos;
        }

        if ((children1Ypos > parents1YPos && children2Ypos < parents2YPos) ||
            (children1Ypos < parents1YPos && children2Ypos > parents2YPos)) {
          var dist1 = Math.abs(children1Ypos - parents1YPos);
          var dist2 = Math.abs(children2Ypos - parents1YPos);
          if (dist1 < dist2) return -1;
          if (dist1 > dist2) return 1;
          return children1Ypos - children2Ypos;
        }

        return 0;
      }.bind(this));

      var groupsMap = this._computeGroupsMap(groups, layer.nodes, prevLayer.nodes);

      var verticalLineIdx = 1;
      for (var j=0; j<groups.length; j++) {
        var group = groups[j];

        var trunkX = prevLayer.nodes[0].position().x + prevLayer.maxNodeWidth + (1 + verticalLineIdx) * this.options.trunkWidth;
        verticalLineIdx++;

        for (var k=0; k<group.children.length; k++) {
          var child = group.children[k];

          var childGroups = groupsMap[child.id];
          var outgoingLinesDist = Math.round(child.height() / (childGroups.length+1));
          childGroups.sort(function(group1, group2) {
            return group1.medianParentsYPos - group2.medianParentsYPos;
          }.bind(this));

          var outgoingLineIdx = childGroups.indexOf(group);

          var childYPos = child.position().y + outgoingLinesDist * (outgoingLineIdx + 1);

          for (var m=0; m<group.parents.length; m++) {
            var parent = group.parents[m];
            var parentGroups = groupsMap[parent.id];
            var incomingLinesDist = Math.round(parent.height() / (parentGroups.length+1));

            parentGroups.sort(function(group1, group2) {
              return group1.medianChildrenYPos - group2.medianChildrenYPos;
            }.bind(this));

            var incomingLineIdx = parentGroups.indexOf(group);

            var parYPos = parent.position().y + incomingLinesDist * (incomingLineIdx + 1);

            var childXPos = child.fakeNode() ? child.position().x : child.position().x + child.width();

            var points = [
              new BS.Point(childXPos, childYPos),
              new BS.Point(trunkX, childYPos),
              new BS.Point(trunkX, parYPos),
              new BS.Point(parent.position().x, parYPos)
            ];

            var lineStyle = parent.getLineStyles()[child.id];

            var that = this;
            var line = this._drawLines(points, lineStyle, !parent.fakeNode());
            child._outgoingLines[parent.id] = line;
            line._setSelected = function(selected) {
              if (selected) {
                this.attr({"stroke": "#333"});
                this.data('bgLine').toFront();
                this.toFront();
              } else {
                this.attr({"stroke": "#bbb"});
                this.toBack();
                this.data('bgLine').toBack();

                if (this.data('lineStyle') == 'solid') {
                  // when we process selection event, we sort lines before calling _setSelected on them,
                  // but it is not enough because _setSelected won't be called for all lines outgoing from some child
                  // and this can result in placing dashed line on top of solid, so we need to additionally process dashed lines here
                  that._putDashedLinesToBack(child._outgoingLines);
                }
              }
            }
          }

          this._putDashedLinesToBack(child._outgoingLines);
        }
      }
    }
  };

  this._putDashedLinesToBack = function(lines) {
    for (var id in lines) {
      if (!lines.hasOwnProperty(id)) continue;
      var line = lines[id];
      if (line.data('lineStyle') == 'dashed') {
        line.toBack();
        line.data('bgLine').toBack();
      }
    }
  };

  this._computeGroupsMap = function(groups, parents, children) {
    var result = [];
    for (var i=0; i<parents.length; i++) {
      var p = parents[i];
      result[p.id] = [];
      for (var j=0; j<groups.length; j++) {
        if (groups[j].parents.indexOf(p) != -1) result[p.id].push(groups[j]);
      }
    }

    for (var i=0; i<children.length; i++) {
      var c = children[i];
      result[c.id] = [];
      for (var j=0; j<groups.length; j++) {
        if (groups[j].children.indexOf(c) != -1) result[c.id].push(groups[j]);
      }
    }

    return result;
  };

  this._attachEventHandlers = function() {
    var drawer = this;
    var nodes = this.graph.getNodes();
    for (var i=0; i<nodes.length; i++) {
      nodes[i].setSelected = function(selected, curNode, processed, direction, prevNode) {
        if (curNode == this) {
          if (selected) {
            drawer.selectedNodes[this.id] = true;
          } else {
            drawer.selectedNodes[this.id] = null;
          }
        }

        var depOnMe = this.getDependedOnMe();
        var deps = this.getDependencies();

        if (this == curNode) {
          for (var j=0; j<depOnMe.length; j++) {
            depOnMe[j].setSelected(selected, curNode, processed, 1, this);
          }

          for (var j=0; j<deps.length; j++) {
            deps[j].setSelected(selected, curNode, processed, -1, this);
          }
        } else if (!processed[this.id]) {
          processed[this.id] = true;

          var n = direction > 0 ? depOnMe : deps;

          for (var j=0; j<n.length; j++) {
            n[j].setSelected(selected, curNode, processed, direction, this);
          }
        }

        if (!selected) {
          this.elem.style.backgroundColor = "var(--ring-content-background-color, #fff)";
        } else {
          if (curNode == this) {
            this.elem.style.backgroundColor = "#ffffcc";
          } else {
            this.elem.style.backgroundColor = "var(--ring-line-color, #dfe5eb)";
          }
        }


        var from = [this];
        var to = direction < 0 ? [prevNode] : depOnMe;

        for (var j=0; j<from.length; j++) {
          var lines = [];
          for (var k=0; k<to.length; k++) {
            var line = from[j]._outgoingLines[to[k].id];
            if (line == null) continue;
            lines.push(line);
          }

          // we need to sort lines so that when lines are selected, we draw dashed lines first and then solid lines
          // in this case in places when two lines have common part, solid line will win
          lines.sort(function (l1, l2) {
            if (l1.data('lineStyle') == 'solid' && l2.data('lineStyle') == 'dashed') {
              return selected ? 1 : -1;
            }
            if (l1.data('lineStyle') == 'dashed' && l2.data('lineStyle') == 'solid') {
              return selected ? -1 : 1;
            }

            return 0;
          });

          for (var m=0; m<lines.length; m++) {
            line = lines[m];
            if (selected) line._setSelected(true);
            else line._setSelected(false);
          }
        }
      };

      nodes[i].elem.onclick = function(event) {
        // don't highlight when clicking react icon
        if ($j(event.target).closest('.js_stop-build').length > 0) {
          return;
        }
        var wasSelected = drawer.selectedNodes[this.id];
        drawer.unselectAll();
        this.setSelected(!wasSelected, this, {}, 0, this);
        BS.stopPropagation(event);
      }.bind(nodes[i]);

      nodes[i].setCurrent = function() {
        this.elem.style.border = "2px solid darkorange";
      }
    }
  };

  this._drawLines = function(points, lineStyle, withArrow) {
    var pathString = this.paths.absMove(points[0]);
    for (var i=1; i<points.length; i++) {
      var p = points[i];
      if (p) pathString += this.paths.absLine(p);
    }

    try {
      // A background line fixes various kinds of rendering artefacts
      var bgLine = this.paper.path(pathString);
      bgLine.attr({
        "stroke": "var(--ring-content-background-color, #fff)",
        "stroke-width": "1.5"
      });
      var line = this.paper.path(pathString);
      if (lineStyle === 'dashed') {
        line.attr({
          "stroke": "#bbb",
          "stroke-dasharray": ".",
          "stroke-width": "1.5"
        });
      } else {
        line.attr({
          "stroke": "#bbb",
          "stroke-width": "1.5"
        });
      }

      if (withArrow) {
        bgLine.attr('arrow-end', 'classic-wide-long');
        line.attr('arrow-end', 'classic-wide-long');
      }

      line.data('bgLine', bgLine);
      line.data('lineStyle', lineStyle);
      return line;
    } catch (e) {
      alert(pathString);
    }
  };

  this.hasSelectedNodes = function() {
    for (var id in this.selectedNodes) {
      if (!this.selectedNodes.hasOwnProperty(id)) continue;
      if (this.selectedNodes[id]) return true;
    }

    return false;
  };

  this.unselectAll = function() {
    for (var id in this.selectedNodes) {
      if (!this.selectedNodes.hasOwnProperty(id)) continue;
      if (this.selectedNodes[id]) {
        var curNode = this.graph.nodes[id];
        curNode.setSelected(false, curNode, [], 0, curNode);
      }
    }

    return false;
  }
};
