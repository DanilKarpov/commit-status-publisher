(function ($) {
  BS.BuildProblems = {
    toggleDetails: function (id) {
      $(BS.Util.escapeId(id + '_details')).toggle();
      $(BS.Util.escapeId(id + '_problem')).toggleClass('handle_expanded handle_collapsed');
      return false;
    },

    expandGroups: function (link) {
      BS.BuildProblems.expandCollapseGroups(link, true);
    },

    collapseGroups: function (link) {
      BS.BuildProblems.expandCollapseGroups(link, false);
    },

    expandCollapseGroups: function (link, expand) {
      if (expand) {
        BS.CollapsableBlocks.expandAll(true, 'problemsAll');
      }
      else {
        BS.CollapsableBlocks.collapseAll(true, 'problemsAll');
      }
      
      $(link).parent('div.expandCollapseActions').next('div.expandCollapseContainer').find(expand ? '.handle_collapsed' : '.handle_expanded').each(function() {
        var elem = $(this);
        if (elem.hasClass('bp')) {
          BS.BuildProblems.toggleDetails(this.id.replace(/_problem/, ''));
        }
      });
      return false;
    },

    updateSnapshotDependencyDescription: function (uid, newContentElmId) {
      var container = $j("#descriptionContainer_" + uid);
      var row = $j("#bpd_" + uid);
      var content = container.html();
      var newContentDiv = $j(newContentElmId);
      var i1 = content.indexOf("\"");
      var i2 = content.indexOf("\"", i1 + 1);

      if (i1 > -1 && i2 > -1) {
        var prefix = content.substring(0, i1);
        var j1 = prefix.indexOf("Snapshot dependency failure");
        var j2 = prefix.indexOf("Snapshot dependency", j1 + 1);
        if (j1 > -1 && j2 > -1) {
          prefix = "Snapshot dependency ";
        }
        container.html(prefix + content.substring(i2 + 2));
      }
      row.html(row.html() + $j(newContentElmId).html());
      newContentDiv.html("");
    },

    updateSnapshotDependencyCompactDescription: function (uid, newContentElmId) {
      var descriptionContainer = $j("#descriptionContainer_" + uid);
      var container = $j("#problemLink_" + uid);
      var newContentContainer = $j(newContentElmId);
      var prefix = "";
      if ($j(descriptionContainer).hasClass("singleNode")) {
        prefix = "Snapshot dependency failure: ";
      }
      if (!$j(container).length) {
        descriptionContainer.html(prefix + newContentContainer.html());
      } else {
        container.html(prefix + newContentContainer.html());
      }
    },

    addDetailsSectionSupport: function (uid) {
      var self = this;
      var cid = '#descriptionContainer_' + uid;
      $j(cid).addClass("hasDetails");
      $j(cid).find('a').contents().unwrap(); // remove link if it exists
      var row = $j(cid).parents('.tcRow');
      row.addClass("hasDetails");
      row.find(".tcCell:not(.rightSideActions)").off("click");
      row.find(".tcCell:not(.rightSideActions)").on("click", function () {
        self.toggleDetailsSection(uid)
      });
      var anchor = $j(location).attr('hash');
      if (anchor != undefined && '#' + uid + '_problem' == anchor) {
        self.expandDetailsSection(cid);
      }
    },

    expandDetailsSection: function (uid) {
      var cid = '#descriptionContainer_' + uid;
      var wid = '#detailsWrapper_' + uid;
      $j(cid).addClass("expanded");
      $j(cid).parents('.tcRow').addClass("expanded");
      $j(wid).addClass("expanded");

      $j(cid).trigger("problemExpanded");
    },

    toggleDetailsSection: function (uid) {
      var cid = '#descriptionContainer_' + uid;
      var wid = '#detailsWrapper_' + uid;
      $j(cid).toggleClass("expanded");
      $j(cid).parents('.tcRow').toggleClass("expanded");
      $j(wid).toggleClass("expanded");

      if ($j(wid).hasClass('expanded')) {
        BS.BuildResults.stacktraceShown();
        $j(cid).trigger("problemExpanded");
      } else {
        BS.BuildResults.stacktraceHidden();
      }

      return false;
    },

    focusBuildProblem: function(problemId) {
      var container = $j('.descriptionContainer[data-id=' + problemId + ']');
      var wrapper = $j('.detailsWrapper[data-id=' + problemId + ']');
      if (container.length > 0 && wrapper.length > 0) {
        container.addClass("expanded");
        container.parents('.tcRow').addClass("expanded");
        wrapper.addClass("expanded");
        $j(window).scrollTop(wrapper.position().top - 20);
        $j(container).trigger("problemExpanded");
      }
    },
    
    shortenLongDescription: function(el){
      var text = el.html();
      var cw = $j(window).width() - el.offset().left - 50;
      var dw = el.width();
      var i = el.html().lastIndexOf(' ');
      var hiddenWords = '';
      while (dw > cw && i > -1){
        hiddenWords += el.html().substring(i);
        el.html(el.html().substring(0,i));
        dw = el.width();
        i = el.html().lastIndexOf(' ');
      }
      if (hiddenWords.length > 0) {
        var ellipsisElem = document.createElement('span');
        ellipsisElem.className = 'descriptionContainer__ellipsis';
        ellipsisElem.textContent = ' ...';
        ellipsisElem.onmouseover = function() {BS.Tooltip.showMessage(this, {}, text)};
        ellipsisElem.onmouseout = function() {BS.Tooltip.hidePopup()};
        el.append(ellipsisElem);
      }
    }
  };

  $(document).on('mouseover mouseout', '.bpl .problemToHighlight', function() {
    var elem = $(this);
    var same = $('.problemToHighlight.problem' + elem.data('id'));
    if (same.length > 1) same.toggleClass('highlighted');
    return true;
  });

  $(document).on('click', '.bpl .problemToHighlight', function() {
    var elem = $(this);
    var same = $('.problemToHighlight.problem' + elem.data('id'));
    if (same.length > 1) same.toggleClass('stickyHighlighted');
    return true;
  });
})(jQuery);