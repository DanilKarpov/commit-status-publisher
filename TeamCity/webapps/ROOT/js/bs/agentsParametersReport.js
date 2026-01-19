(function($) {
  BS.AgentsParametersReport = {
    completionUrl: window['base_uri'] + '/agentParametersAutocompletion.html',

    initForm: function() {
      var paramName = $('#paramName');

      paramName.autocomplete({source: BS.AgentsParametersReport.createSource(),
                               completeOnCtrlSpace: true,
                               minLength: 0});
      paramName.focus();

      $(document).ready(function() {
        var hash = BS.AgentsParametersReport.getHash();
        if (hash) {
          paramName.val(hash);
          BS.AgentsParametersReport.group();
        }
      });
    },

    createSource: function() {
      return function(request, response) {
        $('#reportResultLoading').show();
        jQuery.ajax({
                      type: "GET",
                      url: BS.AgentsParametersReport.completionUrl + '?what=name&term=' + encodeURIComponent(request.term),
                      data: null,
                      success: function(data) {
                        $('#reportResultLoading').hide();
                        response(data);
                      },
                      error: function(xhr, status, e) {
                        $('#reportResultLoading').hide();
                        $('#errors').append(xhr.responseText);
                      },
                      dataType: 'json'
                    });
      };
    },

    group: function() {
      var $paramName = $('#paramName'),
          $paramNameError = $('#paramNameError'),
          name = BS.Util.trimSpaces($paramName.val());

      if (name) {
        $paramName.removeClass("errorField");
        $paramNameError.hide();
        $('#reportResultLoading').show();
        $('#queryResult').get(0).refresh(null, 'name=' + encodeURIComponent(name), function() {
          BS.AgentsParametersReport.setHash(name);
          $('#reportResultLoading').hide();
        });
      } else {
        BS.AgentsParametersReport.setHash('');
        $paramName.addClass("errorField");
        $paramNameError.css({"margin-left": $('#paramNameLabel').outerWidth(true)});
        $paramNameError.show();
      }
      return false;
    },

    getHash: function() {
      if (window.location.hash) {
        return window.location.hash.substr(1);
      } else {
        return '';
      }
    },

    setHash: function(hash) {
      window.location.hash = hash;
    }
  };  
})(jQuery);
