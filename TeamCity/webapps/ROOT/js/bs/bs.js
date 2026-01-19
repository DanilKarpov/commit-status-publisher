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

window.name = 'tcMain';
window.name321 = 'tcMain';

// Additionally define $j in JS to make IDEA happier
window.$j = window.$j || jQuery.noConflict;

$j(function() {
  BS.enableDisabled();
  BS.CSRF.addCSRFHeaderJQuery();   // Install header for jquery ajax requests

  // Initialize handling of CSRF errors in a case of jQuery ajax requests
  $j(document).ajaxError(function( event, request, settings ) {
    BS.CSRF.handleCSRFError(request, null, settings.headers && settings.headers['X-TC-CSRF-Token']);
  });

});

var OO = {
  extend: function(parent, extension) {
    return $j.extend({}, parent, extension);
  },

  bindAll: function(object) {
    var dest = new Object();
    for (var property in object) {
      if (typeof(object[property]) == "function") {
        dest[property] = object[property].bind(dest);
      } else {
        dest[property] = object[property];
      }
    }
    return dest;
  }
};

var BS = {
  Log: {
    _levelValues: {
      debug: 0,
      info: 1,
      warn: 2,
      error: 3
    },
    _defaultLevel: internalProps['teamcity.development.mode'] ? 'debug' : 'info',
    _log: function(level, msg, args) {
      var currentLevel = this._levelValues[BS.Util.extractParam('logLevel')]
        || this._levelValues[this._defaultLevel];
      if (this._levelValues[level] < currentLevel) {
        return;
      }
      var wc = window.console;
      if (wc && wc[level]) {
        if (args.length == 1) {
          wc[level](msg);
          if (msg.stack) {
            wc[level](msg.stack);
          }
        }
        else {
          // multiple arguments
          // this is a more browser-safe way to say wc[level].apply(wc, args)
          Function.prototype.apply.apply(wc[level], [wc, Array.prototype.slice.call(args)]);
        }
      }
    },

    error:  function(msg) { this._log('error', msg, arguments) },
    warn:   function(msg) { this._log('warn', msg, arguments) },
    info:   function(msg) { this._log('info', msg, arguments) },
    debug:  function(msg) { this._log('debug', msg, arguments) }
  },

  loadingUrl: window['base_uri'] + "/img/spinner.gif",
  loadingIcon: '<i class="icon-refresh icon-spin ring-loader-inline"></i>',

  _canReload: true,
  _temporaryBlocked: false,
  _tempBlockedTimer: null,

  stopObservingInContainers: function(elements, isScheduled) {
    if (elements.nodeType == 1) {
      elements = [elements];
    }
    var i = elements.length;

    while (i--) {
      var el = elements[i];
      // BS.Log.info("Clean all data under element " + el.id);
      $j(el).find('[data-observe-visibility]').each(function (_, elt) {
        ReactUI.stopObservingVisibility(elt);
      });
      if (!isScheduled || !el.dataset.cleanedUp) {
        $j(el).find('[data-react-refreshable-root]').each(function (_, elt) {
          ReactUI.markAsUnused(elt.id);
        });
      }
      el.dataset.cleanedUp = true;

      var selfAndDescendants = Array.prototype.slice.call(
        el.getElementsByTagName('*')
      ).concat(el);

      jQuery.cleanData(selfAndDescendants);
      Element.purge(el);
      selfAndDescendants.forEach(function(element) {
        BS.BackgroundLoader.remove(element);
        ReactUI.performCleanups(element);
      });
    }
  },

  stopObservingWhenDetached: function(element, scheduledToStop) {
    if (document.body.contains(element)) {
      setTimeout(BS.stopObservingWhenDetached.bind(BS, element), 100000);
    } else if (scheduledToStop === true) {
      BS.stopObservingInContainers([element], true)
    } else {
      setTimeout(BS.stopObservingWhenDetached.bind(BS, element, true), 10000);
    }
  },

  refreshBlocked: function() {
    return !BS._canReload || BS._temporaryBlocked;
  },

  canReload: function() {
    return !BS.Hider.hasVisiblePopups() &&
      !BS.refreshBlocked() &&
      document.readyState !== 'loading' &&
      document.readyState !== 'uninitialized' &&
      window.getSelection().toString().length === 0;
  },

  initReloadBlocker: function() {
    if (window.ReactUI.isSakuraUI) {
      return
    }

    if(BS.Browser.mozilla) {
      $(document.body).on("mousedown", function(event, element) {
        if (typeof BS == 'object') {
          if (element.tagName.toUpperCase() == 'A' && element.href && (element.href.indexOf("#") == -1 || element.href.indexOf("javascript://") == -1)) {
            BS.blockRefreshTemporary(1000);
          }
        }
      });
    }

    $(document.body).on("mousemove", function() {
      if (typeof BS != 'object') return;
      BS.blockRefreshTemporary(100);
    });

    Event.observe(window, "scroll", function() {
      if (typeof BS != 'object') return;
      BS.blockRefreshTemporary(100);
    });
  },

  blockRefreshTemporary: function(milliseconds) {
    // refresh blocked permanently ?
    if (!BS._canReload) return;

    var millis = milliseconds || 10*1000;

    if (BS._tempBlockedTimer) {
      clearTimeout(BS._tempBlockedTimer);
    }

    BS._temporaryBlocked = true;
    BS._tempBlockedTimer = setTimeout(function() {
      BS._temporaryBlocked = false;
    }, millis);
  },

  /**
   * A page might have several reasons for blocking refresh simultaneously. For example, some tests may be
   * selected and some stacktraces may be expanded. So instead of simply blocking/unblocking,
   * we need to take into account those various reasons.
   */
  _blockingActions: {},
  blockRefreshPermanently: function(action) {
    BS._blockingActions[action || 'default'] = true;
    BS._canReload = false;
  },

  unblockRefresh: function(action) {
    delete BS._blockingActions[action || 'default'];

    if (_.isEmpty(BS._blockingActions)) {
      BS._canReload = true;
      if (BS._tempBlockedTimer) {
        clearTimeout(BS._tempBlockedTimer);
      }
      BS._temporaryBlocked = false;
    }
  },

  _reloadTimeout: null,

  /**
   * Calls or queues passed function or `location.reload`
   * @param {Boolean} force
   * @param {Function} [reloadFunc=window.location.reload]
   * @param {Deferred} [deferred]
   */

  reload: function(force, reloadFunc, deferred) {
    if (!deferred) {
      deferred = $j.Deferred();
    }
    if (BS._reloadTimeout) {
      clearTimeout(BS._reloadTimeout);
      BS._reloadTimeout = null;
    }

    if (BS.canReload() || force) {
      deferred.resolve();
      if (reloadFunc) {
        reloadFunc();
      } else {
        window.location.reload(true);
      }
    }
    else {
      BS._reloadTimeout = setTimeout(function() {
        BS.reload(force, reloadFunc, deferred);
      }, 100);
    }
    return deferred;
  },

  /**
   * Trim text in the middle
   *
   * @param text {string} Text to trim
   * @param maxLength max number of visible characters to be shown after trim
   * @returns {string}
   */
  trimText: function(text, maxLength) {
    text = text || "";
    maxLength -= 1;
    if (text.length > maxLength + 3) {
      return text.substr(0, maxLength / 2) + '\u2026' + text.substr(text.length - maxLength / 2, text.length);
    }
    return text;
  },

  /**
   * @param {String} url
   * @param {Object} options
   * @returns {Ajax.Request}
   */
  ajaxRequest: function(url, options) {
    var opts = BS._patchOptions(url, options);

    if (!opts.afterCSRFRetry) {
      opts.afterCSRFRetry = function() {
        opts.afterCSRFRetry = function(){};  // To avoid cycle of retries
        BS.CSRF.addCSRFHeader(opts);
        new Ajax.Request(url, opts);
      }
    }

    return new Ajax.Request(url, opts);
  },

  /**
   * @typedef {Object} UpdaterTargetObject
   *
   * @prop {Element} [success]
   * @prop {Element} [failure]
   */
  /**
   * @param {Element|String|UpdaterTargetObject} container
   * @param {String} url
   * @param {Object} options
   * @returns {Ajax.Updater}
   */
  ajaxUpdater: function(container, url, options) {
    if (typeof container === 'string') { container = $(container); }
    if (container == null) return null;

    if (!container.success) container = { success: container };

    var opts = BS._patchOptions(url, options, container);

    if (!opts.afterCSRFRetry) {
      opts.afterCSRFRetry = function() {
        opts.afterCSRFRetry = function(){};  // To avoid cycle of retries
        BS.CSRF.addCSRFHeader(opts);
        new Ajax.Updater(container, url, opts)
      }
    }

    return new Ajax.Updater(container, url, opts);
  },

  _getRequestKey: function(url, parameters) {
    if (_.isObject(parameters)) {
      return url + Object.toQueryString(parameters);
    } else if (_.isString(parameters)) {
      return url + parameters;
    } else {
      return url;
    }
  },

  _patchOptions: function(url, options, container) {
    if (options == null) {
      options = {};
    }

    var csrfToken = BS.CSRF.addCSRFHeader(options);

    var oldOnComplete = options.onComplete;

    options.onComplete = function(response, json) {

      if (BS.CSRF.handleCSRFError(response, options.afterCSRFRetry, csrfToken)) {
        return;
      }

      var respXML = response.responseXML;
      if (respXML) {
        var handled = BS.XMLResponse.processErrors(respXML, {
          onAccessDeniedError: function(elem) {
            BS.XMLResponse.processRedirect(elem.ownerDocument);
          },

          onUnexpectedError: function(elem) {
            var message = "Unexpected error occurred on server:<br/>" + elem.textContent.escapeHTML();
            BS.Log.error(message);
            if (options.onUnexpectedError) {
              options.onUnexpectedError(respXML, elem);
            } else {
              BS.confirmDialog.show({
                title: "Unexpected error",
                text: message,
                actionButtonText: "Reload",
                action: function () {
                  BS.reload(true);
                }
              });
            }
          }
        });
        if (handled) return;
      } else {
        if (BS._reloadIfReceivedHTML(response)) return;
      }

      if (response.status === 401 && response.request.url.indexOf(base_uri) === 0) {
        BS.SubscriptionManager.closeSocket("you are logged out");
      }

      if (oldOnComplete) {
        oldOnComplete.call(options, response, json);
      }
    };

    return options;
  },

  internalProperty: function(propName, defVal) {
    var intPropVal = window['internalProps'] == undefined ? defVal : window['internalProps'][propName];
    return intPropVal == undefined ? defVal : intPropVal;
  },

  _reloadIfReceivedHTML: function(response) {
    var text = response.responseText;
    // proxies can return HTML with 502 (gateway timeout) status, in this case we should not reload entire page
    if (response.status == 200 && text.match(/^\s*<!DOCTYPE html[^>]*>[\s\S]*<\/html>\s*/i)) { // '.' does not match \n, while [\s\S] does
      BS.reload(true);
      return true;
    }

    return false;
  }
};

BS.CSRF = {
  _failureCount: 0,
  _cachedToken: null,

  addCSRFHeaderJQuery: function() {
    var csrfToken = this.getToken();
    if (csrfToken) {
      // Add support for $j.ajax requests:
      $j.ajaxSetup({
        headers: {
          "X-TC-CSRF-Token": csrfToken
        }
      });
    }
  },

  addCSRFHeader: function(prototypeJsOptions) {
    var csrfToken = this.getToken();
    if (csrfToken) {
      prototypeJsOptions.requestHeaders = prototypeJsOptions.requestHeaders || {};
      prototypeJsOptions.requestHeaders['X-TC-CSRF-Token'] = csrfToken;
    }
    return csrfToken;
  },

  handleCSRFError: function(request, retryCallback, csrfToken) {
    if (request && request.status == 403 && request.responseText.indexOf("CSRF") >= 0) {
      if (csrfToken != null && csrfToken !== this.getCachedToken()) {
        if (retryCallback != null) {
          BS.Log.info("CSRF token already updated. Retry request");
          retryCallback();
        }
      } else {
        BS.Log.info("CSRF check error for the request");
        this.refreshCSRFToken(retryCallback);
      }


      return true;
    }
    return false;
  },

  getToken: function() {
    var token = $j('meta[name=tc-csrf-token]').attr('content');
    this._cachedToken = token;
    return token;
  },

  getCachedToken: function() {
    return this._cachedToken;
  },

  retryCallbacks: [],

  refreshCSRFToken: function(retryCallback, force) {
    if (retryCallback != null) {
      this.retryCallbacks.push(retryCallback);
    }
    if (!force && !BS.Util.isPageVisible()) {
      return;
    }

    var that = this;
    BS.ajaxRequest(window['base_uri'] + "/authenticationTest.html?csrf", {
      method: "GET",
      onSuccess: function(response) {
        BS.Log.info("CSRF token has been updated");
        $j('meta[name=tc-csrf-token]').attr('content', response.responseText); // Meta tag in HEAD
        $j('.tc-csrf-token-input').attr('value', response.responseText); // Input form param
        that.addCSRFHeaderJQuery();
        this._cachedToken = response.responseText;
        if (that.retryCallbacks.length > 0) {
          BS.Log.info("Retry requests after CSRF token update");
          that.retryCallbacks.forEach(function(callback) {
            callback();
          });
          that.retryCallbacks = [];
        }
      },
      onFailure: function () {
        BS.Log.info("Cannot refresh CSRF token");
      }
    })
  },

  initPeriodicalCsrfRefresh: function() {

    BS.PageVisibilityListeners.subscribe({
      onPageBecameVisible: function() {
        BS.CSRF.refreshCSRFToken();
        BS.ServerLink && BS.ServerLink.getServerInfo();
      }
    });

    var halfHour = 1000 * 60 * 30;
    var initialDelay = Math.random() * halfHour;
    setTimeout(function() {
      setInterval(function () {
        BS.CSRF.refreshCSRFToken(null, true);
      }, halfHour);
    }, initialDelay);
  }
};

