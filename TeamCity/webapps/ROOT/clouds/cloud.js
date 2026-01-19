BS.Clouds = {
  Problems : {},
  _ProblemsSecondGeneration: {},

  registerProblem: function(id) {
    BS.Clouds.Problems[id] = OO.extend(
        new BS.Popup(id, {  delay: 0,  hideDelay: -1}),
        {
          showMe: function(el) {
            this.showPopupNearElement(el);
        }
       });

    delete BS.Clouds._ProblemsSecondGeneration[id];
  },

  GCProblems: function() {
    Object.keys(this._ProblemsSecondGeneration).forEach(function (id) {
      delete this.Problems[id];
    });

    this._ProblemsSecondGeneration = {};
  },

  _showSimpleAjax: function(beforeAjax, params) {
    BS.Clouds.unregisterRefresh();

    beforeAjax();
    BS.ajaxRequest(window['base_uri'] + "/clouds/tab.html",
    {
      parameters: params,
      method : "post",
      onComplete: function() {
        BS.Clouds.refresh();
      }
    });
    return false;
  },

  registerRefreshable: function(fun) {
    BS.PeriodicalRefresh.start(15, function() {
        return fun();
    });
  },
  
  registerRefresh: function() {
    $j(function() {
      BS.Clouds.registerRefreshable(BS.Clouds.refresh.bind(BS.Clouds));
    });
  },

  unregisterRefresh: function() {
    BS.PeriodicalRefresh.stop();
  },

  refresh: function() {
    const element = $('cloudRefreshable');
    return element && element.refresh();
  },

  startInstance: function(uniqueId, projectId, profileId, imageId) {
    return BS.Clouds._showSimpleAjax(
        function() {
          $('startImageButton_' + uniqueId).disabled = 'disabled';
          $('startImageLoader_' + uniqueId).show();
        },
        {
          action : "startInstance",
          projectId: projectId,
          profileId : profileId,
          imageId : imageId
        }
    );
  },

  stopInstance: function(uniqueId, projectId, profileId, imageId, instanceId, expired) {
    BS.Clouds.unregisterRefresh();

    var _stopInstance = function () {
      return BS.Clouds._showSimpleAjax(
        function() {
          $('stopInstanceDiv_' + uniqueId).hide();
          $('stoppingInstanceDiv_' + uniqueId).show();
        },
        {
          action : "stopInstance",
          force : expired,
          profileId : profileId,
          projectId: projectId,
          imageId : imageId,
          instanceId : instanceId
        });
    };

    _stopInstance();
  }
};