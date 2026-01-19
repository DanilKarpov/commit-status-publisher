/**
 * Interface which is passed to async processes run via BS.AsyncRunner
 * */
BS.AsyncContext = function(runner, countDownCounter) {
  this.runner = runner;
  this.counter = countDownCounter;

  this.cancelled = false;
  this.cancelFunction = Prototype.emptyFunction;
};

/** @return if the current process was canceled. */
BS.AsyncContext.prototype.isCanceled = function() { return this.cancelled; };

/** Allows to set cancel callback */
BS.AsyncContext.prototype.setCancelCallback = function(runMeOnCancel) { this.cancelFunction = runMeOnCancel };

/** This method MUST be run when the process has finished. */
BS.AsyncContext.prototype.done = function() {
  this.counter --;
  if (this.counter <= 0) {
    this.runner._removeRunning(this);
  }
};

/** @private */
BS.AsyncContext.prototype.cancel = function() {
  this.cancelled = true;
  this.cancelFunction();
};


BS.AsyncRunner = {
  // Maximum number of async process which can be active at a time
  maxRunningCount: 3,

  /**
   * Cancel all processes started or queued in this runner. If the process was already started, it's context.isCanceled
   * method will return true upon the next call. If it wasn't started, it won't be */
  cancelAll: function() {
    this._runQueue = [];

    for(var i = 0; i < this._runningContexts.length; i++) {
      this._runningContexts[i].cancel();
    }
    this._runningContexts = [];
    this._runFinishCallback();
  },

  /**
   * Run an asyncronous process
   * @param toRun - a function which accepts BS.AsyncContext as a first parameter.
   * This function should be asynchronous and it <b>MUST</b> call context.done() when it has finished.
   * @param countDownCounter number of times context.done() method must be called after which async process is considered finished
   */
  runAsync: function(toRun, countDownCounter) {
    if (!countDownCounter) countDownCounter = 1;
    this._runQueue.push([toRun, countDownCounter]);
    this._runNext();
  },

  /**
   * Sets a callback function which is called each time when a task is finished
   * */
  setCallbackOnFinish: function(callback) {
    this._finishCallback = callback;
  },

  isEmpty: function() {
    return this._runQueue.length + this._runningContexts.length == 0;
  },

  _runFinishCallback: function() {
    this._finishCallback.call(this);
  },

  _runNext: function() {
    if (!this._runHandler) {
      this._runHandler = setTimeout(function() {
        delete this._runHandler;

        this._startQueueItems(this.maxRunningCount - this._runningContexts.length);

        if (this._runQueue.length > 0) {
          this._runNext();
        }

      }.bind(this), 20);
    }
  },

  _startQueueItems: function(maxProcessesToStart) {
    var countToStart = Math.min(maxProcessesToStart, this._runQueue.length);
    for(var i = 0; i < countToStart; i++) {
      var runData = this._runQueue.shift();
      var context = new BS.AsyncContext(this, runData[1]);
      this._runningContexts.push(context);

      // Well, start the process!
      runData[0](context);
    }
  },

  _removeRunning: function(context) {
    var idx = this._runningContexts.indexOf(context);
    if (idx >= 0) {
      this._runningContexts.splice(idx, 1);
    }
    this._runFinishCallback();
  },


  //BS.AsyncRunner.__runSelfTest()
  __runSelfTest: function() {
    for(var i = 0; i < 100; i ++) {
      (function(t, that) {
        that.runAsync(function(context) {
          setTimeout(function() {
            if (context.isCanceled()) {
              BS.Log.info("Canceled: " + t);
              return;
            }
            BS.Log.info("Done: " + t);
            context.done();
          }, 1000)
        });
      })(i, this);
      setTimeout(this.cancelAll.bind(this), 5000);
    }
  },

  _runQueue: [],
  _runningContexts: [],
  _finishCallback: Prototype.emptyFunction,
  _f: null
};

