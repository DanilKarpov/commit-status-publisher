BS.CustomControl = {
  /**
   * Functions that are expected to be supported for a custom control for BS.RunBuildDialog.ControlsHost
   */
  AbstractControl : {
    /**
     * Custom control must implement this function to return control value.
     *
     * This method is called by the system to get current control value.
     */
    getControlValue: function() {
      //implementation must return control value.
      throw "Not Implemented";
    },

    /**
     * Custom control may define a hash of error processors.
     * Every error_id returned from the Java side will be
     * mapped to an on[errorId]Error function.
     * If a function is defined, custom error handling will be performed.
     *
     * Otherwise, element with id 'error_[errorId]' will be highlighted
     * in the same way as build runner form validation works.
     */
    errorsProcessor : {
      /** this is an example of an error handler for errorId == 'ComplexError' **/
      onComplexError: function(errorMessage) {
      }
    }
  }
};
