(function ($) {
  BS.DiffView = {
    //[*[0-lCount, 1-lStart, 2-rCount, 3-rStart, 4-addedEmptyLines, 5-lastLine]]
    changes: [],
    cc: 0,

    pageUrl: "",
    loadingMessage: "",
    fileName: "",
    beforeLines: 0,
    addedLines: 0,
    finalLines: 0,

    RTL: false,
    EXPANDER: ("<br />&nbsp;"),

    width: 0,
    height: 0,
    mapWidth: 55,
    lineHeight: 0,
    scrollHeightKnown: false,
    unsyncedScrollBeforeCount: 0,
    unsyncedScrollAfterCount: 0,

    init: function () {
      this.$window = $(window);
      this.diffView = $('#diffView');
      this.status = $("#status");
      this.panels = $("#panels");
      this.dbefore = $("#dbefore");
      this.tbefore = $("#tbefore");
      this.dafter = $("#dafter");
      this.tafter = $("#tafter");
      this.toolbar = $("#toolbar");
      this.toolbarBefore = this.toolbar.find(".column-before");
      this.toolbarAfter = this.toolbar.find(".column-after");
      this.toolbarTools = this.toolbar.find(".column-tools");
      this.dmap = $("#dmap");
      this.mapWindow = $("#mapWindow");
      this.panels = $("#panels");

      this.status.html(this.loadingMessage);
      this.sourceDiff();
      this.initClipboard();
      this.$window.resize(_.bind(this.doResize, this));
    },

    getLanguage: function() {
      var filetypeMap = {
        'as': 'actionscript',
        'sh': 'bash',
        'coffee': 'coffeescript',
        'cpp': 'cpp',
        'hpp': 'cpp',
        'cs': 'cs',
        'css': 'css',
        'clj': 'clojure',
        'erl': 'erlang',
        'go': 'go',
        'scss': 'scss',
        'js': 'javascript',
        'json': 'json',
        'kt': 'kotlin',
        'm': 'objectivec',
        'md': 'markdown',
        'pl': 'perl',
        'pm': 'perl',
        'php': 'php',
        'py': 'python',
        'rb': 'ruby',
        'rs': 'rust',
        'scala': 'scala',
        'sql': 'sql',
        'ant': 'xml',
        'fxml': 'xml',
        'iml': 'xml',
        'jhm': 'xml',
        'jnlp': 'xml',
        'ps1': 'powershell',
        'pom': 'xml',
        'rng': 'xml',
        'svg': 'xml',
        'tld': 'xml',
        'wsdl': 'xml',
        'xml': 'xml',
        'xsl': 'xml',
        'xslt': 'xml',
        'xul': 'xml'
      };

      var filename = BS.DiffView.fileName;
      var filetype = filename.match(/\.(\w+)$/);

      filetype = filetype && filetype.length > 0 ? filetype[1] : null;

      return filetype && filetypeMap[filetype] || null;
    },


    sourceDiff: function () {
      this.status.addClass('hidden');
      this.doResize();
      this.toolbar.removeClass('invisible');
      this.panels.removeClass('invisible');
      this.setupPanelsScrolling();

      var highlightBlocks = $('.needsHighlight');
      var language = BS.DiffView.getLanguage();

      highlightBlocks.each(function () {
        var plainContent = $('#' + this.id + 'Plain');
        var lines = plainContent.val().split('\n');
        if (lines.length > 2500) {
          BS.Log.info('File size is too large, highlighting will not be performed');
          return;
        }

        var highlighted = language ? hljs.highlight(language, plainContent.val(), true) : hljs.highlightAuto(plainContent.val());
        var highlightedLines = highlighted.value.split('\n');

        BS.Log.info('Detected language: ' + highlighted.language);

        $(this).find('li').each(function (i) {
          this.innerHTML = highlightedLines[i] || '&nbsp;';
        });
      });

      this.setLineHeight();

      if (this.changes.length > 0) {
        this.highlightChanges();
        this.buildChangeMiniMap();
        this.scrollToChange();
        this.setupMapWindowHeight();
        this.setupMapWindowDrag();
      } else {
        //no changes
        this.mapWindow.addClass('hidden');
      }
    },

    setupMapWindowDrag: function() {
      var that = this;
      var delta = 0;

      const mouseMoveHandler = function(e) {
        var totalHeight = that.dmap.get(0).offsetHeight - that.mapWindow.get(0).offsetHeight;
        var targetMapWindowPos = e.clientY - that.topOffset() - delta;
        var targetPercent = targetMapWindowPos / totalHeight;
        var scrollTopMax = that.dbefore.get(0).scrollHeight - that.dbefore.get(0).offsetHeight;
        var newScrollTop = scrollTopMax * targetPercent;

        that.dbefore.scrollTop(newScrollTop);
        that.dafter.scrollTop(newScrollTop);
      };

      const cleanupHandler = function (e) {
        that.dbefore.css('userSelect', '');
        that.dafter.css('userSelect', '');

        document.removeEventListener('mousemove', mouseMoveHandler);
        document.removeEventListener('mouseup', cleanupHandler);
        that.panels.off('mouseleave', cleanupHandler);
      };

      this.mapWindow.on('mousedown', function(e) {
        var rect = that.mapWindow[0].getBoundingClientRect();
        delta = e.clientY - rect.y;

        that.dbefore.css('userSelect', 'none');
        that.dafter.css('userSelect', 'none');

        document.addEventListener('mousemove', mouseMoveHandler);
        document.addEventListener('mouseup', cleanupHandler);
        that.panels.on('mouseleave', cleanupHandler);
      });
    },

    highlightChanges: function () {
      var changes = this.changes;
      var j;

      for (var i = 0; i < changes.length; i++) {
        changes[i][4] = changes[i][0];

        for (j = 0; j < changes[i][0]; j++) {
          $("#l_l_" + (changes[i][1] + j + 1)).addClass('changeRemoved');
        }

        for (j = 0; j < changes[i][2]; j++) {
          $("#r_l_" + (changes[i][3] + j + 1)).addClass('changeAdded');
        }

        var d = changes[i][2] - changes[i][0];
        if (d > 0) {
          for (j = 0; j < d; j++) {
            $("#l_l_" + (changes[i][1] + changes[i][0])).append(this.EXPANDER);
            this.addedLines++;
            changes[i][4]++;
          }
        } else if (d < 0) {
          for (j = 0; j < -d; j++) {
            $("#r_l_" + (changes[i][3] + changes[i][2])).append(this.EXPANDER);
          }
        }
        changes[i][5] = changes[i][3] + this.addedLines;
      }
      this.finalLines = this.beforeLines + this.addedLines;
    },

    buildChangeMiniMap: function () {
      var changes = this.changes;
      var tmpContainer = document.createDocumentFragment();
      var change;
      for (var i = 0; i < changes.length; i++) {
        var t = ($("#l_l_" + changes[i][1]).get(0).offsetTop / ((this.finalLines - 1) * this.getLineHeight()) * 100).toFixed(2);
        var h = (changes[i][4] / this.finalLines * 100 + .5).toFixed(2);

        t += "%";
        h += "%";

        if (changes[i][0] > 0) {
          change = $('<div class="changeL"/>');
          change.css('top', t);
          if (parseInt(h, 10) > 0) {
            change.css('height', h);
          }
          change.attr('title', 'Change #' + (i + 1));
          change.attr('i', i);
          change.appendTo(tmpContainer);
        }
        if (changes[i][2] > 0) {
          change = $('<div class="changeR"/>');
          change.css('top', t);
          if (parseInt(h, 10) > 0) {
            change.css('height', h);
          }
          change.attr('title', 'Change #' + (i + 1));
          change.attr('i', i);
          change.appendTo(tmpContainer);
        }
      }

      this.dmap.append(tmpContainer);

      var that = this;
      this.dmap.on('click', '.changeL, .changeR', function () {
        that.cc = parseInt(this.getAttribute("i"), 10);
        that.scrollToChange();
      });
    },

    scrollToChange: function () {
      if (this.changes.length > 0) {
        var scrollTop = $("#l_l_" + this.changes[this.cc][1]).get(0).offsetTop - this.getLineHeight();
        this.dbefore.scrollTop(scrollTop);
        this.dbefore.scrollLeft(0);
        this.dafter.scrollTop(scrollTop);
        this.dafter.scrollLeft(0);
      }
    },

    topOffset: function() {
      return this._topOffset = this._topOffset || this.diffView.outerHeight() + this.toolbar.outerHeight();
    },

    setupMapWindowHeight: function () {
      var mapWindowHeight = (this.height * 100 / (this.finalLines * this.getLineHeight())).toFixed(2);
      if (mapWindowHeight > 0) {
        mapWindowHeight > 100 ?
          this.mapWindow.addClass('hidden') :
          this.mapWindow.removeClass('hidden') && this.mapWindow.css('height', mapWindowHeight + "%");
      }
    },

    scrollPanels: function (evt) {
      var before = this.dbefore.get(0),
          after = this.dafter.get(0),
          isScrollSyncRequired = false,
          isRTL = false;

      if (evt.target === before) {
        if (this.unsyncedScrollBeforeCount > 0) {
          this.unsyncedScrollBeforeCount--;
        } else {
          isScrollSyncRequired = true;
          this.unsyncedScrollAfterCount++;
        }
      } else if (evt.target === after) {
        if (this.unsyncedScrollAfterCount > 0) {
          this.unsyncedScrollAfterCount--;
        } else {
          isScrollSyncRequired = true;
          isRTL = true;
          this.unsyncedScrollBeforeCount++;
        }
      }

      if (isScrollSyncRequired) {
        var source = isRTL ? after : before,
            target = isRTL ? before : after;

        if (this.scrollHeightKnown || source.scrollHeight > source.offsetHeight) {
          this.scrollHeightKnown = true;
          target.scrollTop = source.scrollTop;
        }

        target.scrollLeft = source.scrollLeft;

        this.setupMapWindowHeight();
        var mapWindowTop = (after.scrollTop * 99 / (this.finalLines * this.getLineHeight() + .1)).toFixed(2);

        this.mapWindow.css('top', mapWindowTop + "%");
      }
    },

    setupPanelsScrolling: function () {
      this.dbefore.on('scroll.diff', this.scrollPanels.bind(this));
      this.dafter.on('scroll.diff', this.scrollPanels.bind(this));
    },

    doResize: function () {
      this.width = (this.$window.width() - this.mapWidth) / 2;
      this.height = this.$window.height() - this.topOffset() - 1;

      if (this.width < 0 || this.height < 0) return;

      this.panels.css('height', this.height + 'px');
      this.dbefore.css('height', this.height + 'px');
      this.dafter.css('height', this.height + 'px');
      this.dmap.css('height', this.height + 'px');

      this.dbefore.css({left: 0, width: this.width + 'px'});
      this.toolbarBefore.css({left: 10, width: this.width - 10 + 'px'});
      this.tbefore.css('min-width', this.width + 'px');

      this.dafter.css({left: this.width + this.mapWidth + 'px', width: this.width + 'px'});
      this.toolbarAfter.css({left: this.width + this.mapWidth + 10 + 'px', width: this.width - 10 + 'px'});
      this.tafter.css('min-width', this.width + 'px');

      this.dmap.css({left: this.width + 'px', width: this.mapWidth + 'px'});
      this.toolbarTools.css({left: this.width + 'px', width: this.mapWidth + 'px'});

      this.scrollHeightKnown = false;
    },

    ignoreSpaces: function (ignore) {
      var url = this.pageUrl;

      var search = 'ignoreSpaces=' + (ignore ? 'false' : 'true');
      var replace = 'ignoreSpaces=' + (ignore ? 'true' : 'false');

      if (url.indexOf("&" + search) != -1) {
        url = url.replace("&" + search, "&" + replace);
      }
      else if (url.indexOf("?" + search) != -1) {
        url = url.replace("?" + search, "?" + replace);
      }
      else {
        url += "&" + replace;
      }

      window.location = url;
    },

    initClipboard: function () {

      BS.Clipboard('.clipboard-btn', {
        text: function(trigger) {
          var contentId = $j(trigger).data('for');
          var processedContent = '';

          var lineFeed = BS.Util.getLineFeed();

          $j(contentId).find('li').each(function () {
            // u00A0 is &nbsp;
            processedContent += $j(this).text().replace(/\u00A0/g, ' ') + lineFeed;
          });
          return processedContent;
        }
      });

    },

    getLineHeight: function() {
      return this.lineHeight;
    },

    setLineHeight: function() {
      this.lineHeight = this.lineHeight || this.dbefore.find('ol.list > li:first-child').height() || 18;
    },

    insertIFrameWithGraphicContent: function(modificationId, isPersonal, baseUrl, fileNameEncodedForJsAndUrl, showParam, containerId) {
      var container = $j('#' + containerId);
      if (!container){
        BS.Log.error("An error occurred in attempted to show graphic content. Container not found.");
        return;
      }
      //can't use new URLSearchParams() because of IE 11, so file name should be encoded for URL and JS at the same time
      var graphicUrl = baseUrl + '?show=' + showParam
                             + '&modId=' + modificationId
                             + '&personal=' + isPersonal
                             + '&vcsFileName=' + fileNameEncodedForJsAndUrl;
      var iFrame = document.createElement("iframe");
      iFrame.setAttribute('src', graphicUrl);
      container.html('');
      container.append(iFrame);
    }
  };
})(jQuery);
