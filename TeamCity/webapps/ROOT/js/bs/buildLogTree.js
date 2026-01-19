BS.BuildLogTree = {
  expand: 'none',
  filter: 'all',
  clickTimeout: null,
  hideBlocks: 'false',
  consoleStyle: 'false',

  onToggle: function () {},

  SEPARATOR: ',',
  stickyOptions: {topSpacing:0, zIndex: 1},

  setFocusParam: function(id) {
    var url = document.location.href;

    if (url.indexOf('&_focus') > 0) {
      url = url.replace(/&_focus=\d*/, id ? '&_focus=' + id : '');
    }
    else if (id) {
      var hash = url.indexOf('#');
      if (hash > 0) {
        url = url.substr(0, hash) + '&_focus=' + id + url.substr(hash);
      }
      else {
        url += '&_focus=' + id;
      }
    }

    history.replaceState(history.state, '', url);
  },

  // Init stuff that can be inited before the page has finished loading.
  // Be careful when putting code here - test in Internet Explorer. DOM modifications of the log itself
  // have to be done in initDeferred()
  /**
   * @param {string} expand
   * @param {string} filter
   * @param {boolean} hideBlocks
   * @param {boolean} consoleStyle
   * @param {int} resolvedFocus
   */
  init: function (expand, filter, hideBlocks, consoleStyle, resolvedFocus) {
    this.expand = expand;
    this.filter = filter;
    this.hideBlocks = hideBlocks;
    this.consoleStyle = consoleStyle;


    if(resolvedFocus != null) {
      this.setFocusParam(resolvedFocus);
    }

    var container = $j('#buildLog');
    var that = this;

    container.on('click', '.msg', function (e) {
      var id = this.id.replace(/msg_/, '');
      var oldFocus = that.getFocus();

      that.unFocus();
      that.hideMessagePopup();

      if (id != oldFocus) {
        that.setFocusParam(id);
        that.focus(id, false);
      }
    });

    container.on('mouseover mouseout', '.msg .ts_in', function (e) {
      if (e.type == 'mouseover') {
        that.showMessagePopup($j(this).parent('.ts').attr('id').replace('ts_', ''));
      } else {
        that.hideMessagePopup();
      }
    });

    container.on('mousedown click dblclick', '.closed > .msg > .ts, .open > .msg > .ts', function (e) {
      if (e.type == 'mousedown') return false; // Prevent text selection

      var id = this.id.replace('ts_', '');
      e.type == 'click' && that.onNodeClick(id);
      e.type == 'dblclick' && that.onNodeDoubleClick(id);
    });

    container.on('click', '.msgLink', function (e) {
      e.stopPropagation();
    });

    this.initCheckbox('useConsoleStyle', 'consoleStyle', false, this.consoleStyle);
    this.initCheckbox('hideBlockNames', 'hideBlocks', true, !this.hideBlocks);

    this.initDeferred();
  },

  initDeferred: function () {
    var container = $j('#buildLog');

    if (this.consoleStyle) {
      container.addClass('console_mod');
    }

    var that = this;
    $j(document).ready(function () {
      // Custom oncopy handler for IE - removes empty lines from the copied fragment. Empty lines appear because
      // subtrees are present in the HTML, but hidden
      if (window.attachEvent && window.clipboardData) {
        container.get(0).attachEvent('oncopy', function (e) {
          setTimeout(function () {
            var text = window.clipboardData.getData('Text');
            text = text.split('\n');
            text = _.reject(text, function (item) {
              return item.match(/^\s$/)
            });
            text = text.join('\r\n');
            window.clipboardData.setData('Text', text);
          }, 10);
        });
      }

      that.restoreState();
      that.focus(that.getFocus(), true);
    });
  },

  initCheckbox: function (id, paramName, inverse, initVal) {
    if (!paramName) paramName = id;

    var that = this;
    var checkbox = $j('#' + id);

    checkbox.prop('checked', initVal);
    checkbox.change(function () {
      window.location.replace(that.getHrefWithParameter(paramName, inverse ? !this.checked : this.checked));
    });
  },

  onNodeClick: function (id) {
    if (this.clickTimeout) return;

    var that = this;
    this.clickTimeout = window.setTimeout(function () {
      that.clickTimeout = null;
      that.toggleNodeAndState(id, false);
    }, 200);
  },

  onNodeDoubleClick: function (id) {
    if (this.clickTimeout) {
      clearTimeout(this.clickTimeout);
      this.clickTimeout = null;
    }
    this.toggleNodeAndState(id, true);
  },

  toggleNodeAndState: function (id, recursive) {
    this.updateState(id, this.toggleNode(id, recursive), recursive);
  },

  // returns true if element is opened after toggling
  toggleNode: function (id, recursive) {
    var elem = $j('#node_' + id);
    if (elem.length > 0) {
      var wasOpen = elem.hasClass('open');
      if (wasOpen) {
        this.closeNode(id);
      } else {
        this.openNode(id, recursive);
      }
      elem.toggleClass('open closed');
      if (!recursive && !wasOpen) {
        //this.smartExpand(id);
      }

      return !wasOpen;
    }
  },

  closeBlock: function (id) {
    var elem = $j('#node_' + id);
    if (elem.length > 0) {
      if (elem.hasClass('open')) {
        this.closeNode(id);
        elem.removeClass("open");
        elem.addClass("closed");
      }
    }
  },

  openNode: function (id, recursive) {
    var that = this;

    var node = $j('#node_' + id);
    var loading = $j("<i/>").css({
                                   marginLeft: "16px",
                                   display: "none"
                                 }).append(BS.loadingIcon).append("&nbsp;Loading...").attr('id', 'load_' + id).insertAfter(node);

    setTimeout(function () {
      loading.show();
    }, 200);

    BS.ajaxRequest(window['base_uri'] + '/buildLog/buildLogTree.html', {
      parameters: {
        'id': id,
        'buildId': this.getHrefParameter('buildId'),
        'buildTypeId': this.getHrefParameter('buildTypeId'),
        'expand': recursive ? 'all' : that.expand,
        'filter': this.filter,
        'hideBlocks': that.hideBlocks,
        'consoleStyle': that.consoleStyle,
        'baseLevel': node.data('level'),
        'baseClasses': that.getChClasses(node) + ' ch_' + id,
        'state': that.getHrefParameter('state'),
        'type': 'block'
      },
      onComplete: function (transport) {
        loading.remove();

        if (node.hasClass('closed')) {
          // already closed
          that.onToggle();
          return;
        }

        $j('.ch_' + id).remove();

        node.after($j(transport.responseText));
        that.onToggle();
      }
    });
  },

  getBlockText: function (block) {
    return block.children('.msg').children('.mark').contents().filter(function () {
      return this.nodeType == 3;
    }).text()
  },

  closeNode: function (id) {
    $j('#load_' + id).remove();
    $j('.ch_' + id).remove();
    this.onToggle();
  },

  getChClasses: function (elem) {
    var classAttr = elem.attr('class');
    if (!classAttr) return '';

    var chClasses = '';
    var classes = classAttr.split(/\s+/);
    $j.each(classes, function (index, item) {
      if (item.indexOf('ch_') == 0) chClasses += item + ' ';
    });
    return chClasses;
  },

  updateState: function (id, open, recursive) {
    if (open) {
      this.expand == 'all' ? this.removeFromState(id) : this.addToState(id, recursive);
    } else {
      this.expand == 'all' ? this.addToState(id) : this.removeFromState(id);
    }
  },

  addToState: function (id, recursive) {
    this.removeFromState(id);
    if (recursive) id = this.wrapRecursiveId(id);
    var ids = this.getIdsFromState();
    var index = ids.indexOf(id);
    if (index == -1) {
      ids.push(id);
      this.setState(ids.join(this.SEPARATOR));
    }
  },

  removeFromState: function (id) {
    var ids = this.getIdsFromState();
    var index = ids.indexOf(id);
    if (index > -1) {
      ids.splice(index, 1);
      this.setState(ids.join(this.SEPARATOR));
    } else {
      index = ids.indexOf(this.wrapRecursiveId(id));
      if (index > -1) {
        ids.splice(index, 1);
        this.setState(ids.join(this.SEPARATOR));
      }
    }
  },

  wrapRecursiveId: function (id) {
    return id + '!';
  },

  isRecursiveId: function (id) {
    return /!/g.test(id);
  },

  getRecursiveId: function (id) {
    return id.split('!')[0];
  },

  getIdsFromState: function () {
    var state = this.getState();
    if (!state) return [];
    return state.split(this.SEPARATOR);
  },

  getState: function () {
    return BS.LocationHash.getHashParameter('state');
  },

  setState: function (state) {
    BS.LocationHash.setHashParameter('state', state);
  },

  hover: function (elem, className) {
    elem = $j(elem);
    if (!elem || elem.hasClass(className)) return false;
    elem.addClass(className);
    return true;
  },

  unHover: function (elem, className) {
    elem = $j(elem);
    if (!elem || !elem.hasClass(className)) return;

    elem.removeClass(className);
  },

  unHoverAll: function (className) {
    $j('.' + className).removeClass(className);
  },

  focus: function (id, scrollTo) {
    if (!id || id === '') return;

    var msg = $j('#msg_' + id);
    if (!msg.length || !this.hover(msg.get(0), 'focus') || !scrollTo) return;

    $j('html, body').animate(
        {
          scrollTop: msg.position().top - 200
        }, 500);
  },

  unFocus: function () {
    this.setFocusParam('');
    this.unHoverAll('focus');
  },

  getFocus: function () {
    return this.getHrefParameter('_focus') || BS.LocationHash.getHashParameter('focus');
  },

  restoreState: function () {
    var state = BS.LocationHash.getHashParameter('state');
    if (state || this.getHrefParameter('state')) {
      window.location.replace(this.getHrefWithParameter('state', state));
    }
  },

  smartExpand: function (id) {
    var elem = $j('#node_' + id);
    var hours = elem.children('#sub_' + id + ' > .closed > .msg > .time').filter(':contains("h:")');
    if (hours.length) {
      hours.parent().parent().toggleClass('open closed');
    } else {
      var minutes = elem.find('#sub_' + id + ' > .closed > .msg > .time').filter(':contains("m:")');
      if (minutes.length) {
        minutes.parent().parent().toggleClass('open closed');
      } else {
        var seconds = elem.find('#sub_' + id + ' > .closed > .msg > .time').filter(':contains("s")');
        if (seconds.length) {
          seconds.parent().parent().toggleClass('open closed');
        }
      }
    }
    elem.children('#sub_' + id + ' > .closed > .msg > .time').filter(':contains("started"), :contains("running")').toggleClass('open closed');
    elem.find('.sub > .closed:only-child').toggleClass('open closed');
  },

  reloadExpand: function (expand) {
    BS.LocationHash.setHashParameter('state', '');

    var newHref = this.replaceHrefParameter(this.getHrefWithParameter('expand', expand), 'state', '');
    if (newHref == window.location.href) {
      window.location.reload();
    } else {
      window.location.replace(newHref);
    }
  },

  reloadFilter: function (filter) {
    if (filter == this.filter) return;
    window.location.replace(this.getHrefWithParameter('filter', filter));
  },

  getHrefWithParameter: function (key, val) {
    return this.replaceHrefParameter(window.location.href, key, val);
  },

  replaceHrefParameter: function (href, key, val) {
    var search = window.location.search;
    var params = search.toQueryParams();
    params[key] = val;
    return href.replace(search, '?' + Object.toQueryString(params));
  },

  getHrefParameter: function (key) {
    var param = window.location.search.toQueryParams()[key];
    return param ? param : '';
  },

  showMessagePopup: function (id) {
    var elem = $j('#node_' + id);
    var filter = this.filter;
    var fromServer = elem.children('.pC').html();

    var popupText = '';

    if (elem.hasClass('open') || elem.hasClass('closed')) {
      popupText += '<li>' +
                   '<a href="#" title="Collapse / expand all inside this node" onclick="BS.BuildLogTree.toggleNodeAndState(\'' + id +
                   '\', true); return false">Collapse / expand subtree</a>' +
                   '</li>';
    }

    popupText += this._copyLinksText(elem);

    if (filter && filter != 'all' && filter != 'debug') {
      popupText +=
      '<li><a href="#" onclick="BS.BuildLogTree.navigateToTree(\'' + id + '\');return false;" title="Navigate to this message in All messages view">Show in All messages</a></li>';
    }

    if (fromServer) {
      popupText += fromServer;
    }

    if (popupText == '') return;

    if (!BS.MessagePopup) {
      BS.MessagePopup = new BS.Popup("messagePopup", {
        hideDelay: -1,    // disable mouseout hiding
        className: "messagePopup"
      });
    }
    BS.MessagePopup.hidePopup(600, true);
    var that = this;
    BS.MessagePopup.showPopupNearElement($('node_' + id), {
      shift: {x: 10, y: 15},
      innerHTML: "<ul class='messages buildLogPopup'>" + popupText + "</ul>",
      afterShowFunc: function (popup) {
        that.hover('#msg_' + id, "withPopup");

        var linkElement = $j('#messagePopup').find('.js-url-copy');
        linkElement.attr('data-clipboard-text', linkElement[0].href); // pass full HREF to copy to clipboard
      },
      afterHideFunc: function () {
        that.unHover('#msg_' + id, "withPopup");
      }
    });
  },

  _copyLinksText: function(elem) {
    var links_template = document.getElementById('buildRowPopupTemplate').innerHTML;
    var msgDiv = elem.find("div.msg");
    // Set attribute data_msg_1234 for build message element with copied data
    var elementWithText = elem.find('i.mark');
    var data_id = 'data_' + msgDiv.attr('id');
    elementWithText.attr('id', data_id);

    return links_template.replace(/##MSG_ID##/g, data_id.substring('data_msg_'.length))
  },

  hideMessagePopup: function () {
    if (BS.MessagePopup) BS.MessagePopup.hidePopup(600);
  },

  removeNodesHiddenOnClient: function (id, response) {
    var block = $j('#node_' + id);
    if (block.hasClass('closed')) {
      $j(response).filter('.ch_' + id).remove();
    }
  },

  updateBlockClass: function (id, hasChildren) {
    var block = $j('#node_' + id);
    if (hasChildren) {
      if (block.hasClass('emptyOpen')) {
        block.toggleClass('emptyOpen open');
      } else if (block.hasClass('emptyClosed')) {
        block.toggleClass('emptyClosed closed');
      }
    } else {
      if (block.hasClass('open')) {
        block.toggleClass('emptyOpen open');
      } else if (block.hasClass('closed')) {
        block.toggleClass('emptyClosed closed');
      }
    }
  },

  updateBlockDuration: function (id, duration) {
    var msgContainer = $j('#msg_' + id + ' > .mark');
    if (!msgContainer.length) return;

    if (duration.length > 0) {
      duration = ' (' + duration + ')';

      var time = msgContainer.children('.time');
      if (time.length > 0) {
        time.text(duration);
      } else {
        msgContainer.append('<u class="time"> ' + duration + '</u>');
      }
    } else {
      msgContainer.children('.time').remove();
    }
  },

  updateBlockStatus: function (id, statusClass) {
    var msgDiv = $j('#msg_' + id);
    if (msgDiv.length == 0) return;

    var mark = msgDiv.children('.mark');
    if (mark.length > 0) {
      mark.removeClass('status_warn');
      mark.addClass(statusClass); // we do not drop previous status class, it will simply be "overriden"
    }
    else {
      mark = $j('<i class="mark"/>').addClass(statusClass);
      BS.Util.getTextChildren('msg_' + id).wrap(mark); // we get text and wrap it in <i class='mark'>
    }
  },

  navigateTo: function (id) {
    this.unFocus();
    this.setFocusParam(id);
    this.focus(id, true);
  },

  navigateToTree: function (id, filter) {
    if (!filter) filter = 'all';
    if ($j('.rTree').length && $j('#node_' + id).length && (filter == this.filter)) {
      this.navigateTo(id, filter);
    } else {
      window.location.replace(window['base_uri'] + '/viewLog.html?tab=buildLog&logTab=tree&expand=all&buildId=' +
                              this.getHrefParameter('buildId') + '&filter=' + filter + '&_focus=' + id);
    }
  },

  showSizeWarning: function() {
    BS.Util.show('msg_overflow_warn_top').then(function () {
      $j(".stickyBar").sticky(BS.BuildLogTree.stickyOptions);
    })
  },

  showSizeWarningPermanent: function () {
    this.showSizeWarning();
    this._doNotHideWarning = true;
  },

  hideSizeWarning: function () {
    if (this._doNotHideWarning) return;

    BS.Util.hide('msg_overflow_warn_top').then(function () {
      $j(".stickyBar").sticky(BS.BuildLogTree.stickyOptions);
    });
  },

  continueLoading: function (id, optionalArg) {

    var that = this;
    var warning = $j('#msg_overflow_warn');
    var loading = $j("<i/>").css({
                                   marginLeft: "16px",
                                   display: "none"
                                 }).append(BS.loadingIcon).append("&nbsp;Loading...").attr('id', 'load_' + id).insertAfter(warning);

    warning.hide();

    setTimeout(function () {
      loading.show();
    }, 200);

    var params = {
      'buildId': this.getHrefParameter('buildId'),
      'buildTypeId': this.getHrefParameter('buildTypeId'),
      'expand': that.expand,
      'filter': that.filter,
      'hideBlocks': that.hideBlocks,
      'consoleStyle': that.consoleStyle,
      'state': that.getHrefParameter('state'),
      'contIndex': id
    };

    if (optionalArg) {
      for (var paramName in optionalArg) { params[paramName] = optionalArg[paramName]; }
    }

    BS.ajaxRequest(window['base_uri'] + '/buildLog/buildLogTree.html', {
      parameters: params,
      onComplete: function (transport) {
        loading.remove();
        warning.after($j(transport.responseText));
        warning.remove();
        that.onToggle();
      }
    });
  }
};