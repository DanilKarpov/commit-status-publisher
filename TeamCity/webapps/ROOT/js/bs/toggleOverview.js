BS.TogglePopup.toggleOverview = function(link, projectId, options) {
  options = $j.extend({
                        loadingTop: 0,
                        loadingLeft: -20,
                        updateParent: true
                      }, options || {});

  var pinLink = $j(link),
      pinLinkImage = pinLink.children('.icon16_watched'),
      hiddenClass = 'icon16_watched_no',
      isPinned = !pinLinkImage.hasClass(hiddenClass),
      action = isPinned ? 'hideProject' : 'addProject',
      classAction;

  var offset = pinLink.offset(),
      loading = $j(BS.loadingIcon);

  loading.css({
                position: "absolute",
                top: offset.top + options.loadingTop + 'px',
                left: offset.left + options.loadingLeft + 'px',
                zIndex: 1000
              }).appendTo(document.body);

  BS.ajaxRequest(window['base_uri'] + "/ajax.html", {
    parameters: action + "=" + projectId,
    onComplete: function() {
      loading.remove();
    },
    onSuccess: function() {
      var newSrc, newTitle;

      if (isPinned) {
        classAction = 'addClass';
        newTitle = "Click to show project on the overview page";
      } else {
        classAction = 'removeClass';
        newTitle = "Project is shown on the overview page. Click to hide";
      }
      pinLinkImage[classAction](hiddenClass);
      pinLinkImage.attr("title", newTitle);

      if (options.updateParent) {
        pinLink.toggleClass("pinLink");
        pinLink.parents('tr.inplaceFiltered').toggleClass("visibleProject");
      }

      if (BS.TogglePopup.isOverviewPage === true) {
        var overviewProjects = $j('#overview-projects');

        if (overviewProjects.length == 0) {
          overviewProjects = $j('<div id="overview-projects">' +
                                'Overview configuration has been changed, ' +
                                '<a href="#" onclick="BS.reload(true)">refresh the page</a> to see the changes.' +
                                '<a href="#" class="dismiss-link" onclick="BS.Util.hide(this.parentNode)">Dismiss</a>' +
                                '</div>');
          $j('#toolbar').append(overviewProjects);
        } else {
          overviewProjects.show();
        }
      }
    }
  });
  return false;
};

