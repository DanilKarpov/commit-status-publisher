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
BS.getPosition = function(el) {
  el = $(el);
  var doc = el.ownerDocument;

  // Gecko browsers normally use getBoxObjectFor to calculate the position.
  // When invoked for an element with an implicit absolute position though it
  // can be off by one. Therefore the recursive implementation is used in those
  // (relatively rare) cases.
  var BUGGY_GECKO_BOX_OBJECT = BS.Browser.mozilla && doc.getBoxObjectFor &&
                               el.getStyle('position') == 'absolute' &&
                               (el.style.top == '' || el.style.left == '');

  // NOTE: If element is hidden (display none or disconnected or any the
  // ancestors are hidden) we get (0,0) by default but we still do the
  // accumulation of scroll position.

  var pos = [];

  var parent = null;
  var box;

  var scroll = document.viewport.getScrollOffsets();
  var viewportElement = document.documentElement || document.body;

  if (el.getBoundingClientRect) { // IE
    box = el.getBoundingClientRect();
    var scrollTop = scroll.top;
    var scrollLeft = scroll.left;

    pos.x = box.left + scrollLeft;
    pos.y = box.top + scrollTop;

  } else if (doc.getBoxObjectFor && !BUGGY_GECKO_BOX_OBJECT) { // gecko
    // Gecko ignores the scroll values for ancestors, up to 1.9.  See:
    // https://bugzilla.mozilla.org/show_bug.cgi?id=328881 and
    // https://bugzilla.mozilla.org/show_bug.cgi?id=330619

    box = doc.getBoxObjectFor(el);
    var vpBox = doc.getBoxObjectFor(viewportElement);
    pos.x = box.screenX - vpBox.screenX;
    pos.y = box.screenY - vpBox.screenY;

  } else { // safari/opera
    pos.x = el.offsetLeft;
    pos.y = el.offsetTop;
    parent = el.offsetParent;
    if (parent != el) {
      while (parent) {
        pos.x += parent.offsetLeft;
        pos.y += parent.offsetTop;
        parent = parent.offsetParent;
      }
    }

    // opera & (safari absolute) incorrectly account for body offsetTop
    if (BS.Browser.opera || (BS.Browser.webkit && el.getStyle('position') == 'absolute')) {
      pos.y -= doc.body.offsetTop;
    }

    // accumulate the scroll positions for everything but the body element
    parent = el.offsetParent;
    while (parent && parent != doc.body) {
      pos.x -= parent.scrollLeft;
      // see https://bugs.opera.com/show_bug.cgi?id=249965
      if (!BS.Browser.opera || parent.tagName != 'TR') {
        pos.y -= parent.scrollTop;
      }
      parent = parent.offsetParent;
    }
  }

  var res = [pos.x, pos.y];
  res.left = pos.x;
  res.top = pos.y;

  return res;
};