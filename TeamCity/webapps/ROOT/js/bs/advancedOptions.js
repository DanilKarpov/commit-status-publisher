/**
 * Init Show/Hide advanced settings link and bind click handlers
 * @param {String} containerId
 * @param {String} propKey
 * @param {Boolean} showAdvanced
 */
BS.bindShowHideAdvancedOptions = function (containerId, propKey, showAdvanced) {
  var container = document.getElementById(containerId),
      hiddenClass = 'advanced_hidden';
  container._advancedOptions = {
    containerId: containerId,

    init: function() {
      var advSettingChanged = this.advancedSettingChanged();
      this.showAdvanced(showAdvanced || advSettingChanged, false);
    },

    advancedSettingChanged: function() {
      return $j(container).find('.advancedSetting .valueChanged:visible').length > 0;
    },

    showAdvanced: function(show, highlightOnShow) {
      var advancedSettings = $j(container).find('.advancedSetting');

      var toggleControl = $j('#advancedSettingsToggle_' + this.containerId);
      var toggleControlLink = toggleControl.find('a');

      if (show) {
        advancedSettings.removeClass(hiddenClass);
        if (highlightOnShow) {
          advancedSettings.css('color'); // make browser recalculate styles for blocks considered hidden (and having transition disabled)
          advancedSettings.addClass('advancedSettingHighlight strongHighlight');
          setTimeout(function() {
            advancedSettings.removeClass("strongHighlight");
          }, 1000);
        }
      }
      else {
        advancedSettings.addClass(hiddenClass).removeClass('advancedSettingHighlight');
      }

      if (advancedSettings.length > 0) {
        toggleControl.show();
        toggleControlLink.text(show ? 'Hide advanced options' : 'Show advanced options');

        var that = this;
        toggleControlLink.off('click').on('click', function toggleAdvancedSettings() {
          BS.User.setBooleanProperty(propKey, !show, {
            afterComplete: function() {
              that.showAdvanced(!show, true);
              BS.VisibilityHandlers.updateVisibility(container);
            }
          });
        });
        BS.MultilineProperties.updateVisible();
      } else {
        toggleControl.hide();
      }
    }
  };

  container._advancedOptions.init();
};
