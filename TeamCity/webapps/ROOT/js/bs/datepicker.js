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


/* Change default behaviour of the 'Today' button. Select date instead of just go to page with today's date */
(function($) {
  var _gotoToday = $.datepicker._gotoToday;
  $.datepicker._gotoToday = function (a) {
    var target = $(a);
    var inst = this._getInst(target.get(0));
    _gotoToday.call(this, a);
    $.datepicker._selectDate(a, $.datepicker._formatDate(inst, inst.selectedDay, inst.selectedMonth, inst.selectedYear));
  }
})(jQuery);