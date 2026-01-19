BS.TypedParameters = {};
BS.TypedParameters.create = function () {
  return {
    containerId: 'contextId',  // this should be overridden in usage
    submitUrl: '', //url of generic parameters controller that is in charge of control validation

    components: {},

    extra: {}, //hash used to share state on control rendering

    AbstractControl: OO.extend(BS.CustomControl.AbstractControl, {

    }),

    //this is sample of response object
    AbstractSubmitResult: {


    },

    register: function (id) {
      var o = OO.extend(this.AbstractControl, {
        id: id,
        getControlValue: function () {
          var el = $(o.id);
          if (el == null) return null;
          return el.getValue();
        }
      });
      this.components[id] = o;

      return function (x) {
        if (x.getControlValue) {
          o.getControlValue = x.getControlValue.bind(x);
        }

        if (x.errorsProcessor) {
          for (var k in x.errorsProcessor) {
            o.errorsProcessor[k] = x.errorsProcessor[k].bind(x.errorsProcessor);
          }
        }
      };
    },

    getInternalValues: function () {
      var result = {};
      for (var k in this.components) {
        var v = this.components[k];
        result['custom_control:' + k] = v.getControlValue();
      }

      return result;
    },

    //sample parameters object of #getSubmitValues
    AbstractSubmitValuesParameters: {
      onComplete: function (AbstractSubmitResult) {},
      onError: function (e) {},
      onFailure: function () {}
    },

    getSubmitValues: function (params) {
      var that = this;

      var parameters = OO.extend(this.getInternalValues(), {
        contextId: that.containerId
      });

      params = OO.extend(this.AbstractSubmitValuesParameters, params);

      BS.ajaxRequest(
          that.submitUrl, {
            method: 'post',
            parameters: Object.toQueryString(parameters),
            onComplete: function (transport) {
              params.onComplete(transport.responseJSON);
            },
            onFailure: function () {
              params.onFailure();
            },
            onException: function (obj, e) {
              params.onError(e);
            }
          }
      )
    },


    //sample error info
    AbstractErrorInfo: {
      'some_control_id': {
        'mainError': 'text',
        'errors': { 'k': 'v' }
      }
    },

    updateErrors: function (errorsInfo) {
      var errorFound = false;

      for (var id in this.components) {
        var err = errorsInfo[id];
        var control = this.components[id];
        if (err) {
          errorFound = true;
          this.showControlError(id, control, err);
        } else {
          this.hideControlError(id);
        }
      }

      return errorFound;
    },

    hideErrors: function () {
      for (var id in this.components) {
        this.hideControlError(id)
      }
    },

    _controlErrorElements: function (id, action) {
      $j('#' + id + "_container span.error").each(action);
    },

    showControlError: function (id, control, controlError) {
      if (controlError.mainError) {
        this._controlErrorElements(id, function () {
          $j(this).text(controlError.mainError);
        });
      }

      //TODO: support sub-errors in controls
    },

    hideControlError: function (id) {
      this._controlErrorElements(id, function () {
        $j(this).html('');
      });
    },

    ///returns BS.PasswordFormSaver object that aware of custom controls
    createFormSaver: function (baseSaver, validationRequired) {
      var typedThis = this;
      if (!baseSaver) baseSaver = BS.PasswordFormSaver;
      var superSaver = baseSaver.save.bind(baseSaver);

      return OO.extend(baseSaver, {
        save: function (form, submitUrl, listener, debug) {
          var saverThis = this;

          //avoid extra AJAX call if parameters are same
          if (!_.any(typedThis.components)) {
            superSaver.apply(saverThis, [form, submitUrl, listener, debug]);
            return;
          }

          listener.onBeginSave(form);
          typedThis.getSubmitValues(
              {
                onComplete: function (dataAndErrors) {

                  if (validationRequired) {
                    typedThis.hideErrors();
                    var hadErrors = typedThis.updateErrors(dataAndErrors.errors);
                    if (hadErrors) {
                      listener.onCompleteSave(form, $j("<empty/>"), true, "custom controls save");
                      return;
                    }
                  }

                  var old = form.serializeParameters();
                  var submitProperties = {};
                  var hasCustomParameters = false;
                  for (var k in dataAndErrors.nameToValues) {
                    hasCustomParameters = true;
                    submitProperties['prop:' + k] = dataAndErrors.nameToValues[k];
                  }

                  if (!hasCustomParameters) {
                    /// There were no custom parameter values returned.
                    /// This only means form session was lost.
                    /// we should break original form submit to avoid all parameters loss
                    /// thus calling reload here to make it re-create proper session state
                    listener.onCompleteSave(form, $j("<empty/>"), true, "custom controls save");
                    BS.reload(true);
                    return;
                  }

                  var mine = Object.toQueryString(submitProperties);
                  var allParameters = old + "&" + mine;

                  var updatedListener = OO.extend(listener, {
                    onBeginSave: function () {
                    }
                  });

                  var updatedForm = OO.extend(form, {
                    serializeParameters: function () {
                      return allParameters;
                    }
                  });

                  superSaver.apply(saverThis, [updatedForm, submitUrl, updatedListener, debug]);
                },

                onError: function (e) {
                  listener.onError(form, e)
                },

                onFailure: function () {
                  listener.onFailure(form)
                }
              }
          );
        }
      });
    }

  }
};
