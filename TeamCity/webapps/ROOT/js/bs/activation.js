/*

* Copyright 2000-2013 JetBrains s.r.o.
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

(function() {
  function XSS(id, url) {
    this.id = id;
    this.url = url + "&noCache=" + (new Date()).getTime() + "&server=" + window['base_uri'];
  }

  XSS.prototype.done = function(color) {
    this.indicator.style.backgroundColor = color;
    if (this.oncomplete) this.oncomplete(this.status);
  };

  XSS.prototype.doneR = function() {
    if(window.opera || /loaded|complete/.test(this.transport.readyState)) {
      this.status = 1;
      this.doneL();
    }
  };

  XSS.prototype.doneL = function() {
    this.status = this.status | this.transport.width;
    if(this.status>0) {
      this.done('green');
    } else {
      this.done('orange');
    }
  };

  XSS.prototype.doneE = function() {
    this.status = -1;
    this.done('silver');
  };

  XSS.prototype.go = function() {
    this.transport = document.getElementById(this.id);
    this.parent = document.getElementById(Activator.PANELID);
    if (this.transport) {
      this.dispose();
    }
    this.transport = new Image();
    this.transport.id = this.id;
    if(BS.Browser.opera) {
      this.transport.onreadystatechange = this.doneR.bind(this);
    } else {
      this.transport.onload = this.doneL.bind(this);
    }
    this.transport.onerror = this.doneE.bind(this);
    this.transport.onabort = this.doneE.bind(this);
    this.transport.style.display = 'none';
    this.indicator = document.createElement("div");
    this.indicator.className='activationIndicator';
    this.indicator.appendChild(this.transport);
    this.parent.appendChild(this.indicator);

    this.transport.src = this.url; // start loading image
  };

  XSS.prototype.dispose = function() {
    if(BS.Browser.opera) {
      this.transport.onreadystatechange = function() {};
    } else {
      this.transport.onload = function() {};
    }
    this.transport.onerror = function() {};
    this.transport.onabort = function() {};
    if (this.transport.parentNode) {
      this.transport.parentNode.removeChild(this.transport);
    }
    if (this.indicator && this.indicator.parentNode) {
      this.indicator.parentNode.removeChild(this.indicator);
    }
  };

  function XSSBroadcast(command) {
    this.panel = document.getElementById(Activator.PANELID);
    if(!this.panel) {
      this.parent = document.getElementsByTagName("body").item(0);
      this.panel = document.createElement("div");
      this.panel.className = Activator.PANELID;
      this.panel.setAttribute("id", Activator.PANELID);
      this.parent.appendChild(this.panel);
      this.panel.style.display = 'block';
    }

    this.sequential = BS.Browser.webkit;
    this.id = "id_" + Math.random();

    var START_PORT = 63330;
    var END_PORT = START_PORT + 9;
    var HOST = "http://127.0.0.1";

    this.responseCount = 0;
    this.successes = 0;
    this.connects = 0;
    this.requests = new Array(END_PORT - START_PORT);
    var oncomplete = this.done.bind(this);
    for (var port = START_PORT; port <= END_PORT; port++) {
      var uri = HOST + ":" + port + "/" + command;
      var xss = new XSS("r_" + this.id + "_" + port, uri);
      xss.oncomplete = oncomplete;
      this.requests[port - START_PORT] = xss;
      if(!this.sequential) xss.go();
    }
    this.index = 0;
    if(this.sequential) this.go();
  }

  XSSBroadcast.prototype.go = function() {
    this.requests[this.index++].go();
  };

  XSSBroadcast.prototype.done = function(status) {
    this._processingResponse = true;
    if (this._timeout) {
       clearTimeout(this._timeout);
    }
    this.responseCount++;
    if (status>=0) {
      this.connects++;
    }
    if (status>0) {
      this.successes++;
    }

    if(this.responseCount >= this.requests.length) {
      this._timeout = setTimeout(this.notify.bind(this), 2000);
    }
    this._processingResponse = false;
    if(this.sequential && (this.index < this.requests.length)) {
      this.go();
    }
  };

  XSSBroadcast.prototype.notify = function() {
    if (this._processingResponse) return;

    if (this.successes==0) {
      if (this.connects==0) {
        BS.ErrorDialog.showNoIdeRespondedError();
      } else {
        BS.ErrorDialog.showCanNotFindFileError();
      }
    }

    if (this.panel && this.panel.parentNode && this.panel.childElementCount <= this.requests.length) {
      this.panel.parentNode.removeChild(this.panel);
    }
    this._timeout = null;

    for (var i=0; i<this.requests.length; i++) {
      this.requests[i].oncomplete = function() {};
      this.requests[i].dispose();
    }
  };

  var Activator = {};
  Activator.PANELID = "activationPanel";
  Activator.doOpen = function (command) {
    new XSSBroadcast(command);
  };

  BS.Activator = Activator;
})();

BS.ErrorDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
  getTitle: function() {
    return $('errorFormTitle');
  },

  getContainer: function() {
    return $('errorFormDialog');
  },

  formElement: function() {
    return $('errorForm');
  },

  getBody: function() {
    return $j("#errorFormDialog").find("div.modalDialogBody").get(0);
  },

  show: function(title, content) {
    this.getTitle().innerHTML = title;
    this.getBody().innerHTML = content;
    this.showCentered();
  },

  showNoIdeRespondedError: function() {
    var html =
        "<div>" +
          "<div>Make sure TeamCity plugin is installed, and you are logged in to TeamCity from within the IDE.</div>" +
          "<br>" +
          "<div>" +
            "You can download the plugin using one of these links:" +
            "<ul>" +
              "<li><a title='Download plugin for IntelliJ Platform IDEs' " +
                     "href='" + window['base_uri'] + "/update/TeamCity-IDEAplugin.zip'>IntelliJ Platform plugin</a></li>" +
              "<li><a title='Download Addin for Visual Studio' " +
                     "href='" + window['base_uri'] + "/update/vsAddinWebInstaller.exe'>Addin for Visual Studio</a></li>" +
              "<li><a title='Copy the link location and use it as the Eclipse update site' " +
                     "href='" + window['base_uri'] + "/update/eclipse/'>Eclipse Plugin (update link)</a></li>" +
            "</ul>" +
          "</div>";

          if (window.opera) {
            html += "<div>You seem to be using the Opera browser. Please <a href='#' id='allowOperaXSS'>click here</a> to allow Opera to connect to TeamCity and try again.</div>";
          }

        html += "</div>";
    this.show("No IDE responded", html);

    $j('#allowOperaXSS').click(function() {
      $j('<iframe src="http://127.0.0.1:63330/file" style="position: fixed; width: 100%; height: 300px; top: 0; z-index: 1000"/>')
          .appendTo(document.body);
      return false;
    });
  },

  showCanNotFindFileError: function() {
    var html = "<div>IDE cannot locate the requested file.</div>";
    this.show("Error", html);
  }
}));
