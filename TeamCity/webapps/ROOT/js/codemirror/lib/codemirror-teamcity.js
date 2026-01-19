if (window.CodeMirror) {
  CodeMirror.TeamCity = {
    // File extension to CodeMirror mode map
    modeMap: {
      "c": "clike",
      "cpp": "clike",
      "h": "clike",
      "hpp": "clike",
      "cc": "clike",
      "cs": "clike",
      "java": "clike",
      "scala": "clike",

      "clj": "clojure",
      "coffee": "coffeescript",

      "css": "css",
      "less": "css",
      "scss": "css",

      "gant": "groovy",
      "gdsl": "groovy",
      "gpp": "groovy",
      "gradle": "groovy",
      "groovy": "groovy",
      "grunit": "groovy",

      "htm": "htmlmixed",
      "html": "htmlmixed",
      "jsf": "htmlmixed",
      "jsp": "htmlmixed",
      "jspf": "htmlmixed",
      "jspx": "htmlmixed",
      "tag": "htmlmixed",
      "tagf": "htmlmixed",
      "tagx": "htmlmixed",
      "xjsp": "htmlmixed",

      "js": "javascript",
      "json": {name: "javascript", json: true},
      "ts": "javascript",

      "lua": "lua",

      "markdown": "markdown",
      "mdown": "mdown",
      "md": "markdown",

      "pl": "perl",
      "pm": "perl",

      "properties":"properties",
      "ini": "properties",

      "php": "php",
      "py": "python",
      "rb": "ruby",
      "rake": "ruby",
      "sass": "sass",
      "sql": "sql",
      "vb": "vb",

      "ant": "xml",
      "fxml": "xml",
      "iml": "xml",
      "jhm": "xml",
      "jnlp": "xml",
      "pom": "xml",
      "rng": "xml",
      "svg": "xml",
      "tld": "xml",
      "wsdl": "xml",
      "xml": "xml",
      "xsd": "xml",
      "xsl": "xml",
      "xslt": "xml",
      "xul": "xml",

      "yaml": "yaml",

      "sh": "shell",
      "shell": "shell",
      "powershell": "powershell",

      "dockerfile": "dockerfile"
    },

    mimeTypeMap: {
      "c": "text/x-csrc",
      "cpp": "text/x-c++src",
      "h": "text/x-chdr",
      "hpp": "text/x-c++hdr",
      "cc": "text/x-c++src",
      "cs": "text/x-csharp",
      "java": "text/x-java",
      "scala": "text/x-scala",

      "clj": "text/x-clojure",
      "coffee": "text/x-coffeescript",

      "css": "text/css",
      "less": "text/x-less",
      "scss": "text/x-scss",

      "gant": "text/x-groovy",
      "gdsl": "text/x-groovy",
      "gpp": "text/x-groovy",
      "gradle": "text/x-groovy",
      "groovy": "text/x-groovy",
      "grunit": "text/x-groovy",

      "htm": "text/html",
      "html": "text/html",
      "jsf": "text/html",
      "jsp": "text/html",
      "jspf": "text/html",
      "jspx": "text/html",
      "tag": "text/html",
      "tagf": "text/html",
      "tagx": "text/html",
      "xjsp": "text/html",

      "js": "text/javascript",
      "json": "application/json",
      "ts": "text/typescript",

      "lua": "text/x-lua",

      "markdown": "text/x-markdown",
      "mdown": "text/x-markdown",
      "md": "text/x-markdown",

      "pl": "text/x-perl",
      "pm": "text/x-perl",

      "php": "text/x-php",
      "py": "text/x-python",
      "rb": "text/x-ruby",
      "sass": "text/x-sass",
      "sql": "text/x-sql",
      "vb": "text/x-vb",

      "ant": "text/xml",
      "fxml": "text/xml",
      "iml": "text/xml",
      "jhm": "text/xml",
      "jnlp": "text/xml",
      "pom": "text/xml",
      "rng": "text/xml",
      "svg": "text/xml",
      "tld": "text/xml",
      "wsdl": "text/xml",
      "xml": "text/xml",
      "xsd": "text/xml",
      "xsl": "text/xml",
      "xslt": "text/xml",
      "xul": "text/xml",

      "yaml": "text/x-yaml"
    },

    getFileExtension: function(fileName) {
      var extension;

      // path/to/file.some.ext -> file.some.ext
      fileName = fileName.substring(fileName.lastIndexOf("/") + 1);

      // file.some.ext -> ext
      extension = fileName.substring(fileName.lastIndexOf(".") + 1);

      return extension;
    },

    getModeByFileName: function(fileName) {
      return this.modeMap[this.getFileExtension(fileName)];
    },

    getMimeTypeByFileName: function(fileName) {
      return this.mimeTypeMap[this.getFileExtension(fileName)];
    }
  };
}