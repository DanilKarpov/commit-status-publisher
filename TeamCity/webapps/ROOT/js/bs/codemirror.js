if (CodeMirror) {
  BS.CodeMirror = {
    _textarea: null,
    _editor: null,
    _defaultOptions: {
      viewportMargin: 100,
      lineNumbers: true,
      matchBrackets: true,
      autoCloseTags: true,
      styleActiveLine: true,
      autofocus: true
    },
    fromTextArea: function(textarea, options) {
      var _options = OO.extend(this._defaultOptions, options);

      const originalMode = _options.mode;
      let resolvedMode = originalMode;
      if (!this._hasMode(originalMode)) {
        if (CodeMirror.TeamCity.modeMap.hasOwnProperty(originalMode)) {
          resolvedMode = CodeMirror.TeamCity.modeMap[originalMode];
        } else {
          resolvedMode = 'null';
        }
      }

      if (CodeMirror.TeamCity.mimeTypeMap.hasOwnProperty(originalMode)) {
        _options.mode = CodeMirror.TeamCity.mimeTypeMap[originalMode];
      } else {
        _options.mode = resolvedMode;
      }

      this._editor = CodeMirror.fromTextArea(textarea, _options);

      if (!this._hasMode(_options.mode)) {
        CodeMirror.autoLoadMode(this._editor, resolvedMode);
      }

      return this._editor;
    },
    _hasMode: function (mode) {
      return CodeMirror.modes.hasOwnProperty(mode);
    }
  };
}
