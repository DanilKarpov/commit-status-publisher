/**
 * Created by sergeypak on 14/12/2016.
 */
if (!BS.Clouds) {
  BS.Clouds = {};
}

BS.Clouds.Admin.Profile = {
  toggleOption: function(enabled, option, defaultValue){
    if (enabled) {
      $j('#' + option).removeClass('hidden').val(defaultValue);
    } else {
      $j('#' + option).addClass('hidden').val('');
    }
  }
};