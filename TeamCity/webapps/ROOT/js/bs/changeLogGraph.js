(function ($) {
  BS.ChangeLogGraph = {
    graph: null,
    graphContainer: null,
    changesTableSelector: null,

    isSakuraUI: false,

    overlappingLineShift: 3,
    commitRadius: 4,
    buildRadius: 3,
    commitDiameter: 8,
    vOffsetFromRowTop: 10,
    hOffsetFromRowLeft: 10,
    spaceBetweenColumns: 10,
    spaceBetweenPositions: 15,
    collapseVcsRootAreaWidth: 8,

    selectedVertex: null,
    selectedVertexType: null,
    selectedVertexNode: null,
    selectedVertexPaths: [],
    selectedColumn: null,
    selectedColumnNode: null,

    columnsState: {
      collapsedColumnIds: {},
      block_type: 'vcsRootGraph',

      init: function() {
        var blocks = BS.Blocks._saved[this.block_type];
        if (!blocks) return;
        var savedArray = blocks.split(":");
        for (var i = 0; i < savedArray.length; i++) {
          if (savedArray[i] && savedArray[i] != 'null') {
            this.collapsedColumnIds[savedArray[i]] = true;
          }
        }
      },

      isCollapsed: function(column) {
        return column.maxWidth > 0 && !!this.collapsedColumnIds[column.id];
      },

      toggleCollapsed: function(column) {
        this.collapsedColumnIds[column.id] = !this.collapsedColumnIds[column.id];
        var saved = "";
        for(var i in this.collapsedColumnIds) {
          if (this.collapsedColumnIds[i]) {
            saved += i + ":";
          }
        }

        $.ajax(window['base_uri'] + "/ajax.html", {
          type: "POST",
          dataType: "xml",
          data: {
            blocksType: this.block_type,
            state: saved
          }
        });
      }
    },

    colors: {
      build_successful: '#71D458',
      build_failed: '#F23535',
      background: '#ebf6ff',
      border: '#DFDFDF',
      border_selected: '#BFCFE2',
      collapse_arrow: '#2F4F4F',
      collapse_background: '#DAECFD',
      collapse_background_selected: '#BFCFE2'
    },
    vcsRootColors : {}, // [key]: [r,g,b]

    // columnId -> its vertices' nodes
    columnVerticesNodes: {},

    setGraphData: function(graphData) {
      this.vcsRootColors = {};
      this.graph = graphData;

      if (this.graph != null) {
        for (var i = 0; i < this.graph.columns.length; i++) {
          var column = this.graph.columns[i];
          this.vcsRootColors[column.id] = ReactUI.getColorRgbByString(column.name)
        }
      }
    },

    getTrunkColor: function(columnId) {
      const color = this.vcsRootColors[columnId];
      return this.isSakuraUI ? 'rgb(' + color[0] + ', ' + color[1] + ', ' + color[2] + ')' : '#003366'
    },

    getTrunkFadedColor: function(columnId) {
      const color = this.vcsRootColors[columnId];
      return this.isSakuraUI ? 'rgba(' + color[0] + ', ' + color[1] + ', ' + color[2] + ', 0.3)' : '#7F99B3'
    },

    initGraph: function ({graphContainerSelector, graphToggleSelector, changesTableSelector, isSakuraUI}) {
      this.columnsState.init();

      this.graphContainerSelector = graphContainerSelector;
      this.graphToggleSelector = graphToggleSelector;
      this.changesTableSelector = changesTableSelector;

      if (isSakuraUI) {
        this.isSakuraUI = isSakuraUI;

        this.colors = Object.assign(this.colors, {
          background: 'transparent',
          border: 'transparent',
        });

        this.commitRadius = 3;
        this.commitDiameter = 6;
        this.spaceBetweenColumns = 0;
        this.spaceBetweenPositions = 8;
        this.vOffsetFromRowTop = 13;
        this.hOffsetFromRowLeft = 8;
        this.collapseVcsRootAreaWidth = 0
      }

      var self = this;
      _.once(function() {
        $(window).resize(function () {
          self.redrawGraph();
        });

        BS.LoadStyleSheetDynamically(window['base_uri'] + '/css/changeLog.css', function () {
          BS.LoadStyleSheetDynamically(window['base_uri'] + '/css/changeLogGraph.css', function () {
            self.redrawGraph();
          });
        });
      })();
    },

    isEmptyGraph: function () {
      return this.graph == null || this.graph.columns.length == 0;
    },

    redrawGraph: function () {
      this.columnVerticesNodes = {};

      var graphToggle = $(this.graphToggleSelector),
          graphContainer = $(this.graphContainerSelector);

      this.graphContainer = graphContainer;

      graphContainer.empty().css('width', 0);

      if (this.isEmptyGraph()) {
        graphContainer.parent('.graph-container').css('display', 'none');
        return;
      }

      if ((this.graphToggleSelector == null || graphToggle.prop('checked')) && !this.isEmptyGraph()) {
        this.drawGraph(this.graph);
        if (this.selectedVertexNode) {
          $('#' + this.selectedVertexNode.id).click();
        }
        if (this.selectedColumnNode) {
          $('#' + this.selectedColumnNode.id).click();
        }
      }
    },

    drawGraph: function (graph) {
      this.initGraphGeometry(graph);
      var paper = Raphael($(this.graphContainerSelector).get(0), graph.width, graph.height);
      for (var i = 0; i < graph.columns.length; i++) {
        this.drawColumn(paper, graph.columns[i]);
      }
    },

    initGraphGeometry: function (graph) {
      this.initGraphWidth(graph);
      this.graphContainer.width(graph.width - 5 + 'px').css({position: 'relative'});
      if (!this.isSakuraUI) {
        this.graphContainer.css({'left':'-10px'});
      }
      this.initGraphHeight(graph);
      this.initCommitOffsets(graph);
    },

    initGraphWidth: function (graph) {
      var totalWidth = 0;
      for (var i = 0; i < graph.columns.length; i++) {
        var width = (this.columnsState.isCollapsed(graph.columns[i]) ? 0 : graph.columns[i].maxWidth) * this.spaceBetweenPositions + 2 * this.hOffsetFromRowLeft;
        graph.columns[i].offsetX = totalWidth + this.spaceBetweenColumns;
        graph.columns[i].width = width + this.collapseVcsRootAreaWidth / 2;
        totalWidth = totalWidth + width + this.spaceBetweenColumns + this.collapseVcsRootAreaWidth / 2;
      }
      graph.width = totalWidth + 1;
    },

    initGraphHeight: function (graph) {
      var height = $(this.changesTableSelector).height();
      for (var i = 0; i < graph.columns.length; i++) {
        graph.columns[i].height = height;
      }
      graph.height = height;
    },

    initCommitOffsets: function (graph) {
      var tableOffset = $(this.changesTableSelector).offset()?.top ?? 0;
      for (var i = 0; i < graph.columns.length; i++) {
        var column = graph.columns[i];
        for (var j = 0, len = column.vertices.length; j < len; j++) {
          var commit = column.vertices[j];
          commit.offsetY = this.getVertexRow(commit).offset().top - tableOffset;
        }
      }
    },

    drawColumn: function (paper, column) {
      column.horizontalParts = [];
      this.drawColumnRect(paper, column);
      this.drawColumnCommits(paper, column);
      this.drawLinesFromPreviousPage(paper, column);
    },

    drawColumnRect: function (paper, column) {
      var rect = paper.rect(column.offsetX, 0, column.width, column.height, 4);
      rect.attr({title: column.name,
                  fill: this.colors.background,
                  stroke: this.colors.border,
                  cursor: 'pointer'});

      var $rectNode = $(rect.node);

      $rectNode.attr('id', 'column' + column.id).click(this.makeColumnClickHandler(paper, column));

      if (this.isSakuraUI) {
        $rectNode.mouseenter(this.columnMouseEnterHandler(paper, column));
        $rectNode.mouseleave(this.columnMouseLeaveHandler(paper, column));
      } else {
        this.initColumnTooltip($rectNode, column);
      }

      this.drawColumnCollapse(paper, column);
    },

    drawColumnCollapse: function(paper, column) {
      if (column.maxWidth == 0) {
        return;
      }
      var collapse = paper.rect(column.offsetX + column.width - this.collapseVcsRootAreaWidth, 0, this.collapseVcsRootAreaWidth, column.height, 4)
          .attr({fill: this.colors.collapse_background,
                 stroke: this.colors.background,
                 cursor: 'pointer'});

      var $collapse = $(collapse.node);
      $collapse.attr('id', 'column-collapse-' + column.id);
      var self = this;

      $collapse.mouseenter(function (event) {
        collapse.animate({fill: self.colors.collapse_background_selected}, 250);
        var iconYOffset = (event.offsetY + 30) > column.height ? column.height - 30 : event.offsetY + 30;
        var text = paper.text(column.offsetX + column.width - self.collapseVcsRootAreaWidth/2,
                              iconYOffset,
                              self.columnsState.isCollapsed(column) ? '\u25ba' : '\u25c4')
            .attr({fill: self.colors.collapse_background_selected});
        $(text.node).attr('id', 'column-collapse-arrow-' + column.id);
        text.animate({fill: self.colors.collapse_arrow}, 250);
      });

      $collapse.mouseleave(function () {
        $('#column-collapse-arrow-' + column.id).remove();
        collapse.animate({fill: self.colors.collapse_background}, 250);
      });

      $collapse.click(function() {
        self.columnsState.toggleCollapsed(column);
        self.redrawGraph();
      });
    },

    // We want to avoid showing the column tooltip right after hiding the commit tooltip
    blockColumnTooltip: false,
    blockColumnTooltipTimeout: null,

    graphTooltipInstance: function () {
      return this._graphTooltipInstance =
             this._graphTooltipInstance || $('<div class="graph-tooltip graph-tooltip_s graph-tooltip_hidden">' +
                                             '<div class="graph-tooltip__arrow graph-tooltip__arrow_s"></div>' +
                                             '<div class="graph-tooltip__inner"><span class="mono mono-12px"></span></div>' +
                                             '</div>');
    },

    initColumnTooltip: function ($rectNode, column) {
      var self = this;
      $rectNode.mouseenter(function () {
        if (self.blockColumnTooltip) return;

        var offset = $rectNode.offset();
        var tooltip = self.graphTooltipInstance();

        // Cleanup
        tooltip.addClass('graph-tooltip_hidden').removeClass('graph-tooltip_commit');

        // Create tooltip
        $rectNode.removeAttr('title');
        $rectNode.parent().removeAttr('title');
        tooltip.attr('id', 'tooltip-column-' + column.id);
        tooltip.find('.graph-tooltip__inner .mono').text(column.name);
        tooltip.appendTo(document.body);
        tooltip.css({left: offset.left - 6 + 'px', top: offset.top - tooltip.height() - 12 + 'px'});
        tooltip.addClass('graph-tooltip_column').removeClass('graph-tooltip_hidden');
      });

      $rectNode.mouseleave(function () {
        $('#tooltip-column-' + column.id).remove();
      });
    },

    initCommitTooltip: function($vertexNode, column, vertex) {
      var horizontalOffset = vertex.type === 'build' ? 12 : 11;
      var verticalOffset = vertex.type === 'build' ? 12 : 14;
      this.initTooltip($vertexNode, column, vertex.description, horizontalOffset, verticalOffset, 'tooltip-vertex-' + vertex.id);
    },

    initVcsRootBreakTooltip: function($breakPath, column) {
      this.initTooltip($breakPath, column, 'Vcs Root settings changed', 0, 14, 'tooltip-vcs-root-break-' + $breakPath.id);
    },

    initTooltip: function($node, column, title, horizontalOffset, verticalOffset, tooltipId) {
      var self = this;
      $node.mouseenter(_.throttle(function() {
        var position = $node.offset();
        var tooltip = self.graphTooltipInstance();

        // Cleanup
        tooltip.addClass('graph-tooltip_hidden').removeClass('graph-tooltip_column');

        // Create tooltip
        $node.removeAttr('title');
        $node.parent().removeAttr('title');
        tooltip.attr('id', tooltipId);
        tooltip.find('.graph-tooltip__inner .mono').text(title);
        tooltip.appendTo(document.body);
        tooltip.css({left: position.left - horizontalOffset + 'px', top: position.top - tooltip.height() - verticalOffset + 'px', zIndex: 3});
        tooltip.addClass('graph-tooltip_commit').removeClass('graph-tooltip_hidden');
      }, 500));

      $node.mouseleave(_.throttle(function() {
        $('#' + tooltipId).remove();

        self.blockColumnTooltip = true;

        window.clearTimeout(self.blockColumnTooltipTimeout);

        self.blockColumnTooltipTimeout = window.setTimeout(function() {
          self.blockColumnTooltip = false;
        }, 1000);
      }, 500));
    },

    drawColumnCommits: function (paper, column) {
      var drawnCommitIds = [];
      var drawnLinesCommitIds = [];
      var commit, commitIndex;
      for (var i = 0, len = column.startVertices.length; i < len; i++) {
        commitIndex = column.startVertices[i];
        commit = column.vertices[commitIndex];
        this.drawCommitAndItsAncestors(paper, column, commit, commitIndex, drawnCommitIds, drawnLinesCommitIds);
      }

      for (i = 0, len = column.vertices.length; i < len; i++) {
        commitIndex = i;
        commit = column.vertices[commitIndex];
        this.drawCommitAndItsAncestors(paper, column, commit, commitIndex, drawnCommitIds, drawnLinesCommitIds);
      }
    },

    drawCommitAndItsAncestors: function (paper, column, commit, commitIndex, drawnCommitIds, drawnLinesCommitIds) {
      var self = this;
      if (!drawnCommitIds[commit.id]) {
        this.depthFirstSearch(column, commit, commitIndex,
                              function (commit, commitIndex) {
                                if (!drawnCommitIds[commit.id]) {
                                  self.drawVertex(paper, column, commit, commitIndex);
                                  drawnCommitIds[commit.id] = 1;
                                  return true;
                                } else {
                                  return false;
                                }
                              },
                              function (commit, commitIndex) {
                                if (!drawnLinesCommitIds[commit.id]) {
                                  self.drawCommitLines(paper, column, commit, commitIndex);
                                  drawnLinesCommitIds[commit.id] = 1;
                                }
                              });
      }
    },

    drawLinesFromPreviousPage: function (paper, column) {
      if (this.columnsState.isCollapsed(column) && column.lines.length) {
        var path = this.drawLineFromPreviousPage(paper, column, [0, 0]);//draw a single line to the first vertex
        path.attr({'stroke-dasharray': '. '});
      } else {
        for (var i = 0; i < column.lines.length; i++) {
          this.drawLineFromPreviousPage(paper, column, column.lines[i]);
        }
      }
    },

    drawLineFromPreviousPage: function (paper, column, line) {
      var pathOffsets = this.getLineSegmentOffsets(line, column.vertices, column, true);
      var path = paper.path(this.getPathSpec(column, pathOffsets));
      path.attr({stroke: this.getTrunkColor(column.id)});
      return path;
    },

    drawVertex: function (paper, column, vertex, vertexIndex) {
      var vertexRaphaelObj;
      if (vertex.type === 'commit') {
        vertexRaphaelObj = this.drawCommit(paper, column, vertex);
      } else {
        vertexRaphaelObj = this.drawBuild(paper, column, vertex);
      }

      if (!this.columnVerticesNodes[column.id]) {
        this.columnVerticesNodes[column.id] = [];
      }

      if (this.columnVerticesNodes[column.id].indexOf(vertexRaphaelObj.node) == -1) {
        this.columnVerticesNodes[column.id].push(vertexRaphaelObj.node);
      }

      var $vertexNode = $(vertexRaphaelObj.node);
      $vertexNode.attr('id', vertex.type + vertex.id);
      $vertexNode.click(this.makeVertexClickHandler(paper, column, vertex, vertexIndex));
      // Visual feedback on hover
      $vertexNode.mouseenter(this.getVertexMouseEnterHandler(paper, column, vertex, vertexRaphaelObj));
      $vertexNode.mouseleave(this.getVertexMouseLeaveHandler(paper, column, vertex, vertexRaphaelObj));

      if (this.isSakuraUI) {
        $vertexNode.mouseenter(this.columnMouseEnterHandler(paper, column));
        $vertexNode.mouseleave(this.columnMouseLeaveHandler(paper, column));
      }
      // Commit node tooltip
      this.initCommitTooltip($vertexNode, column, vertex);
    },

    drawCommit: function(paper, column, commit) {
      var commitCenterX = this.getOffsetX(column, commit.position),
          commitCenterY = this.getOffsetY(commit),
          columnColor = this.getTrunkColor(column.id);

      var commitCircle = paper.circle(commitCenterX, commitCenterY, this.commitRadius);
      commitCircle.attr({fill: columnColor,
                          stroke: columnColor,
                          cursor: 'pointer'});
      commitCircle.node.setAttribute('data-type', 'commit');

      if (commit.last) {
        this.drawVcsRootBorder(paper, column, commit, commitCenterY);
      }

      return commitCircle;
    },

    drawVcsRootBorder: function(paper, column, commit, commitCenterY) {
      var lineY = commitCenterY + 10;
      var lineStartX = column.offsetX;
      var lineFinishX = column.offsetX + column.width;
      var pathSpec = [];
      pathSpec.push("M" + (lineStartX + ", " + lineY));
      var up = true;
      for (var i = lineStartX + 3; i < lineFinishX; i += 5) {
        pathSpec.push("L" + (i + ", " + (lineY + (up ? -2 : 2))));
        up = !up;
      }
      paper.path(pathSpec.join('')).attr({stroke: 'red'});
      var rect = paper.rect(lineStartX, lineY - 3, column.width, 6, 1);//show tooltip over rectangle, it is hard to place cursor over 1px border line
      rect.attr({opacity: 0});
      var $rect = $(rect.node);
      $rect.attr('id', 'vcs-root-break' + commit.id);
      this.initVcsRootBreakTooltip($rect, column);
    },

    drawBuild: function (paper, column, vertex) {
      var commitCenterX = this.getOffsetX(column, vertex.position),
          commitCenterY = this.getOffsetY(vertex);

      var color = vertex.status === 'success' ? this.colors.build_successful : this.colors.build_failed;

      var buildCircle = paper.circle(commitCenterX, commitCenterY, this.buildRadius);
      if (this.isSakuraUI) {
        color = this.getTrunkColor(column.id);
        buildCircle.attr({fill: 'white',
          stroke: color,
          strokeWidth: '1px',
          cursor: 'pointer'});
      } else {
        buildCircle.attr({fill: color,
          stroke: color,
          cursor: 'pointer'});
      }
      buildCircle.node.setAttribute('data-type', 'build');
      buildCircle.node.setAttribute('data-status', vertex.status);

      return buildCircle;
    },

    getVertexMouseEnterHandler: function (paper, column, vertex, vertexRaphaelObj) {
      var self = this;
      if (vertex.type === 'commit') {
        return _.throttle(function () {
          if (self.selectedVertexNode != vertexRaphaelObj.node) {
            vertexRaphaelObj.animate({r: self.commitRadius * 1.3}, 250);
          }
          self.showSubrepoLinks(paper, column, vertex, '-sub-mouseover-', 1);

          if (self.isSakuraUI) {
            self.getVertexRow(vertex).attr('data-hovered', true)
          }
        }, 500);
      } else {
        return function() {
          if (vertex.type === 'build' && self.isSakuraUI) {
            self.getVertexRow(vertex).attr('data-hovered', true)
          }
        }
      }
    },

    getVertexMouseLeaveHandler: function (paper, column, vertex, vertexRaphaelObj) {
      var self = this;
      if (vertex.type === 'commit') {
        return _.throttle(function () {
          if (self.selectedVertexNode != vertexRaphaelObj.node) {
            vertexRaphaelObj.animate({r: self.commitRadius}, 250);
          }
          $('[id|="' + vertex.id + '-sub-mouseover"]').remove();

          if (self.isSakuraUI) {
            self.getVertexRow(vertex).attr('data-hovered', false)
          }
        }, 500);
      } else {
        return function() {
          if (vertex.type === 'build' && self.isSakuraUI) {
            self.getVertexRow(vertex).attr('data-hovered', false)
          }
        }
      }
    },

    drawCommitLines: function (paper, column, commit, commitIndex) {
      commit.paths = [];
      if (this.columnsState.isCollapsed(column) && !commit.last) {
        this.drawCommitLine(paper, column, commit, [0, 0], commitIndex);//draw a single line to the next vertex
      } else {
        for (var i = 0; i < commit.lines.length; i++) {
          this.drawCommitLine(paper, column, commit, commit.lines[i], commitIndex);
        }
      }
    },

    drawCommitLine: function (paper, column, commit, line, commitIndex) {
      var subsequentCommits = column.vertices.slice(commitIndex);
      var pathOffsets = this.getLineSegmentOffsets(line, subsequentCommits, column);
      var path = paper.path(this.getPathSpec(column, pathOffsets));
      path.attr({stroke: this.getTrunkColor(column.id)});
      $(path.node).attr('pointer-events', 'fill');
      if (this.columnsState.isCollapsed(column)) {
        path.attr({'stroke-dasharray': '. '});
      }
      commit.paths.push(path);
    },

    getLineSegmentOffsets: function (line, commitsInColumn, column, startFromTheTop) {
      var positionIdx = 0, commitIdx,
          lineLength = line.length,
          position,
          lastX,
          y,
          result = [];

      if (startFromTheTop) {
        position = line[0];
        result.push({x: this.getOffsetX(column, position),
                     y: 0});
        positionIdx = 1;
      }
      for (commitIdx = 0; positionIdx < lineLength; positionIdx++, commitIdx++) {
        position = line[positionIdx];
        if (commitsInColumn[commitIdx]) {
          if (positionIdx == lineLength - 1) {
            y = commitsInColumn[commitIdx].offsetY + this.vOffsetFromRowTop;
          } else {
            y = commitsInColumn[commitIdx].offsetY + this.vOffsetFromRowTop + this.commitDiameter;
          }
          result.push({x: this.getOffsetX(column, position),
                       y: y});
        }
      }
      if (commitsInColumn.length < lineLength) {
        //This happens when
        //1. a line from commit goes to the next page
        //2. a line from the previous page goes to the next page
        //3. a line from the previous page goes to the last commit in the column
        //In first two cases we should stretch a line to the end of the column.
        //In the latter case - we should not, otherwise will draw a line over
        //node and have it crossed, like in TW-23356.

        var lastCommitPosition = this.columnsState.isCollapsed(column) ? 0 : commitsInColumn[commitsInColumn.length - 1].position;
        if (startFromTheTop && //line from prev page
            lineLength == commitsInColumn.length + 1 && line[lineLength - 1] == lastCommitPosition) { //goes to the last commit on the page
          //don't add the last segment
        } else {
          lastX = line[commitsInColumn.length] ? this.getOffsetX(column, line[commitsInColumn.length]) : result[result.length - 1].x;
          result.push({x: lastX,
                       y: column.height});
        }
      }
      return result;
    },

    getOffsetX: function (column, position) {
      if (this.columnsState.isCollapsed(column)) {
        return column.offsetX + this.hOffsetFromRowLeft;
      } else {
        return column.offsetX + this.hOffsetFromRowLeft + position * this.spaceBetweenPositions;
      }
    },

    getOffsetY: function(vertex) {
      return vertex.offsetY + this.vOffsetFromRowTop + this.commitRadius;
    },

    getPathSpec: function (column, points) {
      var i,
          len = points.length,
          point,
          x, y,
          prevX = null, prevY, prevPrevY,
          horizontals,
          pathSpec = [],
          bendHeight,
          bendOffsetX,
          bendOffsetY;
      for (i = 0; i < len; i++) {
        bendHeight = 16;
        bendOffsetX = 2;
        bendOffsetY = 8;
        point = points[i];
        x = point.x;
        y = point.y;
        horizontals = [];
        if (prevX !== null) {
          if (x === prevX) {
            pathSpec.push("L" + (x + ", " + y));
          } else if (x > prevX) {
            pathSpec.push("C" + (prevX + ", " + (prevY + bendOffsetY)) +
                          " " + ((x - bendOffsetX) + ", " + (prevY + bendHeight - bendOffsetY)) +
                          " " + (x + ", " + (prevY + bendHeight)) +
                          "L" + (x + ", " + y));
          } else {
            if ((prevX - x) / this.spaceBetweenColumns > 5) {
              bendOffsetY = 15;
              bendOffsetX = 10;
            }
            pathSpec.push("C" + (prevX + ", " + (prevY + bendOffsetY)) +
                          " " + (x + ", " + (prevY + bendHeight - bendOffsetY)) +
                          " " + (x + ", " + (prevY + bendHeight)) +
                          "L" + (x + ", " + y));
          }
        } else {
          pathSpec.push("M" + (x + ", " + y));
        }
        prevPrevY = prevY;
        prevX = x;
        prevY = y;
      }
      return pathSpec.join('');
    },

    getVertexRow: function (vertex) {
      return this.isSakuraUI ? $(`[data-graph-id=${this.getVertexRowId(vertex)}]`) :  $('#' + this.getVertexRowId(vertex));
    },

    getVertexRowId: function (vertex) {
      if (vertex.type === 'commit') {
        return 'tr-mod-' + vertex.id;
      } else {
        var buildId = vertex.id.substring(0, vertex.id.indexOf('_'));
        return 'tr-build-' + buildId;
      }
    },

    getVertexRows: function () {
      if (this.isSakuraUI) {
        return $(this.changesTableSelector).find('div').filter('[data-graph-id|=tr-mod], [data-graph-id|=tr-build]');
      }
      return $(this.changesTableSelector).find('tr').filter('[id|=tr-mod], [id|=tr-build]');
    },

    makeColumnClickHandler: function (paper, column) {
      var self = this;
      return function () {
        var oldSelectedColumn = self.selectedColumnNode;
        self.restoreDefaultGraphView();
        if (this !== oldSelectedColumn) {// 'this' is bound to the column rect node
          self.selectedColumnNode = this;
          self.selectedColumn = column;
          self.highlightSelectedColumn();
          self.highlightSelectedColumnModifications();
        }
      };
    },

    columnMouseEnterHandler: function (paper, column) {
      var self = this;
      return function () {
        $('#column' + column.id).attr({'fill-opacity': 0.1, fill: self.getTrunkColor(column.id)});
      };
    },

    columnMouseLeaveHandler: function (paper, column) {
      var self = this;
      return function () {
        $('#column' + column.id).attr({'fill-opacity': 0, fill: self.getTrunkColor(column.id)});
      };
    },

    highlightSelectedColumn: function () {
      if (this.selectedColumn) {
        for (var i = 0; i < this.graph.columns.length; i++) {
          var column = this.graph.columns[i];
          if (column != this.selectedColumn) {
            if (this.isSakuraUI) {
              column.vertices.forEach(item => {
                item.paths.forEach(path => {
                  path.node.setAttribute('stroke', this.getTrunkFadedColor(column.id))
                })
              })
            } else {
              $('#column' + column.id).attr('opacity', 0.5);
              $('#column-collapse-' + column.id).attr('opacity', 0.5);
            }
            this.fadeVertices(column.id);
          } else {
            this.resetFadedVertices(column.id);
          }
        }
        this.selectedColumnNode.setAttribute('stroke-width', 2);
        this.selectedColumnNode.setAttribute('stroke', this.colors.border_selected);
      }
    },

    resetSelectedColumn: function () {
      for (var i = 0; i < this.graph.columns.length; i++) {
        var column = this.graph.columns[i];
        if (this.isSakuraUI) {
          column.vertices.forEach(item => {
            item.paths.forEach(path => {
              path.node.setAttribute('stroke', this.getTrunkColor(column.id))
            })
          })
        } else {
          $('#column' + column.id).attr('opacity', 1);
          $('#column-collapse-' + column.id).attr('opacity', 1);
        }
      }

      if (this.selectedColumnNode) {
        this.selectedColumnNode.setAttribute('stroke-width', 1);
        this.selectedColumnNode.setAttribute('stroke', this.colors.border);
        this.selectedColumnNode = null;
        this.selectedVertexType = null;
      }

      this.resetFadedVertices();
    },

    highlightSelectedColumnModifications: function () {
      if (this.selectedColumn) {
        var rowIds = [];
        for (var i = 0, len = this.selectedColumn.vertices.length; i < len; i++) {
          var commit = this.selectedColumn.vertices[i];
          rowIds[this.getVertexRowId(commit)] = 1;
        }
        this.highlightModificationRows(rowIds);
      }
    },

    highlightModificationRows: function (rowIds) {
      var self = this;
      this.getVertexRows().each(function (index, el) {
        var id = self.isSakuraUI ? $(el).attr('data-graph-id') : el.id;
        if (!rowIds[id]) {
          $(el).attr('data-faded', true).css("opacity", 0.25);
        }
      });
    },

    resetHighlightedModificationRows: function () {
      this.getVertexRows().each(function (index, el) {
        $(el).attr('data-faded', false).css("opacity", 1);
      });
    },

    fadeVertices: function (columnId) {
      var vertexNode,
          i;

      if (this.columnVerticesNodes[columnId]) {
        for (i = 0; i < this.columnVerticesNodes[columnId].length; i++) {
          vertexNode = this.columnVerticesNodes[columnId][i];
          this.setVertexStyle(columnId, vertexNode, 'faded');
        }
      }
    },

    resetFadedVertices: function (columnId) {
      var vertexNode,
          i;

      if (columnId) {
        if (this.columnVerticesNodes[columnId]) {
          for (i = 0; i < this.columnVerticesNodes[columnId].length; i++) {
            vertexNode = this.columnVerticesNodes[columnId][i];
            this.setVertexStyle(columnId, vertexNode, 'normal');
          }
        }
      } else {
        for (var column in this.columnVerticesNodes) {
          if (this.columnVerticesNodes[column]) {
            for (i = 0; i < this.columnVerticesNodes[column].length; i++) {
              vertexNode = this.columnVerticesNodes[column][i];
              this.setVertexStyle(column, vertexNode, 'normal');
            }
          }
        }
      }
    },

    setVertexStyle: function (columnId, vertexNode, style) {
      var vertexType = vertexNode.getAttribute('data-type');
      var vertexColor;

      if (style == 'faded') {
        vertexColor = this.getTrunkFadedColor(columnId);
      } else if (style == 'normal') {
        vertexColor = this.getTrunkColor(columnId);
      }

      if (vertexType == 'commit') {
        vertexNode.setAttribute('fill', vertexColor);
        vertexNode.setAttribute('stroke', vertexColor);
      } else if (vertexType == 'build' && this.isSakuraUI) {
        vertexNode.setAttribute('stroke', vertexColor);
      }
    },

    makeVertexClickHandler: function (paper, column, vertex, vertexIndex) {
      var self = this;
      return function () {
        var oldSelectedVertexNode = self.selectedVertexNode;
        self.restoreDefaultGraphView();
        if (this !== oldSelectedVertexNode) {// 'this' is bound to the vertex node
          self.selectedVertexPaths = [];

          self.selectedVertex = vertex;
          self.selectedVertexType = vertex.type;
          self.selectedVertexNode = this;

          var rowIds = [];
          var handledSubrepos = [];
          $('[id*="-sub-reachable-"]').remove();
          self.highlightReachableNodes(paper, column, vertex, vertexIndex, rowIds, handledSubrepos);

          self.highlightSelectedCommits();
          self.highlightModificationRows(rowIds);
        }
      };
    },

    highlightReachableNodes: function (paper, column, vertex, vertexIndex, rowIds, handledSubrepoColumns) {
      var self = this;
      this.depthFirstSearch(column, vertex, vertexIndex, function (commit) {
        rowIds[self.getVertexRowId(commit)] = 1;
        for (var i = 0, len = commit.paths.length; i < len; i++) {
          self.selectedVertexPaths.push(commit.paths[i]);
        }

        var filter = function(subrepo_column_id) {//ensure we show links to each subrepo only once
          return !handledSubrepoColumns[subrepo_column_id];
        };

        var action = function(paper, subrepo_column, subrepo_commit, subrepo_commit_index) {//highlights nodes in subrepo column
          handledSubrepoColumns[subrepo_column.id] = true;
          if (subrepo_commit != null && subrepo_commit_index != null) {
            self.highlightReachableNodes(paper, subrepo_column, subrepo_commit, subrepo_commit_index, rowIds, handledSubrepoColumns);
          }
        };

        self.showSubrepoLinks(paper, column, commit, '-sub-reachable-', 2, filter, action);

        return true;
      });
    },

    showSubrepoLinks: function(paper, column, commit, idInfix, strokeWidth, subrepoColumnFilter, afterAction) {
      if (!commit.subrepos) {
        return;
      }
      var mainRepoCommitCenterX = this.getOffsetX(column, commit.position),
          mainRepoCommitCenterY = this.getOffsetY(commit);
      for (var i = 0, len = commit.subrepos.length; i < len; i++) {
        var subrepo_column_id = commit.subrepos[i].column_id;
        if (subrepoColumnFilter && !subrepoColumnFilter(subrepo_column_id)) {
          continue;
        }

        var subrepo_column = this.findColumn(subrepo_column_id);
        if (!subrepo_column) {// no changes in this subrepo on the page
          continue;
        }

        var subrepo_vertex_and_index = this.findVertex(subrepo_column, commit.subrepos[i].mod_id);
        var submoduleCommitCenterX,
            submoduleCommitCenterY;
        var middleX = subrepo_column.offsetX - 5;
        var pathToSubmoduleCommit;
        var bendOffsetY = 30;
        var columnColor = this.getTrunkColor(column.id);
        if (subrepo_vertex_and_index) {
          var subrepo_commit = subrepo_vertex_and_index[0];
          var subrepo_commit_index = subrepo_vertex_and_index[1];

          if (!$('#' + commit.id + '-sub-reachable-' + subrepo_column_id).length) {//if no links already shown
            submoduleCommitCenterX = this.getOffsetX(subrepo_column, subrepo_commit.position);
            submoduleCommitCenterY = this.getOffsetY(subrepo_commit);

            if ((submoduleCommitCenterY - mainRepoCommitCenterY) > 100) {
              pathToSubmoduleCommit = paper.path("M" + mainRepoCommitCenterX + ", " + mainRepoCommitCenterY +
                                                 "Q" + middleX + ", " + mainRepoCommitCenterY + " " + middleX + ", " + (mainRepoCommitCenterY + bendOffsetY) +
                                                 "L" + middleX + ", " + (submoduleCommitCenterY - bendOffsetY) +
                                                 "Q" + middleX + ", " + submoduleCommitCenterY + " " + submoduleCommitCenterX + ", " + submoduleCommitCenterY);
            } else {
              pathToSubmoduleCommit = paper.path("M" + mainRepoCommitCenterX + ", " + mainRepoCommitCenterY +
                                                 "Q" + submoduleCommitCenterX + ", " + mainRepoCommitCenterY + " " + submoduleCommitCenterX + ", " + submoduleCommitCenterY);
            }
            pathToSubmoduleCommit.attr({stroke: columnColor, 'stroke-dasharray': '--'});
            pathToSubmoduleCommit.node.setAttribute('stroke-width', strokeWidth);
            pathToSubmoduleCommit.node.setAttribute('id', commit.id + idInfix + subrepo_column_id);

            if (afterAction) {
              afterAction(paper, subrepo_column, subrepo_commit, subrepo_commit_index);
            }
          }
        } else {
          //column found, but commit is on the next page, draw line to the end
          submoduleCommitCenterY = mainRepoCommitCenterY + bendOffsetY;
          pathToSubmoduleCommit = paper.path("M" + mainRepoCommitCenterX + ", " + mainRepoCommitCenterY +
                                             "Q" + middleX + ", " + mainRepoCommitCenterY + " " + middleX + ", " + submoduleCommitCenterY +
                                             "L" + middleX + ", " + this.graph.height);
          pathToSubmoduleCommit.attr({stroke: columnColor, 'stroke-dasharray': '--'});
          pathToSubmoduleCommit.node.setAttribute('stroke-width', strokeWidth);
          pathToSubmoduleCommit.node.setAttribute('id', commit.id + idInfix + subrepo_column_id);

          if (afterAction) {
            afterAction(paper, subrepo_column, subrepo_commit, subrepo_commit_index);
          }
        }
      }
    },

    findColumn: function (columnId) {
      for (var i = 0, len = this.graph.columns.length; i < len; i++) {
        var column = this.graph.columns[i];
        if (column.id == columnId) {
          return column;
        }
      }
      return null;
    },

    //returns pair: vertex and its index in column, or null if nothing found
    findVertex: function (column, vertex_id) {
      var vertex;
      for (var i = 0, len = column.vertices.length; i < len; i++) {
        vertex = column.vertices[i];
        if (vertex.id == vertex_id) {
          return [vertex, i];
        }
      }
      return null;
    },

    depthFirstSearch: function (column, commit, commitIndex, discoverCommitCallback, finishProcessingCommitCallback) {
      var stack = [commit],
          commitIndices = [],
          i, len,
          white = 0, grey = 1, black = 2, colors = [];

      commitIndices[commit.id] = commitIndex;

      var getColor = function (commitModId) {
        var color = colors[commitModId];
        if (!color) {
          color = white;
          setColor(commitModId, color);
        }
        return color;
      };

      var setColor = function (commitModId, color) {
        colors[commitModId] = color;
      };

      var finishCallback = finishProcessingCommitCallback || function (c, index) {
      };

      while (stack.length > 0) {
        var c = stack[stack.length - 1];
        var commitModId = c.id;
        var cIndex = commitIndices[commitModId];
        var color = getColor(commitModId);
        if (color == white) {
          setColor(commitModId, grey);
          if (discoverCommitCallback(c, commitIndices[commitModId])) {
            for (len = c.parents.length, i = len - 1; i >= 0; i--) {
              var parentIndex = cIndex + c.parents[i];
              var parent = column.vertices[parentIndex];
              if (parent) {
                var parentModId = parent.id;
                var parentColor = getColor(parentModId);
                if (parentColor == white) {
                  stack.push(parent);
                  commitIndices[parentModId] = parentIndex;
                } else if (parentColor == grey) {
                  BS.Log.error('Found cicle in the graph');
                }
              }
            }
          }
        } else if (color == grey) {
          stack.pop();
          setColor(commitModId, black);
          finishCallback(c, cIndex);
        } else {
          stack.pop();
        }
      }
    },

    restoreDefaultGraphView: function () {
      this.resetSelectedColumn();
      this.resetHighlightedModificationRows();
      if (this.selectedVertexNode) {
        this.restoreUnselectedVertex();
        this.getVertexRow(this.selectedVertex).removeClass('selectedCommitRow');
      }
      $("path", this.graphContainer).each(function () {
        this.setAttribute('stroke-opacity', 1);
        this.setAttribute('stroke-width', 1);
      });
      $('[id*="-sub-reachable-"]').remove();
      this.selectedVertex = null;
      this.selectedVertexNode = null;
      this.selectedVertexPaths = [];
    },

    highlightSelectedCommits: function () {
      if (this.selectedVertexNode) {
        $("path:not([id^='build'])", this.graphContainer).each(function () {
          this.setAttribute('stroke-opacity', 0.5);
        });
        this.getVertexRow(this.selectedVertex).addClass('selectedCommitRow');
        this.highlightSelectedVertex();
        var paths = this.selectedVertexPaths;
        for (var i = 0, len = paths.length; i < len; i++) {
          var node = paths[i].node;
          node.setAttribute('stroke-opacity', 1);
          node.setAttribute('stroke-width', 2);
        }
      }
    },

    highlightSelectedVertex: function () {
      if (this.selectedVertexType === 'commit') {
        this.selectedVertexNode.setAttribute('r', 1.25 * this.commitRadius);
      } else {
        this.selectedVertexNode.setAttribute('stroke-width', 3);
      }
    },

    restoreUnselectedVertex: function () {
      if (this.selectedVertexType === 'commit') {
        this.selectedVertexNode.setAttribute('r', this.commitRadius);
      } else {
        this.selectedVertexNode.setAttribute('stroke-width', 1);
      }
    }
  };
})(jQuery);
