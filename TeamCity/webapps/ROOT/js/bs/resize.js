/*
 * Copyright 2000-2024 JetBrains s.r.o.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * This file adds CSS classes to BODY element of the document, corresponding to the current view area width.
 * The classes can be tuned by CSS_WIDTHS constant.
 *
 * @author kir
 */

/* TODO replace with CSS media queries */

(function($) {
  // If browser width is 810 px, this code will set the following classes: gt800 lt1000 lt1200
  // If browser width is 2000 px, this code will set: gt800 gt1000 gt1200
  // If browser width is 200 px, this code will set: lt800 lt1000 lt1200
  var CSS_WIDTHS = [800, 1000, 1200];

  var $body;
  var update_classes = function() {
    $body = $body && $body.length > 0 ? $body : $(document).find('body');

    if ($body.length == 0) return;

    var classNames = $body.get(0).className.split(' ');
    var currWidth = $body.width();

    $.each(CSS_WIDTHS, function(i, width) {
      classNames = _.without(classNames, 'lt' + width);
      classNames = _.without(classNames, 'gt' + width);

      if (currWidth < width) {
        classNames.push('lt' + width);
      } else {
        classNames.push('gt' + width);
      }
    });

    $body.attr('class', _.compact(classNames).join(' '));
  };

  var onResize = _.throttle(update_classes, 500);

  $(document).ready(update_classes);
  Event.observe(window, "resize", onResize);
  Event.observe(window, "unload", function() {
    Event.stopObserving(window, "resize", onResize);
  });
})(jQuery);