BS.WebSocketLog = function() {

  var loggedMessages = [];

  return {
    log: function(sessionId, message) {
      if (message.length > 200) {
        message = message.substring(0, 200) + "...";
      }
      if (loggedMessages.length > 50) {
        loggedMessages.shift();
      }
      var currentTime = new Date();
      var addLeadingZero = function(number) {
        if (number < 10) return "0" + number;
        else return "" + number;
      };
      var addTwoLeadingZeros = function(number) {
        if (number < 10) return "00" + number;
        if (number < 100) return "0" + number;
        else return "" + number;
      };
      var logMsg = '[' + addLeadingZero(currentTime.getHours()) + ":" + addLeadingZero(currentTime.getMinutes()) + ':' + addLeadingZero(currentTime.getSeconds()) + '.' +
        addTwoLeadingZeros(currentTime.getUTCMilliseconds()) + ", session " + sessionId + "]: " + message;
      loggedMessages.push(logMsg);
      if (BS.internalProperty('teamcity.ui.webSocket.logToConsole', false)) {
        BS.Log.debug("WebSocket: " + logMsg);
      }
    },

    getLog: function() {
      return loggedMessages;
    }
  }
} ();

BS.WebSocketProperties = {
  heartbeatIntervalMillis: 15000,
  webSocketEnabled: true
};

BS.WebSocket = function() {
  var onMessage;
  var socket;
  var socketOpened = false;
  // noinspection SpellCheckingInspection
  var connectTimeouted = false;
  var socketOpenedDeferred;
  var connectTimeout;
  var pushQueue = [];    //list of pending messages that are going to be sent to the server.
  var flushQueueTimeout;
  var idleTimeout;
  var onDisconnected;
  var sessionId;

  var webSocketClosed = function() {
    if (connectTimeout) {
      clearTimeout(connectTimeout);
      connectTimeout = null;
    }

    if (idleTimeout) {
      clearTimeout(idleTimeout);
      idleTimeout = null;
    }

    if (flushQueueTimeout) {
      clearTimeout(flushQueueTimeout);
      flushQueueTimeout = null;
    }

    if (socketOpened) {
      socketOpened = false;
      if (onDisconnected) {
        log("Calling WebSocket disconnected listener");
        onDisconnected();
      }
    }

    if (socketOpenedDeferred.state() === 'pending') {
      socketOpenedDeferred.resolve(false);
    }
  };

  var log = function(msg) {
    BS.WebSocketLog.log(sessionId, msg);
  };

  var webSocketFailed = function(reason) {
    log("WebSocket connection failed" + (reason ? (': ' + reason) : ""));

    webSocketClosed();

    if (socket != null && socket.readyState === 1) {
      log("Closing WebSocket on error");
      socket.close();
    }
  };

  var webSocketOpened = function() {
    if (connectTimeouted) {
      log("WebSocket connection is established, but the connection timeout was already fired, closing the socket.");
      if (socket.readyState === 1) {
        socket.close();
      }
      return;
    }

    socketOpened = true;
    clearTimeout(connectTimeout);
    log("WebSocket connection is successfully established");

    (function flushQueue() {
      while (pushQueue.length > 0) {
        var message = pushQueue.splice(0, 50).join(',');
        sendToServer(message);
      }
      flushQueueTimeout = setTimeout(flushQueue, 500);
    })();

    sendToServer("ping");

    if (socketOpenedDeferred.state() === 'pending') {
      socketOpenedDeferred.resolve(true);
    }
  };

  var sendToServer = function(message) {
    log("Sending message '" + message + "'");
    socket.send(message);
  };

  var openSocket = function() {
    if (!window.WebSocket) {
      webSocketFailed("WebSocket is not supported in the current browser");
      return;
    }

    var url = (window['base_uri']).replace(/^http/, "ws") + '/app/subscriptions' + "?browserLocationHost=" + encodeURIComponent(window['base_uri']);
    log("Opening websocket on '" + url + "'");

    socket = new WebSocket(url);

    socket.onmessage = function(event) {
      var incomingMsg = event.data;
      log("Message received: '" + incomingMsg + "'");

      if (idleTimeout) {
        clearTimeout(idleTimeout);
      }

      idleTimeout = setTimeout(function () {
        if (socketOpened) {
          log("Closing WebSocket session due to idle timeout");
          webSocketClosed();
          socket.close();
        }
      }, BS.WebSocketProperties.heartbeatIntervalMillis * 2);

      //Server sends 'socketOpened' message when it receives and verified CSRF token message that client sends on socket opening.
      //We consider connection as established only if this round trip is successful.
      if (incomingMsg == 'socketOpened') {
        webSocketOpened();
        return;
      }

      if (incomingMsg == 'ping#Ping') {
        if (socketOpened) {
          sendToServer("pong");
        }
        return;
      }

      if (onMessage) {
        onMessage(incomingMsg);
      }
    };

    socket.onerror = function () {
      log("WebSocket 'error' event captured");
      webSocketFailed();
    };

    socket.onclose = function (event) {
      if (event.wasClean) {
        log("WebSocket closed normally with code " +  event.code + " " + event.reason);
      } else {
        log("WebSocket closed unexpectedly with code " +  event.code + " " + event.reason);
      }

      webSocketClosed();
    };

    socket.onopen = function() {
      log("WebSocket 'open' event captured");
      sendToServer("tc-csrf-token:" + BS.CSRF.getToken());
    };

    connectTimeout = setTimeout(function () {
      if (!socketOpened) {
        connectTimeouted = true;
        webSocketFailed("Connection timeout");
      }
    }, BS.internalProperty('teamcity.ui.websocket.connectTimeout', 3000));
  };

  return {

    open: function(options) {

      if (!BS.WebSocketProperties.sessionsCounter) {
        BS.WebSocketProperties.sessionsCounter = 1;
      }

      sessionId = BS.WebSocketProperties.sessionsCounter++;

      if (!BS.WebSocketProperties.webSocketEnabled) {
        log("WebSocket support is disabled on server side.");
        options.onFailedToOpen();
        return;
      }

      socketOpenedDeferred = $j.Deferred();
      socketOpenedDeferred.done(function(opened) {
        log("WebSocket opening deferred is resolved to " + opened);
        if (opened) {
          options.onOpen();
        } else {
          options.onFailedToOpen();
        }
      });

      onDisconnected = options.onDisconnected;
      onMessage = options.onMessage;

      openSocket();
    },

    close: function(message) {
      if (socket != null && socket.readyState === 1) {
        log("Closing WebSocket" + message && (": " + message) + ".");
        socket.close();
      }
    },

    sendMessage: function(msg) {
      pushQueue.push(msg);
    }
  }
};

/**
 * Executes the given task with the specified interval.
 * Pauses execution while current page is not visible.
 *
 * @param task function returning a thenable (e.g. native Promise or jQuery Deferred). Thenable should be resolved/failed when the current task call is finished.
 * @param {integer} [interval=5000] in milliseconds
 */
BS.periodicalExecutor = function(task, interval) {

  var taskTimeoutId;
  var visibilityListenerId;
  var lastStartedTask = null;

  if (!interval) interval = 5000;

  var scheduleNext = function() {
    if (BS.Util.isPageVisible()) {
      clearTimeout(taskTimeoutId);
      taskTimeoutId = setTimeout(executeTask, interval);
    }
  };

  var executeTask = function() {
    lastStartedTask = task().then(scheduleNext, scheduleNext);
    return lastStartedTask;
  };

  var cancelNextTask = function() {
    return lastStartedTask.then(function() {
      clearTimeout(taskTimeoutId);
    })
  };

  return {
    start: function() {
      executeTask();

      var that = this;
      visibilityListenerId = BS.PageVisibilityListeners.subscribe({
        onPageBecameHidden: function() {
          cancelNextTask();
        },
        onPageBecameVisible: function() {
          that.unscheduledExecution();
        }
      });
    },

    unscheduledExecution: function() {
      return cancelNextTask().then(executeTask);
    },

    stop: function() {
      cancelNextTask();
      BS.PageVisibilityListeners.unsubscribe(visibilityListenerId);
    }
  };
};

/**
 * Allows to subscribe to updates in some interesting topic.
 * If WebSocket is available then it's used, otherwise default polling is started automatically.
 */
BS.SubscriptionManager = function() {

  var topicHandlers = {};
  var poller = null;
  var DEFAULT_ID = 'default';

  var socketIsActive;

  var socket;
  var lastMessages = {};

  function callHandlers(topicId, message) {
    lastMessages[topicId] = message;
    var handlers = topicHandlers[topicId];
    if (handlers == null) {
      return;
    }

    Object.keys(handlers).forEach(function(key) {
      var handler = handlers[key];
      if (handler != null) {
        handlers[key](message);
      } else {
        BS.Log.info("Message with unknown handler '" + topicId + "' was received: " + message);
      }
    });
  }

  var manager = {
    subscribe: function (topicId, onMessage, subscriptionId) {
      var subId = subscriptionId || DEFAULT_ID;

      if (topicHandlers[topicId] == null) {
        // first subscription on this topic
        topicHandlers[topicId] = {};
        if (socketIsActive) {
          socket.sendMessage(topicId);
        } else {
          checkNowThrottled();
        }
      } else if (topicHandlers[topicId][subId] != null) {
        // already subscribed
        return;
      } else if (lastMessages[topicId] != null) {
        onMessage(lastMessages[topicId]);
      }

      topicHandlers[topicId][subId] = onMessage;

      return function() {
        manager.unsubscribe(topicId, subscriptionId)
      }
    },

    unsubscribe: function (topicId, subscriptionId) {
      var subId = subscriptionId || DEFAULT_ID;
      var handlers = topicHandlers[topicId] || {};
      if (handlers[subId] == null) {
        // already unsubscribed
        return;
      }

      delete handlers[subId];

      if (Object.keys(handlers).length === 0) {
        // last subscription on this topic is gone
        if (socketIsActive) {
          socket.sendMessage("unsubscribe#" + topicId);
        }
        delete topicHandlers[topicId];
      }
    },

    /**
     * Send unscheduled polling request.
     */
    checkNow: function () {
      if (poller) {
        poller.unscheduledExecution();
      }
    },

    start: function () {
      socket = BS.WebSocket();
      socket.open({
        onOpen: function () {
          socketIsActive = true;

          for (var topic in topicHandlers) {
            if (topicHandlers.hasOwnProperty(topic)) {
              socket.sendMessage(topic);
            }
          }
        },

        onFailedToOpen: function () {
          socketIsActive = false;
          poller = BS.periodicalExecutor(function () {
              var result = $j.Deferred();

              BS.ajaxRequest(window['base_uri'] + '/subscriptions.html', {
                method: 'post',
                parameters: "topics=" + Object.keys(topicHandlers).join(','),
                onComplete: function (response) {
                  if (response && response.status != 200) {
                    BS.ServerLink.waitUntilServerIsAvailable(BS.SubscriptionManager.start);
                    poller.stop();
                    poller = null;
                    return;
                  }

                  var messages = response.responseText.trim();
                  //contains messages from different topics in format: 'topic1|message1Length|message1topic2|message2Length|message2'

                  while (messages.length !== 0) {
                    var topicDelimiterPos = messages.indexOf('|');
                    var topic = messages.substring(0, topicDelimiterPos);
                    messages = messages.substring(topicDelimiterPos + 1);

                    var lengthDelimiterPos = messages.indexOf("|");
                    var length = messages.substring(0, lengthDelimiterPos);
                    messages = messages.substring(lengthDelimiterPos + 1);
                    callHandlers(topic, messages.substring(0, length));
                    messages = messages.substring(length);
                  }

                  result.resolve();
                }
              });
              return result.promise();
          }, BS.internalProperty('teamcity.ui.pollInterval') * 1000);
          poller.start();
        },

        onDisconnected: function () {
          socketIsActive = false;

          BS.ServerLink.waitUntilServerIsAvailable(function () {
            BS.SubscriptionManager.start();
          });
        },

        onMessage: function (msg) {
          //all the messages have the format 'topic#message'.
          var delimiterIndex = msg.indexOf("#");
          var topicId = msg.substring(0, delimiterIndex);
          var message = msg.substring(delimiterIndex + 1);

          callHandlers(topicId, message);
        }

      })
    },

    dispose: function() {
      if (poller) {
        poller.stop();
      }
      topicHandlers = {};
    },

    closeSocket: function(message) {
      if (socket != null) {
        socket.close(message);
      }
    }
  };

  const checkNowThrottled = _.throttle(manager.checkNow, 500, {leading: true, trailing: true});

  return manager;
}();

BS.ServerCommands = {
  _reloadCounter: null,

  startWatching: function() {
    var that = this;
    BS.SubscriptionManager.subscribe("serverCommands/reload", function(message) {
      var reloadCommand = JSON.parse(message);
      if (!reloadCommand) return;

      if (that._reloadCounter === null) {
        that._reloadCounter = reloadCommand.counter;
        return;
      }

      if (that._reloadCounter !== reloadCommand.counter) {
        var reloadTimeoutInSeconds = Math.floor((Math.random() * reloadCommand.dispersion) + 1);
        BS.Log.info("Received reload command from the server, page will be reloaded in " + reloadTimeoutInSeconds + " seconds.");
        setTimeout(function() {
          BS.reload(false);
        }, reloadTimeoutInSeconds * 1000)
      }
    })
  }
};

Ajax.PeriodicalUpdater.addMethods({
  updateNow: function () {
    clearTimeout(this.timer);
    this.onTimerEvent();
  }
});

