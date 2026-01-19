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

///-------------------------------------------------
// Utility to show testConnectionDialog
///-------------------------------------------------
BS.TestConnectionDialog = OO.extend(BS.AbstractModalDialog, {
  hideOnMouseClickOutside: true,
  getContainer: function() {
    return $('testConnectionDialog');
  },

  getSuccessTitle: () => 'Connection successful!',

  getFailureTitle: () => 'Connection failure!',

  show: function(status, details, nearElem, preserveHtml) {
    if (details.length > 0) {
      details = details + '\n';
    }

    var testConnectionDetails = $('testConnectionDetails');
    var testConnectionStatus = $('testConnectionStatus');

    var preparedText = preserveHtml ? details : details.
      replace(/&/g, '&amp;').
      replace(/</g, '&lt;').
      replace(/\n/g, '<br>').
      replace(/ /g, '&nbsp;');

    var showHidePromise = (preparedText.length > 0)
      ? BS.Util.show(testConnectionDetails)
      : BS.Util.hide(testConnectionDetails);

    var that = this;
    var sandbox = ReactUI.getSandbox(testConnectionDetails);
    return showHidePromise
      .then(function() {
        return sandbox.mutate(function () {
          if (typeof status === 'string') {
            testConnectionStatus.textContent = status;
            testConnectionStatus.className = 'testConnectionNeutral'
          }
          else if (status) {
            testConnectionStatus.innerHTML = that.getSuccessTitle();
            testConnectionStatus.className = 'testConnectionSuccess';
          } else {
            testConnectionStatus.innerHTML = that.getFailureTitle();
            testConnectionStatus.className = 'testConnectionFailed';
          }
        });
      })
      .then(function() {
        return that.showCentered();
      })
      .then(function () {
        return sandbox.mutate(function () {
          testConnectionDetails.style.height = '';
          testConnectionDetails.style.overflow = 'auto';
          testConnectionDetails.innerHTML = preparedText;
        });
      })
      .then(function () {
        return sandbox.measure(function () {
          return testConnectionDetails.getDimensions();
        });
      })
      .then(function (dim) {
        return sandbox.mutate(function () {
          var dialogHeight = dim.height + 20; // horizontal scroll bar might be shown, so we should increase dialog height
          if (dialogHeight > 350) {
            testConnectionDetails.style.height = '300px';
          } else {
            testConnectionDetails.style.height = dialogHeight + 'px';
          }

          that.recenterDialog();
        });
      });
  }

});