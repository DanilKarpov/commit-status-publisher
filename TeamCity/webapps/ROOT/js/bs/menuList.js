(function($) {
  $(function() {
    var $doc = $(document);

    $doc.on('mouseover mouseout', '.menuList .menuItem', function(e) {
      $(this).toggleClass('menuItemSelected', e.type == 'mouseover');
    });

    $doc.on('click', '.menuList .menuItem', function(e) {
      if (!_.isFunction(this.onclick)) {
        var link = $(this).children('a').get(0);
        if (link && e.target != link) {
          if (_.isFunction(link.onclick)) {
            link.onclick();
          } else {
            return BS.openUrl(e, link.href);
          }
        }
      }
    });
  });
})(jQuery);