BS.PeriodicalUpdater = Class.create(Ajax.PeriodicalUpdater, {
  initialize: function($super, container, url, options) {
    this.initialFrequency = options.frequency || 2;
    this.reducedFrequency = this.initialFrequency * 5;
    this.initialOnSuccess = options.onSuccess || Prototype.emptyFunction();
    this.initialOnFailure = options.onFailure || Prototype.emptyFunction();
    options.onSuccess = this.onSuccess.bind(this);
    options.onFailure = this.onFailure.bind(this);
    options.onException = this.onException.bind(this);
    options.onComplete = this.onComplete.bind(this);
    BS.CSRF.addCSRFHeader(options);
    this.visibilityListenerId = this.setupVisibilityHandler();
    if (container && !container.success) container = { success: container };
    $super(container || {update:function() {}}, url, options);
  },

  updateComplete: function() {
    if (!this.isPaused) {
      Ajax.PeriodicalUpdater.prototype.updateComplete.apply(this, arguments);
    }
  },

  onComplete: function(){
    this.stopVisibilityHandler();
  },

  onSuccess: function(response, json) {
    if (response && response.status == 0) {
      // workaround, see http://dev.rubyonrails.org/ticket/11508
      this.onFailure(response, json);
      return;
    }

    this.frequency = this.initialFrequency; // reset frequency
    this.failureState = false;

    if (this.initialOnSuccess) {
      if (BS._reloadIfReceivedHTML(response)) return;
      this.initialOnSuccess.call(this.options, response, json);
    }
  },

  onFailure: function(response, json) {
    this.frequency = this.reducedFrequency; // reduce frequency
    this.failureState = true;
    if (this.initialOnFailure) {
      this.initialOnFailure.call(this.options, response, json);
    }
  },

  onException: function() {
    this.frequency = this.reducedFrequency; // reduce frequency
    this.failureState = true;
  },

  setupVisibilityHandler: function() {
    var that = this;
    return BS.PageVisibilityListeners.subscribe({
      onPageBecameVisible : function() {
        that.isPaused = false;
        that.updateNow();
      },

      onPageBecameHidden: function() {
        that.isPaused = true;
      }
    });
  },

  stopVisibilityHandler: function() {
    if (this.visibilityListenerId !== undefined) {
      BS.PageVisibilityListeners.unsubscribe(this.visibilityListenerId);
    }
  }
});

/**
 * https://developer.mozilla.org/en/DOM/Using_the_Page_Visibility_API
 */
BS.PageVisibility = {
  detect: function() {
    var hiddenProperty, visibilityChangeEvent;
    if (typeof document.hidden !== "undefined") {
      hiddenProperty = "hidden";
      visibilityChangeEvent = "visibilitychange";
    } else if (typeof document.mozHidden !== "undefined") {
      hiddenProperty = "mozHidden";
      visibilityChangeEvent = "mozvisibilitychange";
    } else if (typeof document.msHidden !== "undefined") {
      hiddenProperty = "msHidden";
      visibilityChangeEvent = "msvisibilitychange";
    } else if (typeof document.webkitHidden !== "undefined") {
      hiddenProperty = "webkitHidden";
      visibilityChangeEvent = "webkitvisibilitychange";
    }

    var pageVisibilitySupported = typeof document.addEventListener !== "undefined" && typeof hiddenProperty !== "undefined";

    return {
      supported: pageVisibilitySupported,
      hiddenProperty: hiddenProperty,
      visibilityChangeEvent: visibilityChangeEvent
    };
  }
};

BS.PageVisibilityListeners = function() {
  var pageVisibility = BS.PageVisibility.detect();
  var registeredListeners = [];

  if (pageVisibility.supported) {
    document.addEventListener(pageVisibility.visibilityChangeEvent, function() {
      if (document[pageVisibility.hiddenProperty]) {
        for (var i = 0; i < registeredListeners.length; i++) {
          if (registeredListeners[i]) {
            if (registeredListeners[i].onPageBecameHidden) {
              registeredListeners[i].onPageBecameHidden();
            }
          }
        }
      } else {
        for (var j = 0; j < registeredListeners.length; j++) {
          if (registeredListeners[j]) {
            if (registeredListeners[j].onPageBecameVisible) {
              registeredListeners[j].onPageBecameVisible();
            }
          }
        }
      }
    }, false);
  }

  return {
    /**
     * @param listener - object containing two optional callbacks:
     * onPageBecameHidden
     * onPageBecameVisible
     *
     * Note that in some browsers we can't detect page visibility, so callbacks will not be called.
     * It seems to be fine - for such browsers all pages are assumed to be visible always.
     */
    subscribe: function(listener) {
      if (!pageVisibility.supported || (BS.Cookie && BS.Cookie.get('disable-visibility-api') == 1)) {
        return -1;
      }

      return registeredListeners.push(listener) - 1;
    },

    unsubscribe: function(listenerId) {
      registeredListeners[listenerId] = undefined;
    }
  }
}();

BS.EventTracker = {
  _subscriptions: {},

  _toBeInvokedListeners : [],

  subscribeOnEvent: function(eventName, currentValue, listener) {
    this._subscribeOnEvent(eventName, currentValue, "", listener)
  },

  subscribeOnProjectEvent: function(eventName, currentValue, projectId, listener) {
    this._subscribeOnEvent(eventName, currentValue, "p:" + projectId, listener)
  },

  subscribeOnBuildTypeEvent: function(eventName, currentValue, buildTypeId, listener) {
    this._subscribeOnEvent(eventName, currentValue, "b:" + buildTypeId, listener)
  },

  subscribeOnUserEvent: function(eventName, currentValue, userId, listener) {
    this._subscribeOnEvent(eventName, currentValue, "u:" + userId, listener)
  },

  subscribeOnAgentEvent: function(eventName, currentValue, agentId, listener) {
    this._subscribeOnEvent(eventName, currentValue, "a:" + agentId, listener)
  },

  _subscribeOnEvent: function(eventName, currentValue, parameters, listener) {
    var subscr = {
      currentValue: currentValue,
      listeners: [listener],
      id: eventName + ";" + parameters
    };
    this._addSubscription(subscr);
  },

  unsubscribeBuildTypeEventSubscription: function(eventName, buildTypeId) {
    this._removeSubscription(eventName, "b:" + buildTypeId);
  },

  _removeSubscription: function(eventName, parameters) {
    var id = (eventName + ";" + parameters);
    var subscription = this._subscriptions[id];
    if (subscription) {
      subscription.listeners = [];
      delete subscription[id];
    }
    BS.SubscriptionManager.unsubscribe("events/" + id)
  },

  _addSubscription: function(subscr) {
    var curSubscr = this._subscriptions[subscr.id];
    if (curSubscr != null) {
      for (var i=0; i<curSubscr.listeners.length; i++) {
        if (curSubscr.listeners[i].toString().strip() == subscr.listeners[0].toString().strip()) return;
      }

      curSubscr.listeners.push(subscr.listeners[0]);
    } else {
      this._subscriptions[subscr.id] = subscr;
    }

    BS.SubscriptionManager.subscribe("events/" + subscr.id, function(counter) {
      if (subscr.currentValue != counter) {
        subscr.currentValue = counter;
        for (var j=0; j< subscr.listeners.length; j++) {
          BS.EventTracker._addPendingListener(subscr.listeners[j])
        }
      }
    });
  },

  _callPendingListeners: function() {
    for (var k=0; k < this._toBeInvokedListeners.length; k++) {
      try {
        this._toBeInvokedListeners[k]();
      } catch (e) {
        BS.Log.error(e);
      }
    }
    this._toBeInvokedListeners = [];
  },

  _addPendingListener: function(lr) {
    if (!this._toBeInvokedListeners.include(lr)) {
      this._toBeInvokedListeners.push(lr);
    }
  },

  startTracking: function() {
    (function _callListeners() {
      setTimeout(function () {
        BS.EventTracker._callPendingListeners();
        _callListeners();
      }, BS.internalProperty('teamcity.ui.events.pollInterval') * 1000);
    })();
  },

  checkEvents: function() {
    BS.SubscriptionManager.checkNow();
  }
};

