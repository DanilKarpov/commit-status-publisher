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

BS.MultipartFormSaver = OO.extend(BS.FormSaver, {
  save: function(form, submitUrl, listener, debug) {
    var hiddenIframe = BS.MultipartFormSaver.createHiddenIframe();
    var hiddenForm = BS.MultipartFormSaver.createHiddenForm(form, hiddenIframe);

    var toDeleteFlag = false;

    hiddenIframe.observe('load', function() {
      if (// For Safari
          hiddenIframe.src == "javascript:'%3Chtml%3E%3C/html%3E';" ||
            // For FF, IE
          hiddenIframe.src == "javascript:'<html></html>';") {
        if (toDeleteFlag) {
          setTimeout(function() {
            hiddenIframe.remove();
          }, 0);
        }
        return;
      }

      var doc = hiddenIframe.contentDocument ? hiddenIframe.contentDocument : window.frames[hiddenIframe.id].document;

      // Opera fires load event multiple times. Should not affect other browsers
      if (doc.readyState && doc.readyState != 'complete') return;
      if (doc.body && doc.body.innerHTML == "false") return;

      BS.MultipartFormSaver.fillFormFromResponse(form, doc);
      hiddenForm.remove();
      toDeleteFlag = true;
      hiddenIframe.src = "javascript:'<html></html>';"; // Fix IE mixed content issue

      BS.FormSaver.save(form, submitUrl, listener, debug);
    });
    hiddenForm.submit();
  },

  createHiddenIframe: function() {
    var id = 'f' + Math.floor(Math.random() * 99999);
    var iframe = new Element('iframe', {name:id, id:id, src:'javascript:false;', style:'display:none'});
    document.body.appendChild(iframe);
    return iframe;
  },

  createHiddenForm: function(form, iframe) {

    var fileUploadUrl = '/fileUpload.html';

    var tokenMeta = document.querySelector('meta[name=tc-csrf-token]');
    if (tokenMeta) {
      fileUploadUrl += '?tc-csrf-token=' + encodeURIComponent(tokenMeta.getAttribute('content'));
    }

    var hiddenForm =
        new Element('form', {method:'post', enctype:'multipart/form-data', action:window['base_uri'] + fileUploadUrl, target:iframe.name, style:'display:none'});

    var fileInputs = Form.getInputs(form.formElement()).filter(function(element) {
      return element.getAttribute('type') == 'file' && element.name.startsWith('file:')
    });

    for (var i = 0; i < fileInputs.length; i++) {
      var real = fileInputs[i];
      var clone = real.cloneNode(true);
      real.hide();
      real.parentNode.insertBefore(clone, real);
      hiddenForm.appendChild(real);
    }

    document.body.appendChild(hiddenForm);
    return hiddenForm;
  },

  fillFormFromResponse: function(form, doc) {
    var response = BS.MultipartFormSaver.obtainResponse(doc);
    var fileUploadNodes = response.getElementsByTagName("uploadedFile");
    if (fileUploadNodes && fileUploadNodes.length > 0) {
      BS.MultipartFormSaver.addFilesToForm(fileUploadNodes, form);
    }
  },

  obtainResponse: function(doc) {
    if (doc.XMLDocument) {
      // response is a xml document Internet Explorer property
      return doc.XMLDocument;
    } else {
      return doc;
    }
  },

  addFilesToForm: function(fileNodes, form) {
    var elements = Form.getInputs(form.formElement()).filter(function(element) {
      return element.getAttribute('type') == 'hidden'
    });

    for (var i = 0; i < fileNodes.length; i++) {
      var uploadedFile = fileNodes.item(i);
      var fileName = uploadedFile.getAttribute('name');
      var name = fileName.substring(5, fileName.length);  //remove "file:" prefix

      var oldVals = elements.filter(function(element) {
        return element.name == name
      });
      for (var j = 0; j < oldVals.length; j++) {
        oldVals[j].remove();
      }

      var input =
          new Element('input',
                      {name:name, type:'hidden', value:(uploadedFile.getAttribute('success') ==
                                                        'true' ? uploadedFile.getAttribute('path') : '')});
      form.formElement().appendChild(input);
    }
  }
});