BS.Util = {

  /**
   * Escapes a string to make it safe to use in HTML and in HTML tag attributes
   * @param s string to be escaped
   * @return see above
   */
  escape: function(s) {
    if (typeof s !== 'string') return s;
    return s.escapeHTML().replace(/"/g, "&quot;").replace(/'/g, "&#39;");
  },

  /**
   * Remove prefix
   */
  removePrefix: function(s, prefix) {
    return s.startsWith(prefix) ? s.substring(prefix.length) : s;
  },

  removeSuffix: function(s, suffix) {
    var endIdx = s.lastIndexOf(suffix);
    return s >= 0 ? s.substring(0, endIdx) : s;
  },

  // Wraps an element into a position: relative container
  wrapRelative: function(element) {
    if ($j(element).parent().hasClass('posRel')) return $j(element).parent();
    return $j(element).wrap('<div class="posRel"/>').parent();
  },

  extractParam: function(paramName, paramsString){
    if (typeof paramsString == 'undefined') {
      paramsString = window.location.search.substring(1);
    }
    var paramsArray = paramsString.split('&');
    for (var i = 0; i < paramsArray.length; i++) {
      var paramPair = paramsArray[i].split('=');
      if (paramPair[0] == paramName) {
        return paramPair[1];
      }
    }
  },


  place: function(element, x, y) {
    $(element).setStyle({left: x + 'px', top: y + 'px'});
  },

  center: function(elementToPlace, container) {
    var pos = BS.Util.computeCenter(elementToPlace, container);
    BS.Util.place(elementToPlace, pos[0], pos[1]);
  },

  // computes x and y so that element is shown centered vertically relative to the window
  // and horizontally relative to the container
  computeCenter: function(elementToPlace, container) {
    if (!container) {
      container = $('mainContent');
    }

    elementToPlace = $(elementToPlace);

    var containerDim = container.getDimensions();
    var containerPos = container.cumulativeOffset();
    var windowSize = BS.Util.windowSize();

    // to obtain element dimensions we have to show it
    var oldVisibility = elementToPlace.style.visibility;
    var oldDisplay = elementToPlace.style.display;
    elementToPlace.setStyle({visibility: 'hidden', display: 'block'});
    var dim = elementToPlace.getDimensions();
    elementToPlace.setStyle({visibility: oldVisibility, display: oldDisplay});
    var x = 0;
    var y = Math.round(this._scrollTop() + (windowSize[1] - dim.height) / 2);

    // check if container is wider than visible area
    if (containerDim.width > windowSize[0]) {
      // position within window instead of container
      x = Math.round(this._scrollLeft() + (windowSize[0] - dim.width) / 2);
    } else {
      x = Math.round(containerPos[0] + (containerDim.width - dim.width) / 2);
    }

    // Make sure dialog fits into screen boundaries
    if (_.isElement(container) && container.id == 'mainContent') {
      y = Math.max(y, 0);
    }

    return [x, y];
  },

  _scrollTop: function() {
    return $j(window).scrollTop();
  },

  _scrollLeft: function() {
    return $j(window).scrollLeft();
  },

  windowSize: function(win) {
    var $window = $j(win || window);

    return [$window.width(), $window.height()];
  },

  placeNearElement: function(elementToPlace, element, shift) {
    if (!shift) {
      shift = {};
      shift.x = 0;
      shift.y = 15;
    }

    element = $(element);

    var pos = element.positionedOffset();
    var x = pos[0] + shift.x;
    var y = pos[1] + shift.y;

    BS.Util.place(elementToPlace, x, y);
  },

  showNearElement: function(near_element, element_to_show, x_shift) {
    var menuDiv = $(element_to_show);
    if (typeof x_shift == 'undefined') {
      x_shift = -180;
    }
    BS.Util.placeNearElement(menuDiv, near_element, {x: x_shift, y: 21});
    BS.Hider.showDivWithTimeout(menuDiv, {hideOnMouseOut: false});
  },

  /**
   * @param {Node|string} element - element or id
   * @returns {boolean}
   */
  visible: function(element) {
    return jQuery($(element)).is(':visible');
  },

  /**
   * @param {Node|string|Jquery} element - element, id or jQuery object
   * @returns {Node}
   */
  toElement: function(element) {
    return jQuery($(element)).get(0)
  },

  /**
   * @param {Node|string|Jquery} element - element, id or jQuery object
   * @returns {Array<Node>}
   */
  toElements: function(element) {
    return jQuery($(element)).get()
  },

  /**
   * @param {Node|string} - element or id
   * ...
   */
  show: function() {
    var elements = Array.from(arguments).map(BS.Util.toElements).reduce(
      function(acc, els) {
        return acc.concat(els);
      },
      []
    );
    return ReactUI.showHide(elements, true).then(function() {
      // https://elements.polymer-project.org/elements/iron-list#resizing
      elements.forEach(function(element) {
        Array.prototype.forEach.call(element.querySelectorAll('iron-list'), function(list) {
          list.fire('iron-resize');
        });
      });
    });
  },

  /**
   * @param {Node|string} - element or id
   * ...
   */
  hide: function() {
    var elements = Array.from(arguments).map(BS.Util.toElements).reduce(
      function(acc, els) {
        return acc.concat(els);
      },
      []
    );
    return ReactUI.showHide(elements, false);
  },

  /**
   * A helper for a case when there is a chooser defining some kind of mode
   * and a page should show different elements depending on which mode was chosen.
   *
   * To use this function add some css class to all the dependent elements
   * and add the class for each visibility mode, e.g. chooser has 2 values
   * mode1 and mode2 and there are 2 elements which depend on selected value.
   * If they have css classes like this:
   *
   * &lt;div class="dependent mode1"/>
   * &lt;div class="dependent mode2"/>
   *
   * then this function will updated their visibility according to selected mode:
   * first div will be visible for mode1, the second - for mode2.
   *
   * @param mode selected mode
   * @param commonClass a common css class for all elements which visibility depends on selected mode
   * @param resetHiddenElements if true all the fields will be reset to their default value (empty
   * string for text, password, file fields and first option for checkboxes).
   * @param modeClassMap a mapping between selected value and a css class, useful when
   * values are long, if not specified assume css class equals mode
   */
  toggleDependentElements: function(mode, commonClass, resetHiddenElements, modeClassMap) {
    var classToShow = modeClassMap && modeClassMap[mode];
    if (!classToShow) {
      classToShow = mode;
    }

    var hideSelector = '.' + commonClass + ':not(.' + classToShow + ')';
    $j(hideSelector).hide();
    if (resetHiddenElements) {
      $j(hideSelector + ' input:text').val('');
      $j(hideSelector + ' input:password').val('');
      $j(hideSelector + ' input:file').val('');
      $j(hideSelector + ' select').prop('selectedIndex', 0);
      $j(hideSelector + ' textarea').val('');
    }
    $j('.' + commonClass + '.' + classToShow).show();
  },

  toggleVisible: function() {
    for (var i = 0; i < arguments.length; i++) {
      var element = $(arguments[i]);
      jQuery(element).toggle();
    }
  },

  isParameterIgnored : function(element) {
    return !element || $j(element).parents('.non_serializable_form_elements_container').length != 0
  },

  isPasswordInput: function(input) {
    return input.type === 'password' || input.hasAttribute('data-imitate-password')
  },

  getPasswordInputs: function(form) {
    return Form.getInputs(form).filter(BS.Util.isPasswordInput);
  },

  //neuro: this is basically copy fo prototype.Form.serialize but with 1.5 contract (send disabled and all submits)
  serializeForm: function(form) {
    var elements = Form.getElements(form);
    var jQueryElementPrefix = BS.jQueryDropdown.namePrefix;
    elements = elements.filter(function(element) {
      return !BS.Util.isPasswordInput(element)
             && element.name.indexOf('prop:encrypted') == -1
             && !element.name.endsWith(jQueryElementPrefix)
             && !BS.Util.isParameterIgnored(element)
          ;
    });

    var key, value, submitted = false, submit;

    var data = elements.inject({ }, function(result, element) {
      var cm = $j(element).data('cm');
      if (cm != null) {
        cm.save();
      }
      if (element.name) {
        key = element.name; value = $(element).getValue();
        if (value != null && (element.type != 'submit' || (!submitted &&
            submit !== false && (!submit || key == submit) && (submitted = true)))) {
          if (key in result && key !== 'tc-csrf-token') {
            // a key is already present; construct an array of values
            if (!_.isArray(result[key])) result[key] = [result[key]];
            result[key].push(value);
          }
          else result[key] = value;
        }
      }
      return result;
    });

    return Object.toQueryString(data);
  },

  //neuro: using _wasDisabled to remember state
  disableFormTemp: function(form, elemsFilter) {
    var disabledElems = [];
    for (var i = 0; i < form.elements.length; i++) {
      var element = form.elements[i];
      if (!elemsFilter || elemsFilter(element)) {
        this.disableInputTemp(element);
        disabledElems.push(element);
      }
    }
    BS.VisibilityHandlers.updateVisibility(form);
    return disabledElems;
  },

  isDisabled: function(input) {
    return input.disabled == 'disabled' || input.disabled;
  },

  disableInputTemp: function(input) {
    input.blur();
    if (this.isDisabled(input)) {
      input._wasDisabled = true;
    } else {
      input.disabled = 'disabled';
      var cm = $j(input).data('cm');
      if (cm != null) {
        cm.setOption('readOnly', true);
      }
    }
  },

  reenableInput: function(input) {
    if (typeof input._wasDisabled == 'undefined') {
      input.disabled = '';
      var cm = $j(input).data('cm');
      if (cm != null) {
        cm.setOption('readOnly', false);
      }
    } else {
      input._wasDisabled = undefined;
    }
  },

  //neuro: using _wasDisabled to restore state
  reenableForm: function(form, elemsFilter) {
    if (form && form.elements) {
      for (var i = 0; i < form.elements.length; i++) {
        var element = form.elements[i];
        if (!elemsFilter || elemsFilter(element)) {
          this.reenableInput(element);
        }
      }
    }
    BS.VisibilityHandlers.updateVisibility(form);
  },

  shiftToFitPage: function(el) {
    el = $(el);

    if (!el || el.hasClassName('modalDialogFixed')) return;

    // Fix for TW-10259.
    var overflow = el.style.overflow;
    if (BS.Browser.opera) { el.style.overflow = 'visible'; }

    var winSize = BS.Util.windowSize();
    var scrollLeft = BS.Util._scrollLeft();
    var pos = el.positionedOffset();
    var dim = el.getDimensions();
    var maxPageX = winSize[0] + scrollLeft;
    var minElemX = pos[0];
    var maxElemX = pos[0] + dim.width;

    if (minElemX < scrollLeft) {
      // if element is hidden by scroller
      el.style.left = (10 + scrollLeft) + 'px';
    } else if (maxElemX > maxPageX && dim.width < maxPageX) {
      // element maximum position by X is outside visible area
      el.style.left = (maxPageX - dim.width - 20) + 'px';
    } else if (dim.width >= maxPageX) {
      // element width is more than visible area
      el.style.left = '10px';
    }

    if (BS.Browser.opera) { el.style.overflow = overflow; }
  },

  showHelp: function(event, url, options) {
    Event.stop(event);
    var parts = url.split('#');
    if (parts.length == 2) {
      BS.Util.popupWindow(
        parts[0] + '#' + (options.preservePlus ? parts[1] : parts[1].replace(/\+/g, '')),
        "tcHelp",
        options
      );
    }
    else {
      BS.Util.popupWindow(url, "tcHelp", options);
    }
  },

  popupWindow: function(url, target, options) {
    target = target || '_blank';
    options = options || {};

    var width = options.width || 1000;
    var height = options.height || 600;
    var safe = options.safe !== false;
    var opener = options.opener || window;

    // noinspection SpellCheckingInspection
    var w = opener.open(
      url,
      target,
      'toolbar=no,scrollbars=yes,resizable=yes,width=' + width + ',height=' + height + (safe ? ',noopener=yes,noreferrer=yes' : '')
    );

    try {
      w.focus();
    } catch(e) {
      // no need catch
    }
    return w;
  },

  hideSuccessMessages: function() {
    if (BS._shownMessages) {
      for (var id in BS._shownMessages) {
        var el = $(id);
        if (el && BS._shownMessages[id] == 'info') {
          el.style.visibility = 'hidden';
        }
      }
      BS._shownMessages = {};
    }
  },

  addWordToTextArea: function(textarea, word) {
    var initialValue = textarea.value;
    if (initialValue.length == 0) {
      textarea.value = word;
    } else {
      textarea.value = initialValue + " " + word;
    }
  },

  processError: function(e) {
    if (e.message) {
      alert(e.message);
    } else {
      alert(e.toString());
    }
  },

  changeChildrenColor: function(parent, options) {
    var color = options.color;
    var bgColor = options.backgroundColor;
    var filter = options.filter;

    var childNodes = parent.childNodes;
    for (var i=0; i<childNodes.length; i++) {
      if (filter && !filter(childNodes[i])) continue;
      if (childNodes[i].style) {
        if (color != null) {
          childNodes[i].style.color = color;
        }

        if (bgColor != null) {
          childNodes[i].style.backgroundColor = bgColor;
        }
      }
    }
  },

  documentRoot: function(transport) {
    if (!transport.responseXML) return null;
    return transport.responseXML.documentElement;
  },

  trimSpaces: function(str) {
    return str.replace(/^\s+(.*)/, "$1").replace(/(.*?)\s+$/, "$1");
  },

  makeBreakable: function(text, regex) {
    regex = regex ? new RegExp("(" + regex + ")", "g") : /(.{60})/g;

    return text.replace(regex, "$1<wbr/>");
  },

  /*
  * Formats time in format 23h:33m:21s
  * If includeSeconds == false, seconds are not shown
  * */
  formatSeconds: function(seconds, includeSeconds) {
    if (seconds < 0) return "N/A";
    if (seconds == 0) return "&lt;1s";

    var result = "";
    var t = parseInt(seconds);

    if (t >= 3600) {
      var hours = Math.floor(t / 3600);
      t -= hours*3600;
      result += hours + "h"
    }

    if (t >= 60) {
      var mins = Math.floor(t / 60);
      t -= mins*60;
      if (result != "") {
        result += ":";
      }
      result += mins + "m";
    }

    if (t > 0 && includeSeconds) {
      seconds = t;
      if (result != "") {
        result += ":";
      }
      result += seconds + "s";
    }
    else if (result == "") {
      result = "&lt;1m";
    }
    return result;
  },

  /**
   * Turns ON all checkboxes with specified name in the specified form
   * @param form
   * @param checkboxName
   */
  selectAll: function(form, checkboxName) {
    this._setChecked(form, checkboxName, true);
  },

  /**
   * Turns OFF all checkboxes with specified name in the specified form
   * @param form
   * @param checkboxName
   */
  unselectAll: function(form, checkboxName) {
    this._setChecked(form, checkboxName, false);
  },

  /**
   * Turns array of the selected checkboxes values
   * @param form
   * @param checkboxName
   */
  getSelectedValues: function(form, checkboxName) {
    var result = [];
    var checkboxes = Form.getInputs(form, "checkbox", checkboxName);
    for (var i=0; i<checkboxes.length; i++) {
      if (checkboxes[i].checked) {
        result.push(checkboxes[i].value);
      }
    }
    return result;
  },

  _setChecked: function(form, checkboxName, checked) {
    var checkboxes = Form.getInputs(form, "checkbox", checkboxName);
    for (var i=0; i<checkboxes.length; i++) {
      if (!checkboxes[i].disabled) {
        checkboxes[i].checked = checked;
      }
    }
  },

  descendantOf: function(child, parent) {
    while (child != null) {
      if (child === parent) return true;
      child = child.parentNode;
    }
    return false;
  },

  isDetached: function(elem) {
    if (elem.id) return $(elem.id) !== elem;

    if (elem === document.documentElement || elem === window || elem === document) return false;
    if (elem.parentNode == null) return true;

    return BS.Util.isDetached(elem.parentNode);
  },

  /**
   * Executes `toRun` as soon as node with `element_id` is attached to DOM
   * OR timeout ms elapsed (result of last existence check is passed to the
   * `toRun` as first argument)
   *
   * @param {String} element_id
   * @param {Function} toRun
   * @param {int} [timeout=1000] in ms
   */
  runWithElement: function(element_id, toRun, timeout) {
    if (!timeout) timeout = 1000;

    BS.WaitFor(function() {
      return $(element_id) && !BS.Util.isDetached($(element_id));
    }, toRun, timeout / 1000.0);
  },

  setTitle: function(title) {
    document.title = title ? title + " \u2014 TeamCity" : "TeamCity";
  },

  capitalize: function(s) {
    return s.replace(/\s+(\w)/g, function(match, chr) {
      return ' ' + chr.toUpperCase();
    });
  },

  fadeOutAndDelete: function(jQuerySelector) {
    $j(jQuerySelector).fadeOut("fast", function() {
      $j(this).remove();
    });
  },

  createDelayedInvocator: function(fun, delay) {
    return {
      _timeoutId: null,
      invoke: function() {
        if (this._timeoutId) {
          clearTimeout(this._timeoutId);
        }
        var that = this;
        this._timeoutId = setTimeout(function() {
          that._timeoutId = null;
          fun();
        }, delay);
      }
    };
  },

  // Escapes IDs containing dots and colons to make them usable as jQuery selectors
  escapeId: function(id) {
    if (id.toString().match(/^#/)) return id;

    //TODO: consider all possible variants: !"#$%&'()*+,./:;<=>?@[\]^`{|}~
    return '#' + id.toString().replace(/(:|\.)/g,'\\$1');
  },

  // Returns element's direct children that are text nodes
  getTextChildren: function(elemId) {
    return $j(BS.Util.escapeId(elemId)).contents().filter(function () {
      return this.nodeType == 3;
    });
  },

  // OS-specific line feed
  getLineFeed: function() {
    return navigator.userAgent.toLowerCase().match(/windows/) ? '\r\n' : '\n';
  },

  isModifierKey: function(e) {
    return e && (e.ctrlKey || e.altKey || e.shiftKey || e.metaKey);
  },

  installPlaceHolder: function(inputField, placeHolderText, setPlaceHolderText) {
    inputField = $(inputField);
    placeHolderText = placeHolderText.trim();

    if (setPlaceHolderText) {
      inputField.value = placeHolderText;
    }

    if (inputField.value.trim() == placeHolderText) {
      inputField.style.color = "gray";
    }

    inputField.on('focus', function() {
      if (this.value.trim() == placeHolderText) {
        this.value = "";
        this.style.color = "black";
      }
    });

    inputField.on('blur', function() {
      if (this.value.trim().length == 0) {
        this.value = placeHolderText;
        this.style.color = "gray";
      }
    });
  },

  paramsFromHash: function(separator) {
    var parsed = {};
    var hash = document.location.hash;
    if (hash.length > 1) {
      hash = hash.substring(1);
      var params = hash.split(separator || '&');
      for (var i=0; i<params.length; i++) {
        var eqsgn = params[i].indexOf('=');
        if (eqsgn == -1) continue;

        var name = params[i].substring(0, eqsgn);
        parsed[name] = params[i].substring(eqsgn+1);
      }
    }
    return parsed;
  },

  removeParamFromHash: function(paramName, separator, skipHistory) {
    var parsed = BS.Util.paramsFromHash(separator);
    var newParams = [];

    for (var key in parsed) {
      if (parsed.hasOwnProperty(key) && key !== paramName) {
        newParams.push(key);
        newParams.push(parsed[key]);
      }
    }

    BS.Util.setParamsInHash(newParams, separator, skipHistory)
  },

  setParamsInHash: function(params, separator, skipHistory) {
    var newHash = "";
    for (var i=0; i<params.length; i+=2) {
      newHash += params[i] + "=" + params[i+1] + separator;
    }

    if (newHash.length > 0) {
      newHash = newHash.substring(0, newHash.length - 1); //remove last separator
    }

    if (skipHistory) {
      // will replace location to avoid it appearance in browser history
      var url = document.location.href;
      var hashIdx = url.indexOf('#');
      if (hashIdx != -1) {
        url = url.substring(0, hashIdx);
      }
      url += '#' + newHash;
      document.location.replace(url);
    } else {
      document.location.hash = newHash;
    }
  },

  syncValues: function(sourceElem, targetElem) {
    var srcVal = sourceElem.value;
    var destVal = targetElem.value;
    var generated = targetElem.getAttribute('generated');
    if (destVal.length == 0 || (generated != null && destVal == generated)) {
      targetElem.value = srcVal;
      targetElem.setAttribute('generated', srcVal);
      $j(targetElem).trigger("keyup");
    }
  },

  _visibilityAPI: null,

  isPageVisible: function() {
    if (this._visibilityAPI == null) {
      this._visibilityAPI = BS.PageVisibility.detect();
    }
    return !this._visibilityAPI.supported || !document[this._visibilityAPI.hiddenProperty];
  },

  escapeRegExp: function(str) {
    return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
  }
};

//==========================================================================
/**
Public API:

BS.Hider.showDivWithTimeout('id');
BS.Hider.startHidingDiv('id', delay = 500);
BS.Hider.stopHidingDiv('id');
BS.Hider.hideDiv('id');


BS.Hider.hideAll('id');

*/

BS.Hider = {
  hidingDivs: {},
  allDivs: {},
  afterHideFuncs: {},

  hasVisiblePopups: function() {
    return !$j.isEmptyObject(this.allDivs);
  },

  _currentZindex: function() {
    while (this._shownStack.length > 0) {
      var id = this._shownStack[this._shownStack.length - 1];
      if ($(id)) {
        return parseInt($(id).style.zIndex, 10) + 5;
      }
      this._shownStack.pop();
    }
    return 10;
  },

  addHideFunction: function(id, hideFunction) {
    if (typeof this.afterHideFuncs[id] == 'function') {
      var old = this.afterHideFuncs[id];
      this.afterHideFuncs[id] = function() {
        hideFunction();
        old();
      }
    }
    else {
      this.afterHideFuncs[id] = hideFunction;
    }
  },

  showDivWithTimeout: function(id, options) {
    var element = $(id);
    id = element.id;

    if (!options) {
      options = {};
    }

    if (options.hideOnMouseOut === undefined) {
      options.hideOnMouseOut = true;
    }

    if (options.hideOnMouseClickOutside === undefined) {
      options.hideOnMouseClickOutside = true;
    }

    if (options.draggable === undefined) {
      options.draggable = false;
    }

    if (!_.isElement(options.dragHandle)) {
      options.draggable = false;
    }

    var currentZIndex = this._currentZindex();
    if (options.zIndex === undefined || options.zIndex < currentZIndex) {
      options.zIndex = currentZIndex;
    }

    if (options.afterHideFunc != undefined) {
      this.addHideFunction(id, options.afterHideFunc);
    }

    // Modal dialog's position is defined in CSS
    if (!element.hasClassName('modalDialog')) {
      element.style.position = 'absolute';
    }

    element.style.zIndex = "" + options.zIndex;

    return BS.Util.show(id).then(function() {
      BS.Util.shiftToFitPage(id);

      this.allDivs[id] = id;

      this.stopHidingDiv(id); // if was started previously

      this._shownStack.indexOf(id) < 0 && this._shownStack.push(id);
      this._setupHandlers(id, options);

      BS.VisibilityHandlers.updateVisibility(id);

      element._hideOnMouseClickOutside = false;
      if (options.hideOnMouseClickOutside) {
        setTimeout(function() {
          element._hideOnMouseClickOutside = true;
        }.bind(this), 10);
      }

      if (options.draggable && !element._draggable) {
        element._draggable = new Draggable(id, {
          starteffect: function() {},
          endeffect: function() {},
          change: function() {
            $j(window).off('resize.modalDialog scroll.modalDialog');
          },
          handle: options.dragHandle
        });
      }
    }.bind(this));
  },

  startHidingDiv: function(id, delay) {
    if (delay == undefined) {
      delay = 500;
    }

    id = $(id).id;

    this.stopHidingDiv(id, true);

    var that = this;
    this.hidingDivs[id] = setTimeout(function() {
      if (that.hidingDivs[id]) {

        // Hide popup only if it is not pinned
        var isPinned;
        $j('span.toggle').each(function() {
          if (this.getAttribute('data-popup') == id) {
            isPinned = this.getAttribute('data-pinned') === 'true';
            return false;
          }
        });
        if (!isPinned) {
          that.hideDivSingle(id);
        }

      }
    }, delay);
  },

  /* Hides the whole stack of open popups */
  hideDiv: function(id) {
    var divPos = -1;
    for (var i=0; i<this._shownStack.length; i++) {
      if (this._shownStack[i] == id) {
        divPos = i;
        break;
      }
    }

    if (divPos != -1) {
      var numShown = this._shownStack.length - divPos;
      while (numShown > 0) {
        var topId = this._shownStack.pop();
        this.hideDivSingle(topId);
        numShown--;
      }
    }

    if (this.afterHideFuncs[id]) {
      this.afterHideFuncs[id]();
      delete this.afterHideFuncs[id];
    }
  },

  /* Hides a single popup */
  hideDivSingle: function(id) {
    this.stopHidingDiv(id, true);
    delete this.allDivs[id];

    // If there is a relevant toggle control - remove any attributes from it:
    $j('span.toggle').each(function() {
      if (this.getAttribute('data-popup') == id) {
        this.removeAttribute('data-pinned');
        this.removeAttribute('data-popup');
        return false;
      }
    });


    var elem = $(id);

    if (elem && elem._draggable) {
      elem._draggable.destroy();
      elem._draggable = null;
    }
    Event.stopObserving(elem);
    BS.Util.hide(elem);

    this._runAfterHide(id);
  },

  _runAfterHide: function(id) {
    if (this.afterHideFuncs[id]) {
      this.afterHideFuncs[id]();
      delete this.afterHideFuncs[id];
    }
  },

  stopHidingDiv: function(id, thisDivOnly) {
    var idAttr = $(id).id;
    if (this.hidingDivs[idAttr]) {
      if (thisDivOnly) {
        clearTimeout(this.hidingDivs[idAttr]);
      } else {
        for (var i=0; i<this._shownStack.length; i++) {
          clearTimeout(this._shownStack[i]);
          if (this._shownStack[i] == idAttr) {
            break;
          }
        }
      }

      delete this.hidingDivs[idAttr];
    }
  },

  /**
   * Hides all popups or all popups with zIndex greater than zIndex of popup having id provided
   * @param {DOMElement} stopOn - id of popup to break hiding process on
   */
  hideAll: function(stopOn) {
    var divs = [];
    for(var divId in this.allDivs) {
      if (!$(divId)) continue;
      divs.push($(divId));
    }

    // sort divs according to their z-index
    divs.sort(function(div1, div2) {
      var zI1 = parseInt(div1.style.zIndex, 10);
      var zI2 = parseInt(div2.style.zIndex, 10);
      return zI1 - zI2;
    });

    for (var i=divs.length-1; i>=0; i--) {
      var div = divs[i];
      if (div == stopOn) {
        break;
      }
      if (!div._hideOnMouseClickOutside) break;
      this.hideDiv(div.id);
      div._hideOnMouseClickOutside = true;
    }

    // Reset 'pinned' state
    $j('span.toggle').each(function() {
      if (stopOn && this.getAttribute('data-popup') == stopOn.id) return false;

      this.removeAttribute('data-pinned');
      this.removeAttribute('data-popup');
    })
  },

  _shownStack: [],

  _setupHandlers: function(id, options) {
    var el = $(id);

    if (options.hideOnMouseOut) {
      el.on("mouseout", function() {
        // don't hide the popup if a certain element is provided as override (TW-18908)
        if (document.activeElement) {
          if (options.overrideHideIfActive && document.activeElement == $(options.overrideHideIfActive)) {
            return;
          }
        }

        // we should not hide popup on mouse out if there are visible popups shown after this popup
        var top = BS.Hider._shownStack[BS.Hider._shownStack.length - 1];

        if (top != id) {
          return;
        }

        if (typeof options.hideOnMouseOut == 'function') {
          if (!options.hideOnMouseOut())
            return;
        }

        BS.Hider.startHidingDiv(id);
      });
    }

    el.on("mouseover", function() {
      BS.Hider.stopHidingDiv(id);
    });

    el.on("contextmenu", function() {
      $j('span.toggle').each(function() {
        if (this.getAttribute('data-popup') == id) {
          this.setAttribute('data-pinned', 'true');
        }
      });
    });
  },

  _escapeHandler: function(event) {
    if (this._shownStack.length != 0 && event.keyCode == Event.KEY_ESC) {
      var id = this._shownStack[this._shownStack.length - 1];
      BS.Hider.hideDiv(id);
      return false;
    }
  }
};

$j(document).on("click", function(e) {
  var t = e.target;
  // Don't hide popups if click occurred inside one of the popups
  var stopOn = null;
  for(var div in BS.Hider.allDivs) {
    var elem = $(div);
    if (!elem) continue;
    if (BS.Util.descendantOf(t, elem)) {
      stopOn = elem;
      break;
    }
  }
  BS.Hider.hideAll(stopOn);
});

$j(document).on("keydown", BS.Hider._escapeHandler.bind(BS.Hider));


//==========================================================================

BS.Navigation = {
    items: [],

    siblingsNavType: null,

    discoverMode: function(){
      var adminPart = this.items.length > 0 && window.location.href.indexOf('admin') > -1;
      var edit = adminPart && (window.location.href.indexOf('admin/edit') > -1 || window.location.href.indexOf('admin/attachBuildTypeVcsRoots'));
      var create = adminPart && window.location.href.indexOf('admin/create') > -1;
      return {adminPart: adminPart, editMode: edit, createMode: create};
    },

    writeCompactNavigation: function () {
      var mode = BS.Navigation.discoverMode();
      var adminPart = mode.adminPart;
      var edit = mode.editMode;
      var create = mode.createMode;
      $j('#restBreadcrumbs').css('display', 'flex');
      if (adminPart && !edit && !create){
        $j('#restPageTitle').html(this.getTitleHtml(this.items[0])).css('display', 'flex');
      } else {
        if (this.items.length > 1 || this.items[0]?.projectId) {
          $j('#restNavigation').html(this.getCompactItemsHtml()).css('display', 'block');
        }
        if (create || edit || !adminPart) {
          var last = this.items[this.items.length - 1];
          $j('#restPageTitle').html(this.getTitleHtml(last, '', edit)).css('display', 'flex');
        }
        if (!adminPart) {
          var descriptionHtml = this.getDescriptionHtml(last);
          if (descriptionHtml != undefined && descriptionHtml > '') {
            $j('#restPageDescription').html(descriptionHtml).css('display', 'block');
          }
        }
      }
    },

    writeBreadcrumbs: function() {
      if (this.items.length == 0) return;

      if ($j('#restBreadcrumbs').length > 0) {
        this.writeCompactNavigation();
      }
      $j(document).trigger("bs.navigationRendered");
    },

    getCompactItemsHtml: function () {
      var result = "";
      var lastIndex = this.items.length  - 1;
      if (this.items[lastIndex].title == undefined || this.items[lastIndex].title.trim().length == 0){
        lastIndex--;
      }
      for (var i = 0; i < lastIndex; i++) {
        var item = this.items[i];
        if (item != undefined && item.title != undefined && item.title.length > 0){
          result += this._writeCompactItem(this.items[i]);
        }
      }
      result += this._writeCompactItem(this.items[lastIndex], true);
      return result;
    },

    getTitleHtml: function (item, li_class, editMode) {
      var content = item.title, idx = content.indexOf("<small>");
      var __ret = this._prepareAttributes(li_class, item);
      var li_classes = __ret.li_classes;
      var li_attributes = __ret.li_attributes;
      var icon = this._getIcon(item);

      var titleContent = (idx > -1 ? content.substr(0, idx) : item.title);
      if (item.url) {
        titleContent = "<a href='" + item.url + "'>" + titleContent + "</a>";
      }

      return '<div class="' + $j.trim(li_classes) + '"' + li_attributes + '><span class="contentWrapper">' +
             icon + titleContent + '</span></div>';
    },

    getDescriptionHtml: function (item) {
      var content = item.title, idx = content.indexOf("<small>");
      return (idx > -1 ? content.substr(idx + "<small>".length + 1, content.length - ("</small>".length + 1) - (idx + "<small>".length + 1)) : undefined);
    },

    _getIcon: function (navItem) {
      var iconClassName = '';
      if (navItem.siblingsTree || navItem.siblings) {
        iconClassName += ' hasSiblings'
      }

      if (ReactUI) {
        var type;
        if (navItem.projectId) {
          type = "project";
        } else if (navItem.itemClass === "buildTypeTemplate") {
          type = "template";
        } else if (navItem.buildTypeId) {
          type = "buildType";
        }
        var mode = BS.Navigation.discoverMode();

        return type ? ReactUI.createAndRenderStatic(ReactUI.ProjectOrBuildTypeIcon, {
          type: type,
          composite: navItem.composite,
          status: navItem.status,
          edit: mode.adminPart,
          size: 'L',
          className: 'projectOrBuildTypeIcon' + iconClassName,
        }) : ''
      } else {
        if (navItem.projectId) {
          iconClassName = 'projectIcon project-icon';
        } else if (navItem.itemClass === 'buildTypeTemplate') {
          iconClassName = 'buildTypeTemplate-icon';
        } else if (navItem.buildTypeId) {
          iconClassName = 'buildTypeIcon buildType-icon';
          if (navItem.composite) {
            iconClassName += ' buildType-icon_composite';
          }
        }

        return iconClassName
          ? '<i class="tc-icon_before icon16 ' + iconClassName + ' icon_disabled"></i>'
          : '';
      }
    },

    _prepareAttributes: function (li_class, navItem) {
      var li_classes = [], li_attributes = [];

      li_classes.push(li_class);

      if (navItem.selected) {
        li_classes.push("selected");
      }

      if (navItem.itemClass) {
        li_classes.push(navItem.itemClass);
      }

      if (navItem.projectId) {
        li_attributes.push('data-projectId="' + navItem.projectId + '"');
      }
      if (navItem.buildTypeId) {
        li_attributes.push('data-buildTypeId="' + navItem.buildTypeId + '"');
      }
      if (navItem.templateId) {
        li_attributes.push('data-templateId="' + navItem.templateId + '"');
      }

      if (navItem.siblingsTree && navItem.siblingsTree.parentId) {
        li_attributes.push('data-parentId="' + navItem.siblingsTree.parentId + '"');
      }

      li_classes = li_classes.join(" ");
      li_attributes = li_attributes.join(" ");
      return {li_classes: li_classes, li_attributes: li_attributes};
    },

    _writeCompactItem: function(navItem, isLast) {

      var content = navItem.title, idx = content.indexOf("<small>");

      var __ret = this._prepareAttributes(isLast ? "last" : "", navItem);
      var li_classes = __ret.li_classes;
      var li_attributes = __ret.li_attributes;
      var mode = BS.Navigation.discoverMode();
      var adminPart = mode.adminPart;
      const isHierarchyItem = navItem.projectId || navItem.itemClass === "buildTypeTemplate" || navItem.buildTypeId;
      var leftIconId = isLast && adminPart
                         ? "settingsIcon"
                         : navItem.buildTypeId
                           ? navItem.composite ? "buildTypeCompositeIcon" : "buildTypeIcon"
                           : null;
      const leftIcon = leftIconId ? document.getElementById(leftIconId).innerHTML.trim() : null;
      var rightIcon = isHierarchyItem
                        ? document.getElementById("chevronIcon").innerHTML.trim()
                        : null;

      var titleText = (idx > -1 ? navItem.title.substr(0, idx) : navItem.title).trim();

      content = navItem.url ? '<a href="' + navItem.url + '" >' + titleText + '</a>' : titleText;

      return '<li class="' + $j.trim(li_classes) + '"' + li_attributes + '><span class="nowrap"><span class="contentWrapper">' +
        (leftIcon ? '<span class="leftIcon">' + leftIcon + '</span>' : '') +
        content +
        (rightIcon ? '<button type="button" class="iWrapper">' + rightIcon + '</button>' : '') +
        '</span>' + (!isLast ? "<span class='tc-icon_breadcrumb_slash'></span>" : '') + '</span></li>';
    },

    fromUrl: function(idToFind, idToReplace, suffixIfNotFound, removeTabParam) {
      var url = document.location.href;
      var hashIdx = url.indexOf('#');
      if (hashIdx != -1) {
        url = url.substring(0, hashIdx);
      }
      if (removeTabParam) {
        url = url.replace(/tab=[^&]+&*/, "");
      }
      if (!url.include(idToFind) && url.include(encodeURIComponent(idToFind))) {
        idToFind = encodeURIComponent(idToFind);
      }
      if (url.include("=" + idToFind)) {
        return url.replace("=" + idToFind, "=" + (idToReplace || "{id}"));
      }
      return suffixIfNotFound ? url + suffixIfNotFound : url;
    },

    installHealthItems: function () {
        var healthIndicators = $j('.healthItemIndicatorContainer').detach();
        var container = $j('#restPageTitle');
        var hi = {
          'class': 'breadcrumbHealthIndicators',
          'append': healthIndicators
        };
        $j('<div></div>', hi).appendTo(container);
        healthIndicators.show();
    }
};

//==========================================================================

BS.Highlight = function(element, options) {
  new Effect.Highlight(element, _.extend(options || {}, {
    startcolor: '#ffffcc',
    duration: 1.0,
    keepBackgroundImage: true
  }));
};


BS.Logout = function(logoutUrl) {
  BS.ajaxRequest(logoutUrl, {
    onComplete: function(transport) {
      window.localStorage.clear();

      ReactUI.serviceWorkers.cleanServiceWorkerCaches();

      BS.Cookie.clearAll();
      BS.XMLResponse.processRedirect(transport.responseXML);
    }
  });
};

BS.LogoutAllSessions = function(logoutAllSessionsUrl) {
  BS.confirm('This will also log out the current session. \nAre you sure you want to log out of all sessions?', function () {
    BS.ajaxRequest(logoutAllSessionsUrl, {
      onComplete: function(transport) {
        window.localStorage.clear();
        BS.Cookie.clearAll();
        BS.XMLResponse.processRedirect(transport.responseXML);
      }
    });
  }.bind(this));
};

BS.XMLResponse = {
  processModified: function(form, responseXML) {
    if (!responseXML) return;

    var rootElement = responseXML.documentElement;
    form.setModified(rootElement.firstChild && rootElement.firstChild.nodeValue == "modified");
  },

  processRedirect: function(responseXML) {
    if (!responseXML) return false;

    var rootElement = responseXML.documentElement;
    var redirect = rootElement.getElementsByTagName("redirect")[0];
    if (redirect && !redirect.firstChild.nodeValue.startsWith("javascript:")) {
      document.location.href = redirect.firstChild.nodeValue;
      return true;
    }
    return false;
  },

  /** Error handlers is an object with error handlers with names like onFieldError,
   * where 'field' is 'id' of the 'error' element in XML response.
   * The handler is called with 'this' == errorHandlers and XML error element goes as the first parameter.
   * To access text of the error node, use syntax 'param.firstChild.nodeValue'
   * */
  processErrors: function(responseXML, errorHandlers, generalErrorHandler) {
    var eNodes = this._getErrorNodes(responseXML);
    if (!eNodes || eNodes.length == 0) return false;

    var handled = false;
    for (var i=0; i<eNodes.length; i++) {
      var elem = eNodes.item(i);
      var id = elem.getAttribute("id");
      var funcName = "on" + id.charAt(0).toUpperCase() + id.substring(1) + "Error";
      var handler = errorHandlers[funcName] || errorHandlers[id];

      if (handler && typeof(handler) == 'function') {
        handler.apply(errorHandlers, [elem]);
        handled = true;
      } else if (generalErrorHandler) {
        generalErrorHandler(id, elem);
        handled = true;
      }
    }

    return handled;
  },

  _xmlErrorsXml: function(responseXml) {
    var errs = responseXml.getElementsByTagName("errors");
    if (!errs || errs.length == 0 || errs[0].getElementsByTagName("error").length == 0) return [];
    var errorElements = errs[0].getElementsByTagName("error");
    var result = [];
    for (var i = 0; i < errorElements.length; i ++) {
      var e = errorElements[i];
      result.push([e.getAttribute("id"), e.firstChild.nodeValue]);
    }
    return result;
  },

  _getErrorNodes: function(responseXML) {
    if (!responseXML) {
      responseXML = $j.parseXML('<response><errors><error id="emptyResponse">Unexpected empty response</error></errors></response>');
    }
    var parentElement = responseXML.documentElement;
    if (parentElement == null) return null;

    var errorsNodes = parentElement.getElementsByTagName("errors");
    if (!errorsNodes || errorsNodes.length == 0) return null;
    var errorsNode = errorsNodes.item(0);
    return errorsNode.getElementsByTagName("error");
  }
};

BS.StopBuild = function(actionUrl, id, form) {
  if (form) {
    Form.disable(form);
  }

  BS.ajaxRequest(actionUrl + "?kill=" + id, {
    onComplete: function() {
      setTimeout(function() {
        BS.reload(true);
      }, 3000);
    }
  });

  return false;
};

/**
 * @deprecated
 */
BS.TableHighlighting = {
  createInitElementFunction: function () {
      var element = this;

      var f = function (element) {
        element = $(element);

        element.on("mouseover", function () {
          if (typeof(BS) == "undefined") return;

          BS.Util.changeChildrenColor(this.parentNode, {
            color: '#254193',
            backgroundColor: '#ffffcc',
            filter: function (elem) {
              return elem.nodeType == 1 && elem.className.indexOf("highlight") >= 0;
            }
          });
        }.bind(element));

        element.on("mouseout", function () {
          if (typeof(BS) == "undefined") return;
          BS.Util.changeChildrenColor(this.parentNode, {
            color: '',
            backgroundColor: '',
            filter: function (elem) {
              return elem.nodeType == 1 && elem.className.indexOf("highlight") >= 0;
            }
          });
        }.bind(element));
      };

      if (!element.nodeType) {
        // Old calling convention (Behaviour.js)
        return f;
      } else {
        // jQuery
        return f(element);
      }
    }
};

BS.Refreshable = {
  _poppedDialogs: {},
  registerPoppingOutDialog: function (refreshableId, dialogId) {
    if (!this._poppedDialogs[refreshableId]) {
      BS.Refreshable._poppedDialogs[refreshableId] = [];
    }

    if (this._poppedDialogs[refreshableId].indexOf(dialogId) === -1) {
      this._poppedDialogs[refreshableId].push(dialogId);
    }
  },
  loadedScripts: new Set(),
  /**
   * see more in TW-49330 Workaround for JS error "refresh is not a function"
   *
   * @param {String?} progressId
   * @param {String?} moreParameters
   * @param {Function?} afterComplete
   * @param {Number?} progressDelay
   *
   * @returns {Promise}
   */
  prototypeRefreshable: function(progressId, moreParameters, afterComplete, progressDelay) {

      var deferred = $j.Deferred();
      var container = $(this);

      if (!container) {
        BS.Log.error('prototypeRefreshable called without element');
        deferred.reject();
        return deferred.promise();
      }

      var containerId = $j(container).attr('id');

      // noinspection SpellCheckingInspection
    var pageUrl = $j(container).attr('data-pageurl');
      if (!pageUrl) {
        // In case url is empty in BS.ajaxRequest the request will be sent to the current URL due to underlying XMLHttpRequest behaviour
        pageUrl = window.location.pathname;
      }

      // noinspection SpellCheckingInspection
    var passJsp = $j(container).attr('data-passjsp');

      if (BS.ServerLink && !BS.ServerLink.isConnectionAvailable()) {
        BS.Log.info("Connection to server is not available. Refresh is not called.");
        deferred.resolve();
        return deferred.promise();
      }

      if (!moreParameters) {
        moreParameters = "";
      }

      let loadingTimeout;
      if (progressId && $(progressId)) {
        if (progressDelay) {
          loadingTimeout = setTimeout(() => BS.Util.show(progressId), progressDelay);
        } else {
          BS.Util.show(progressId);
        }
      }

      var myParams = passJsp ? "jsp=" + passJsp : "__fragmentId=" + containerId + "Inner";

      BS.ajaxRequest(pageUrl, {
        method: 'get',
        parameters: myParams + (moreParameters ? "&" + moreParameters : ""),
        onFailure: function() {
          BS.Log.warn("Failure while refreshing " + containerId);
          deferred.reject();
        },
        onComplete: async function(response) {
          var status = response.request.getStatus();
          var success = !status || (status >= 200 && status < 300);

          // Do nothing if request has failed (server was unavailable)
          if (success) {
            document.querySelectorAll('script').forEach(script => BS.Refreshable.loadedScripts.add(script.src));
            BS.Refreshable.detachReactRefreshableRoots(container);
            BS.stopObservingInContainers(container);
            BS.Refreshable.destroySortables(container);
            (BS.Refreshable._poppedDialogs[containerId] || []).each(function (id) {
              var element = $(id);
              while (element) {
                element.remove();
                element = $(id);
              }
            });
            delete BS.Refreshable._poppedDialogs[containerId];
            container.innerHTML = response.responseText;
            for (const script of container.querySelectorAll('script')) {
              const clone = document.createElement("script");
              if (script.src) {
                if (!BS.Refreshable.loadedScripts.has(script.src)) {
                  clone.src = script.src;
                  await new Promise((resolve, reject) => {
                    clone.addEventListener('load', resolve);
                    clone.addEventListener('error', reject);
                    script.parentNode.replaceChild(clone, script);
                  });
                  BS.Refreshable.loadedScripts.add(script.src);
                }
              } else {
                clone.innerHTML = script.innerHTML;
                script.parentNode.replaceChild(clone, script);
              }
            }
            BS.enableDisabled(container);
            if (loadingTimeout) {
              clearTimeout(loadingTimeout);
            }
            BS.Util.hide(progressId);
            _.isFunction(afterComplete) && afterComplete();
          }

          deferred.resolve();
        }
      });

      return deferred.promise();
  },
  /**
   * @deprecated (see more in TW-49330 Workaround for JS error "refresh is not a function")
   */
  createRefreshFunction: function () {
    return function() {
      BS.Log.error("This function was created by BS.createRefreshFunction which shouldn't be used any more.");
    }
  },

  destroySortables: function(container) {
    if (typeof(Sortable) == "undefined") return;

    if (!_.isEmpty(Sortable.sortables)) {
      Sortable.destroy(container);
      var children = container.getElementsByTagName('*'),
          l = children.length;

      for (var i = 0; i < l; i ++) {
        if (Sortable.sortables[children[i].id]) {
          Sortable.destroy(children[i]);
          BS.Log.debug("Destroying sortable under " + children[i].id);
          if (_.isEmpty(Sortable.sortables)) {
            return;
          }
        }
      }
    }
  },

  detachReactRefreshableRoots: function(container) {
    var roots = container.querySelectorAll('[data-react-refreshable-root]');
    for (var i = 0; i < roots.length; i++) {
      var element = roots[i];
      ReactUI.markAsUnused(element.id);
      var parent = element.parentNode;
      if (parent) {
        parent.removeChild(element);
      }
    }
  }
};

HTMLDivElement.prototype.refresh = BS.Refreshable.prototypeRefreshable;

HTMLDivElement.prototype.refresh_delayed = function() {
  if (!this._refresh_timer) {
    this._refresh_timer = setTimeout(function () {
      this._refresh_timer = null;
      if (document.body.contains(this)) {
        this.refresh();
      }
    }.bind(this), 300);
  }
};

/**
 * Executes `runWhenDone` as soon as `condition()` returns truthy value
 * OR `waitSeconds` seconds elapses; `condition()` return  value is
 * passed to `runWhenDone` handler
 *
 * @param {Function} condition
 * @param {Function} runWhenDone
 * @param {int} [waitSeconds=10]
 */
BS.WaitFor = function(condition, runWhenDone, waitSeconds) {
  if (!waitSeconds) waitSeconds = 10;
  var maxCount = waitSeconds * 1000 / 50;
  var counter = 0;

  var _waitForHandler = function() {
    var _condition = condition();
    if (!_condition && maxCount > counter++) {
      setTimeout(_waitForHandler, 50);
    }
    else {
      runWhenDone(_condition);
    }
  };
  _waitForHandler();
};

Event.observe(window, "unload", function() {
  BS.PeriodicalRefresh.stop();
});

BS.PeriodicalRefresh = {

  start: function (interval, refreshFunc) {
    if (this.executor) {
      this.executor.stop();
      this.executor = null;
    }

    this.executor = BS.periodicalExecutor(function () {
      return BS.reload(false, function () {
          })
          .then(function () {
            return refreshFunc();
          });
    }, interval * 1000);

    if (interval > 0) {
      this.executor.start();
    }
  },

  stop: function () {
    this.executor && this.executor.stop();
  }
};

(function($) {
  BS.InPlaceFilter = {
    _storedInitializers: {},
    applyFilter: function(containerId, filterField, afterFilterFunc, forceSearch) {
      var container = containerId instanceof $ ? containerId : $(BS.Util.escapeId(containerId));

      var keyword = filterField.value.toUpperCase();
      if (!forceSearch && keyword == this.prevKeyword) return;

      var narrowSearch = this.prevKeyword != null && keyword.indexOf(this.prevKeyword) != -1;
      this.prevKeyword = keyword;

      var elementsToFilter = container.find('.inplaceFiltered');

      var that = this;
      // Search and toggle option visibility
      elementsToFilter.each(function(i) {
        var elem = this;
        if (narrowSearch && !that.isVisible(elem)) return;

        if (!keyword) {
          that.showElement(elem, i);
        } else {
          that.performSearch(elem, keyword, i);
        }
      });

      this.toggleOptgroups(keyword, container, elementsToFilter);

      if (afterFilterFunc) {
        afterFilterFunc.call(this, filterField);
      }
    },

    performSearch: function(elem, keyword, idx) {
      var text = this.getContent(elem);
      var found = text.indexOf(keyword) > -1;
      if (!found) {
        this.hideElement(elem, idx);
      } else {
        this.showElement(elem, idx);
      }
      return found;
    },

    hideElement: function(elem, idx) {
      if (elem.tagName.toUpperCase() == 'OPTION') {
        if (elem.className.indexOf('optgroup') == -1) {
          this.hideOption(elem, idx);
        }
      } else {
        if (elem.tagName.toUpperCase() != 'OPTGROUP') {
          BS.Util.hide(elem);
          $j(elem).data('visibleElem', false);
        }
      }
    },

    showElement: function(elem, idx) {
      if (this.isHiddenOption(elem)) {
        this.showOption(elem, idx);
      } else {
        BS.Util.show(elem);
        $j(elem).data('visibleElem', true);
      }
    },

    isVisible: function(elem) {
      return elem.style.display != 'none';
    },

    /*
     * Retrieves text contents of the element, including child nodes.
     * If a child node contains text that should not be searchable, add a 'noSearch' class to such element.
     */
    getContent: function(elem) {
      var content = elem._cachedContent;
      if (content != null) return content;

      content = "";

      // Take content from data-title, if none is present - search in child nodes,
      // omitting the nodes with noSearch class
      if (elem.getAttribute('data-title')) {
        content = elem.getAttribute('data-title');
      } else {
        for (var i=0; i<elem.childNodes.length; i++) {
          var node = elem.childNodes[i];
          if (node.nodeType == 1 && !node.classList.contains('noSearch')) {
            content += this.getContent(node);
          }
          if (node.nodeType == 3) {
            content += node.nodeValue;
          }
        }
      }

      elem._cachedContent = content.replace(/[\s]+/g, ' ').strip().toUpperCase();
      return elem._cachedContent;
    },

    isHiddenOption: function(elem) {
      return elem.className && elem.className.indexOf('hiddenOption') != -1;
    },

    hideOption: function(elem, idx) {
      var selectElem = elem.parentNode;
      if (!selectElem._hiddenOptions) {
        selectElem._hiddenOptions = {};
      }

      selectElem._hiddenOptions[idx] = elem;

      var newElem = document.createElement("SPAN");
      newElem.className = 'inplaceFiltered hiddenOption';
      newElem._cachedContent = this.getContent(elem);
      if (elem.disabled) {
        newElem.disabled = true;
      }

      if (elem.className.indexOf('optgroup') > -1) {
        newElem.className += ' optgroup';
      }
      newElem.setAttribute("data-filter-data", elem.getAttribute("data-filter-data"));

      selectElem.insertBefore(newElem, elem);
      selectElem.removeChild(elem);
    },

    showOption: function(elem, idx) {
      var selectElem = elem.parentNode;
      if (selectElem && selectElem._hiddenOptions[idx]) {
        selectElem.insertBefore(selectElem._hiddenOptions[idx], elem);
        selectElem.removeChild(elem);

        selectElem._hiddenOptions[idx] = null;
      }
    },

    toggleOptgroups: function(keyword, container, elementsToFilter) {
      function shouldHandle(option) {
        var tagName = option.tagName.toUpperCase();
        return tagName == "OPTION" || tagName == "SPAN"
      }

      if (container.prop('tagName').toUpperCase() == 'SELECT') {
        var that = this;
        elementsToFilter.each(function(index) {
          var thisClassName = this.className;

          // Doesn't do anything with ordinary options.
          if (!thisClassName.include('optgroup') || !shouldHandle(this)) {
            return;
          }

          var hasVisibleChildren = that.getContent(this).include(keyword),
              nextOption = this.nextSibling,
              depth = parseInt(this.getAttribute("data-filter-data") || "0");

          while (nextOption && !hasVisibleChildren) {
            if (nextOption.nodeType == 1 && shouldHandle(nextOption)) {
              // Check if next group is reached.
              var nextData = nextOption.getAttribute("data-filter-data");
              if (nextData) {
                if (depth >= parseInt(nextData)) {
                  break;
                }
              } else {
                if (nextOption.disabled) {
                  break;
                }
              }

              // Stop if there is an element that matches the query.
              hasVisibleChildren = that.isVisible(nextOption) && that.getContent(nextOption).include(keyword);
            }
            nextOption = nextOption.nextSibling;
          }

          if (hasVisibleChildren) {
            thisClassName.include('hiddenOption') && that.showOption(this, index);
          } else {
            !thisClassName.include('hiddenOption') && that.hideOption(this, index);
          }
        });
      }
    },

    prepareFilter: function(containerId) {
      var container = $(BS.Util.escapeId(containerId));

      function getPaddingForElement(element) {
        var attr = (element instanceof $) ? element.attr("data-filter-data") : element.getAttribute("data-filter-data");
        if (!attr) return "";

        var depth = parseInt(attr);
        var spaces = [];
        for (var i = 0; i < 4 * depth; ++i) spaces.push("&nbsp;");
        return spaces.join("");
      }

      if (container.length > 0 && container.prop('tagName').toUpperCase() == 'SELECT') {
        var previousOption = null;
        container.children("option").each(function() {
          var option = this;
          option.innerHTML = getPaddingForElement(option) + option.innerHTML;

          if (previousOption && parseInt(option.getAttribute("data-filter-data") || "0") > parseInt(previousOption.getAttribute("data-filter-data") || "0")) {
            $(previousOption).addClass("optgroup");
          }
          previousOption = option;
        });

        container.children("optgroup").each(function() {
          var optgroup = $(this),
              options = this.getElementsByTagName('option');

          if (options.length == 0) {
            optgroup.remove();
            return;
          }

          for (var i=options.length-1; i>=0; i--) {
            var option = options[i];
            optgroup.after(option);
            option.innerHTML = getPaddingForElement(option) + option.innerHTML;
          }

          option = $('<option class="inplaceFiltered optgroup" disabled="disabled">' + getPaddingForElement(optgroup) + optgroup.attr('label').escapeHTML() + '</option>');
          option.attr("data-filter-data", optgroup.attr("data-filter-data"));
          optgroup.replaceWith(option);
        });
      }
    },
    /**
     * Stores init function with corresponding id to call it manually
     * e.g. right after whatever have been loaded, not on DOM 'ready'
     * @param {String} id
     * @param {Function} func
     */
    storeInitFunction: function (id, func) {
      this._storedInitializers[id] = func;
    },
    /**
     * Returns stored init function by id and changes stored value to null
     * to prevent duplicate inits
     * @param {String} id
     * @returns {Function|null}
     */
    getStoredInitFunction: function (id) {
      var result = this._storedInitializers[id];
      this._storedInitializers[id] = null;
      return result;
    }
  };

  $.fn.inplaceFilter = function(containerId, afterApplyFunc) {
    var input = this;
    var container = $(BS.Util.escapeId(containerId));

    input.on('keyup', _.throttle(function() {
      BS.InPlaceFilter.applyFilter(container, input.get(0), afterApplyFunc);
    }, 100));
  };
})(jQuery);

BS.VisibilityHandlers = {
  _emptyHandler: { updateVisibility: function() {} },
  _handlers: {},

  attachTo: function(control, handler) {
    var controlId = $(control).id;
    var controlHandlers = this._handlers[controlId];
    if (controlHandlers == null) {
      controlHandlers = [];
      this._handlers[controlId] = controlHandlers;
    }
    controlHandlers.push(handler);
  },

  detachFrom: function(elementId) {
    this._handlers[elementId] = null;
  },

  _visibilityHandler: function(element) {
    if (!element || !element.id) return this._emptyHandler;

    var controlHandlers = this._handlers[element.id];
    if (controlHandlers == null) return this._emptyHandler;

    return {
      updateVisibility: function() {
        for (var i=0; i<controlHandlers.length; i++) {
          controlHandlers[i].updateVisibility();
        }
      }
    };
  },

  _collectElements: function(parentEl) {
    var elems = [];
    var id;
    if (parentEl == null) return elems;

    if (parentEl.id) {
      elems.push(parentEl);
    }

    if (parentEl.id == 'mainContent') {
      for (id in this._handlers) {
        if (!this._handlers.hasOwnProperty(id)) continue;
        elems.push($(id));
      }
    } else {
      for (id in this._handlers) {
        if (!this._handlers.hasOwnProperty(id)) continue;
        var elem = $(id);
        if (BS.Util.descendantOf(elem, parentEl)) {
          elems.push(elem);
        }
      }
    }
    return elems;
  },

  updateVisibility: function(el) {
    if (el == null) return;
    var elems = this._collectElements($(el));
    for (var i=0; i<elems.length; i++) {
      this._visibilityHandler(elems[i]).updateVisibility();
    }
  }
};

BS.User = {
  setProperty: function(key, value, options) {
    this._setProperty(key, value, options, "setUserProperty");
  },

  deleteProperty: function(key, options) {
    this._beforeChange(options);

    BS.ajaxRequest(window['base_uri'] + '/ajax.html', {
      parameters: 'deleteUserProperty=' + key,
      onComplete: function() {
        BS.User._afterChange(options);
      }
    })
  },

  setBooleanProperty: function(key, value, options) {
    if (value) {
      this.setProperty(key, value, options);
    } else {
      this.deleteProperty(key, options);
    }
  },

  _setProperty: function(key, value, options, methodName) {
    if (!options) options = {};
    this._beforeChange(options);

    BS.ajaxRequest(window['base_uri'] + '/ajax.html', {
      parameters: methodName + '=' + key + '&value=' + value,
      onComplete: function() {
        BS.User._afterChange(options);
      }
    })
  },


  _beforeChange: function(options) {
    if (options && options.progress) {
      BS.Util.show(options.progress);
    }
  },

  _afterChange: function(options) {
    options = options || {};
    if (options.afterComplete) {
      options.afterComplete();
    }
    if (options.progress) {
      BS.Util.hide(options.progress);
    }
  }
};

/**-------------------------------------------------------*/
/*-------- Simple delayed action support -----------------*/
/**-------------------------------------------------------*/
BS.DelayedAction = function(action_start, action_stop, delay) {
  if (!delay) delay = 300;
  this.delay = delay;
  this.action = action_start;
  this.stop_action = action_stop;
};

BS.DelayedAction.prototype.start = function() {
  this.timeout = setTimeout(this.action, this.delay);
};

BS.DelayedAction.prototype.stop = function() {
  clearTimeout(this.timeout);
  this.stop_action.call(this);
};

/**
 Usage:
 var progress = new BS.DelayedShow(element_id); // == new BS.DelayedShow(element_id, 300);
 progress.show();

 // some ajax call
 // onComplete: function() { progress.hide();}

 */

BS.DelayedShow = function(element) {
  BS.DelayedAction.call(this, function() {
    if ($(element)) $(element).show();
  }, function() {
    if ($(element)) $(element).hide();
  });
};

BS.DelayedShow.prototype = new BS.DelayedAction();
BS.DelayedShow.prototype.show = BS.DelayedShow.prototype.start;
BS.DelayedShow.prototype.hide = BS.DelayedShow.prototype.stop;

/**-------------------------------------------------------*/


/* Catch Javascript problems in AJAX handlers: */
Ajax.Responders.register({
  onException: function(r, e) {
    BS.Log.error(e);
  }
});

// Depends on jquery UFD plugin.
// See http://code.google.com/p/ufd/
BS.jQueryDropdown = function(selector, options) {
  var dropDown = jQuery(selector);
  var id = dropDown.attr('id');

  // Check if already initialized.
  if ($(BS.jQueryDropdown.namePrefix + id)) {
    try {
      jQuery($(id)).ufd("destroy");
    } catch(e) {
      BS.Log.warn(e);
    }
  }

  var selectElem = dropDown.get(0);
  var name = selectElem.name;
  id = selectElem.id;

  var className = "ufd";
  if (dropDown.attr("class")) {
    className += " " + dropDown.attr("class");
  }

  dropDown.ufd(jQuery.extend(true, options || {}, {
    css: { button: BS.jQueryDropdown.namePrefix + (name ? name : id), wrapper: className },
    calculateZIndex: true,
    zIndexPopup: BS.Hider._currentZindex()
  }));

  return dropDown;
};

/**
 * Inits `jQueryDropdown` and attaches `setSelected` and `setSelectValue` methods on element with id `selectId`
 * @param {String} selectId
 * @param {Object} filterOptions - `jquery.ui.ufd` options
 */
BS.enableJQueryDropDownFilter = function(selectId, filterOptions) {
  BS.jQueryDropdown($(selectId), filterOptions);

  /**
   * @function setSelected
   * Updates  master `select` selectedIndex and
   * - by default rebuilds `jQueryDropdown` - can be VERY slow on long list
   * - with `shallow` parameter just updates `jQueryDropdown` in accordance to the index.
   *
   * @param {Number} idx
   * @param {Boolean} [shallow=false]
   */
  $(selectId).setSelected = function(idx, shallow) {
    $(selectId).selectedIndex = idx;
    shallow ? $j($(selectId)).ufd('setInputFromMaster') : BS.jQueryDropdown($(selectId)).ufd("changeOptions");
  };

  /**
   * @function setSelectValue
   * Looks for the provided value in master `select` options, selects it (or 0),
   * updates corresponding `jQueryDropdown`
   *
   * @param val
   * @param {Boolean} [shallow=false]
   */
  $(selectId).setSelectValue = function(val, shallow) {
    var idx = 0;
    var selector = $(selectId);
    for (var i = 0; i < selector.options.length; i++) {
      if (selector.options[i].value == val) {
        idx = i;
        break;
      }
    }
    selector.setSelected(idx, shallow);
  };
};


// jQuery ufd creates temporary elements with names
// that ends with that prefix. We need to filter those
// fields out when sending parameters to the server.
BS.jQueryDropdown.namePrefix = "-ufd-teamcity-ui-";

BS.jQueryDropdown.setJQueryOptions = function($) {
  if ($.ui && $.ui.ufd) {
    $.ui.ufd.defaults.skin = "default";
    $.ui.ufd.defaults.prefix = BS.jQueryDropdown.namePrefix;
    $.ui.ufd.prototype.options = $.ui.ufd.defaults; // 1.8 default options location
  }
};

BS.jQueryDropdown.setJQueryOptions(jQuery);

// A hack-y way of fixing the restriction of the HTML element `optgroup`:
// In some cases `optgroup` appears to be empty (without nested options), but has to be shown anyway.
// Browsers automatically strip empty groups, and we don't want that.
// So here's a trick: insert a dummy option with a special class "user-delete", and delete them right after init.
// Has been tested in Google Chrome, Firefox and Opera.
// For the case with UFD selectors, CSS is enough.
BS.deleteRedundantOptions = function(selector) {
  $j("option.user-delete", selector || "select").remove();
};

// Please consider NOT using this method if possible. An "A" element with display: block is usually
// a better idea than making a DIV or a TD clickable
BS.openUrl = function(event, url) {
  if (Event.element(event) && Event.element(event).tagName.toUpperCase() == 'A') {
    // Handle links normally
    return true;
  } else {
    if (Event.isLeftClick(event)) {
      // New tab requested
      if (event.ctrlKey || event.metaKey) {
        window.open(url);
      // Plain normal click
      } else {
        document.location.href = url;
      }
    // New tab requested
    } else if (Event.isMiddleClick(event)) {
      window.open(url);
    // If we made it until here, and the following check is false - assume the left button
    // was clicked because we ran out of buttons.
    // Why? Because button detection is unstable for click events (looking at you, IE)
    // http://www.quirksmode.org/js/events_properties.html#button
    } else if (!Event.isRightClick(event)) {
      document.location.href = url;
    }
  }
  return false;
};

// A fix for TW-33812.
BS.goBack = function(event, url) {
  // Cannot use window["base_uri"], because of context duplication.
  var prefixWithoutContext = window.location.protocol + "//" + window.location.host;
  BS.openUrl(event, prefixWithoutContext + url);
  return false;
};

// One more fix for TW-33812.
BS.fixCancel = function() {
  $j(function() {
    $j(".btn.cancel").each(function() {
      var self = $j(this),
          href = self.attr("href");
      if (href && href != "#") {
        self.attr("href", BS.ensureLocalUrl(href));
      }
    });
  });
};

/**
 * Returns URL suitable for redirects within the server
 * @param url absolute or relative (to the root) URL
 */
BS.ensureLocalUrl = function (url) {
  if (!url || url == "#") {
    return url;
  }
  var rootUrl = window.location.protocol + "//" + window.location.host;
  if (url.startsWith(rootUrl)) {
    return url;
  }
  try {
    var absoluteUrl = new URL(url);
    absoluteUrl.protocol = window.location.protocol;
    absoluteUrl.host = window.location.host;
    return absoluteUrl.href;
  } catch (e) {
    //consider it not an absolute URL
    if (url.startsWith("/")) {
      return rootUrl + url;
    } else {
      return rootUrl + "/" + url;
    }
  }
};

BS.LoadStyleSheetDynamically = function (url, callback) {
  var head = document.getElementsByTagName('head')[0];
  var existingStylesheet = null;
  var stylesheet;

  $j('link[type="text/css"], style').each(function() {
    if (this.tagName.toLowerCase() == 'link' && this.href == url || this.getAttribute('data-href') == url) {
      existingStylesheet = this;
      return false;
    }
  });

  var intervalId;
  var waitForStylesheet = function(stylesheet, callback) {
    if (stylesheet.getAttribute('data-loaded')) {
      clearInterval(intervalId);
      callback();
    }
  };

  if (!callback) {
    if (existingStylesheet) return;
    stylesheet = document.createElement('link');
    stylesheet.type = 'text/css';
    stylesheet.rel = 'stylesheet';
    stylesheet.title = 'dynamicLoadedSheet';
    stylesheet.href = url;
    head.appendChild(stylesheet);
  } else {
    if (!existingStylesheet) {
      stylesheet = document.createElement('style');
      stylesheet.type = 'text/css';
      stylesheet.setAttribute('data-href', url);
      head.appendChild(stylesheet);
      $j.get(url, function(contents) {
        stylesheet.textContent = contents;
        stylesheet.setAttribute('data-loaded', true);
        callback();
      });
    } else {
      if (existingStylesheet.tagName.toLowerCase() == 'style') {
        intervalId = setInterval(function() {
          waitForStylesheet(existingStylesheet, callback);
        }, 50);
      } else {
        callback();
      }
    }
  }
};

(function () {
  var u = navigator.userAgent.toLowerCase(),
      m = /(chrome)[ \/]([\w.]+)/.exec(u)
                || /(webkit)[ \/]([\w.]+)/.exec(u)
                || /(opera)(?:.*version|)[ \/]([\w.]+)/.exec(u)
                || u.indexOf("compatible") < 0 && /(mozilla)(?:.*? rv:([\w.]+)|)/.exec(u)
          || [],
      b = m[1] || "",
      v = m[2] || 0;

  BS.Browser = {
    version: v,
    mozilla: b === "mozilla",
    opera: b === "opera",
    webkit: b === "chrome" || b === "webkit",
    windows: navigator.platform.indexOf('Win') != -1
  };
})();

BS.stopPropagation = function(event) {
  event.stopPropagation();
};

(function($) {
  BS.MultiSelect = {
    init: function(selector, onchange) {
      var select = $(selector);
      if (!select.length) return;

      select.find("input").each(function() {
        var self = $(this);

        if (self.hasClass("group")) {
          self.on("change", function(evt) {
            var parent = self.parent().parent(),
                depth = parseInt(parent.attr("data-depth") || "0"),
                checked = this.checked;

            var shouldDisableChildren = parent.attr("data-disable-children");

            parent.nextAll().each(function(idx, elem) {
              elem = $(elem);
              var currentDepth = parseInt(elem.attr("data-depth") || "0");
              if (currentDepth > depth) {
                // $(elem).is(':visible') check is simple fix for TW-40638 w/o regressions,
                // but it is too slow for big trees, so lets still use data('visibleElem')
                // from BS.InPlaceFilter but do not forget to use it in MultiSelect#update
                var dataVisibility = $(elem).data('visibleElem');
                if (typeof dataVisibility === 'undefined' || dataVisibility) {
                  elem.find("input").prop("checked", checked);
                  if (shouldDisableChildren) {
                    elem.find("input").prop("disabled", checked);
                  }
                  //if (checked) elem.hide(); else elem.show();
                }
                return true;
              } else {
                return false;
              }
            });

            onchange && onchange(evt);
          });
        } else {
          self.on("change", function(evt) {
            onchange && onchange(evt);
          });
        }
      });

      var stack = [];
      select.find(".inplaceFiltered").each(function() {
        var self = $(this);
        var depth = parseInt(self.attr("data-depth"));

        if (!stack.length) {
          stack.push(self);
          return;
        }

        while (stack.length) {
          var last = stack[stack.length - 1];
          var lastDepth = parseInt(last.attr("data-depth"));

          if (lastDepth == depth) {
            self.data("parent", last.data("parent"));
            stack[stack.length - 1] = self;
            break;
          } else if (depth > lastDepth) {
            self.data("parent", last);
            stack.push(self);
            break;
          } else {
            stack.pop();
          }
        }
      });
    },

    update: function(selector, filterField) {
      if (!filterField.value) {
        return;
      }

      $(selector).find(".inplaceFiltered:visible").each(function() {
        var self = $(this);
        var depth = parseInt(self.attr("data-depth"));
        var row = self;
        while (depth > 0) {
          depth--;
          var parent = row.data("parent");
          if (!parent) {
            parent = row.prevAll(".user-depth-" + depth + ':first');
            row.data("parent", parent);
          }
          parent.show().data('visibleElem', true);
          row = parent;
        }
      });
    }
  };
})(jQuery);

// See TW-27636, TW-29438
function fixErrorMessage(error) {
  return error.escapeHTML().replace(/(\w{40})/g, "$1<wbr>");
}

BS.ScrollUtil = {
  win: $j(window),
  doc: $j(document),

  body: function() {
    return $j('#bodyWrapper');
  },

  getVerticalScroll: function() {
    return this.win.scrollTop();
  },

  getHorizontalScroll: function() {
    return this.win.scrollLeft();
  },

  getContentHeight: function() {
    return this.body().height();
  },

  getWindowHeight: function() {
    return this.win.height();
  },

  isScrollAtBottom: function(error) {
    var height = this.getContentHeight();
    var scroll = this.getVerticalScroll();
    var innerHeight = this.getWindowHeight();
    if (error == undefined) {
      error = 20;
    }

    return Math.abs(innerHeight + scroll - height) < error;
  },

  scrollToBottom: function() {
    this.win.scrollTop(this.getContentHeight());
  }
};

/**
 * @param {jQuery} $select
 */
BS.expandMultiSelect = function ($select) {
  $select.css('height', '');
  $select.attr('size', $select.children('option').length);

  if ($select.get(0).scrollHeight && $select.get(0).scrollHeight > $select.height()) {
    $select.height($select.get(0).scrollHeight);
  }
};

/**
 * Resets `disabled` property to `false` for every element with class `js_to-enable`
 * inside container (document by default)
 *
 * @param {Element} [container=document]
 */
BS.enableDisabled = function (container) {
  $j(container || document).find('.js_to-enable').prop('disabled', false);
};


/**
 * Displays browser confirm dialog
 * and executes `onConfirm` action if user confirms action
 * @param {String} message
 * @param {Function} onConfirm
 * @param {Function} [onCancel]
 */
BS.confirm = function (message, onConfirm, onCancel) {
  if (confirm(message)) {
    onConfirm();
  } else if (onCancel) {
    onCancel();
  }
};

/**
 * Wraps a callback, delaying it to the next frame to avoid forced reflow
 * @param {Function} callback
 */
BS.nextFrame = function (callback) {
  return function() {
    var args = arguments;
    var _this = this;
    window.requestAnimationFrame(function () {
      callback.apply(_this, args)
    });
  };
};

BS.CSRF.initPeriodicalCsrfRefresh();

BS.AdminNavigation = {
  projectAdminPages: [
    '/admin/editProject.html',
    '/admin/editBuildTypeVcsRoots.html',
    '/admin/attachBuildTypeVcsRoots.html',
    '/admin/editBuild.html',
    '/admin/editRunType.html',
    '/admin/editBuildRunners.html',
    '/admin/editBuildFeatures.html',
    '/admin/editBuildFeaturesList.html',
    '/admin/editBuildParams.html',
    '/admin/editRequirements.html',
    '/admin/buildTypeSuggestions.html',
    '/admin/editTriggers.html',
    '/admin/editBuildFailureConditions.html',
    '/admin/cleanupSettings.html',
    '/admin/editDependencies.html',
    '/admin/dependenciesTable.html',
  ],
  isProjectAdminPage(url) {
    return this.projectAdminPages.some(page => url.startsWith(base_uri + page));
  },
  perform() {
    BS.AdminNavigation.currentUrl = new URL(location.href);
    const searchParams = new URLSearchParams(location.search);
    searchParams.delete('init');
    document.getElementById('pageContent').refresh('loadingWarning', searchParams.toString(), () => {
      ReactUI.closeEditDsl('runnerDsl');
      ReactUI.closeEditDsl('buildTypeDsl');
      BS.EditDsl.hideEditDslPanel('#uiMode', '#dslMode');
    }, 500);
  },
  init() {
    BS.AdminNavigation.currentUrl = new URL(location.href);
    document.addEventListener('click', e => {
      const target = e.target;
      const link = target.closest('a');
      if (link != null) {
        const href = link.href;
        try {
          const url = new URL(href);
          if (
            (url.pathname !== location.pathname || url.search !== location.search) &&
            e.button === 0 &&
            (!link.target || link.target === "_self") &&
            !(event.metaKey || event.altKey || event.ctrlKey || event.shiftKey) &&
            BS.AdminNavigation.isProjectAdminPage(href)
          ) {
            e.preventDefault();
            url.searchParams.delete('init');
            history.pushState(null, '', url.toString());
            BS.AdminNavigation.perform();
          }
        } catch {
          // ignore
        }
      }
    });
    window.addEventListener('popstate', () => {
      if (
        (location.pathname !== BS.AdminNavigation.currentUrl.pathname || location.search !== BS.AdminNavigation.currentUrl.search) &&
        BS.AdminNavigation.isProjectAdminPage(location.href)
      ) {
        BS.AdminNavigation.perform();
      }
    });
  }
};
