"use strict";
BS.PauseProjectDialog = OO.extend(BS.AbstractWebForm,OO.extend(BS.DialogWithProgress, {

  formElementId: function() {
    return 'pauseProjectForm';
  },

  formElement: function() {
    return $(this.formElementId());
  },

  getContainer: function() {
    return $(this.formElementId() + 'Dialog');
  },

  showPauseProjectDialog: function(projectId) {
    this.showProgress();
    var that = this;
    $j(BS.Util.escapeId(this.formElementId())).remove();
    BS.ajaxRequest(window["base_uri"] + '/admin/pauseProject.html', {
      method: "GET",
      parameters: {"projectId" : projectId},
      onComplete: function(response) {
        $j('body').append(response.responseText);
        that.showCentered();
        that.bindCtrlEnterHandler(that.submit.bind(that));
        BS.PauseProjectDialog._partiallyActivatedGroups = {};
        BS.PauseProjectDialog._whollyActivatedGroups = [];
      }
    });
    return false;
  },

  submit: function() {
    BS.Util.show('pauseProjectProgressIcon');
    if ($('actionReason').value == $('actionReason').defaultValue) {
      $('actionReason').value = "";
    }
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onCompleteSave: function () {
        BS.Util.hide('pauseProjectProgressIcon');
        BS.reload(true);
      },
      onFailure: function () {
        BS.Util.hide('pauseProjectProgressIcon');
        alert("Problem accessing server");
      }
    }));
    return false;
  },

  _partiallyActivatedGroups: {},
  _whollyActivatedGroups: [],

  processChange: function(evt) {
    if (!Object.keys(BS.PauseProjectDialog.CommentData).length) {
      return;
    }

    function isInitiallyPausedConfiguration($elem) {
      return $elem.siblings('.js-paused-data').length > 0;
    }


    function processProject($elem) {
      var parent = $elem.parent().parent(),
          depth = parseInt(parent.attr("data-depth") || "0"),
          checked = $elem.is(':checked');

      parent.nextAll().each(function(idx, elem) {
        elem = $j(elem);
        if (parseInt(elem.attr("data-depth") || "0") > depth) {
          processBt(elem.find("input"));
          return true;
        } else {
          return false;
        }
      });
    }

    function processBt($elem) {
      if (isInitiallyPausedConfiguration($elem)) {
        var descrElement = $elem.siblings('.js-paused-data').first();
        var hash = descrElement.data('hash') + '';
        var btId = descrElement.attr('id').replace(/-hash$/, '');

        if ($elem.is(':checked')) {
          BS.PauseProjectDialog._removeBtFromPartiallyActivatedGroup(hash, btId);
        } else {
          BS.PauseProjectDialog._addBtToPartiallyActivatedGroup(hash, btId);
        }
      }
    }

    function isProject($elem) {
      return $elem.hasClass('group');
    }

    var $currentElem = $j(evt.target);

    if (isProject($currentElem)) {
      processProject($currentElem);
    } else {
      processBt($currentElem, true);
    }

    BS.PauseProjectDialog.generateWarning();
  },

  generateWarning: function () {
    var warning = '';
    var groups = Object.keys(BS.PauseProjectDialog._partiallyActivatedGroups);

    if (BS.PauseProjectDialog._whollyActivatedGroups.length) {
      BS.PauseProjectDialog._whollyActivatedGroups.forEach(function (groupHash, index) {
        if (index > 0) {
          warning += '<br>';
        }
        warning += 'You are about to unpause group of ';
        warning += BS.PauseProjectDialog.CommentData[groupHash].buildTypes.length;
        warning +=' build configurations, paused ';
        if (BS.PauseProjectDialog.CommentData[groupHash].username) {
          warning+= 'by <b>' + BS.PauseProjectDialog.CommentData[groupHash].username.escapeHTML() + '</b> ';
        }
        warning += 'with message "';
        warning += BS.PauseProjectDialog.CommentData[groupHash].message.escapeHTML();
        warning += '" <a href="javascript:BS.PauseProjectDialog.pauseAll(\'' + groupHash + '\')">reset</a><br>';
      });
    }

    groups.forEach(function (groupHash, index) {
      if (warning.length || index > 0) {
        warning += '<br>';
      }
      warning += 'You are about to unpause ';
      warning += BS.PauseProjectDialog._partiallyActivatedGroups[groupHash].length;
      warning += ' of ';
      warning += BS.PauseProjectDialog.CommentData[groupHash].buildTypes.length;
      warning += ' build configurations paused ';
      if (BS.PauseProjectDialog.CommentData[groupHash].username) {
        warning+= 'by <b>' + BS.PauseProjectDialog.CommentData[groupHash].username.escapeHTML() + '</b> ';
      }
      warning += 'with message "';
      warning += BS.PauseProjectDialog.CommentData[groupHash].message.escapeHTML();
      warning += '" <a href="javascript:BS.PauseProjectDialog.unpauseAll(\'' + groupHash + '\')">unpause all</a><br>';
    });

    $j('.bulk-pause-dialog__warning').html(warning).toggleClass('hidden', warning.length === 0);
  },

  unpauseAll: function(hash) {
    BS.PauseProjectDialog.CommentData[hash].buildTypes.forEach(function (bt) {
      BS.PauseProjectDialog._getCheckboxByBtId(bt.externalId).prop('checked', false);
    });
    BS.PauseProjectDialog._removeGroupFromPartiallyActivatedGroups(hash);
    BS.PauseProjectDialog._addGroupToWhollyActivatedList(hash);
    BS.PauseProjectDialog.generateWarning();
  },

  pauseAll: function(hash) {
    BS.PauseProjectDialog.CommentData[hash].buildTypes.forEach(function (bt) {
      BS.PauseProjectDialog._getCheckboxByBtId(bt.externalId).prop('checked', true);
    });
    BS.PauseProjectDialog._removeGroupFromPartiallyActivatedGroups(hash);
    BS.PauseProjectDialog._removeGroupFromWhollyActivatedList(hash)
    BS.PauseProjectDialog.generateWarning();
  },

  _removeBtFromPartiallyActivatedGroup: function (hash, btId) {
    var groups = BS.PauseProjectDialog._partiallyActivatedGroups;
    BS.PauseProjectDialog._removeGroupFromWhollyActivatedList(hash);

    if (groups[hash]) {
      groups[hash] = groups[hash].filter(function(_btId) {
        return _btId !== btId;
      });
      if (groups[hash].length === 0) {
        BS.PauseProjectDialog._removeGroupFromPartiallyActivatedGroups(hash);
      }
    } else {
      BS.PauseProjectDialog.CommentData[hash].buildTypes
        .forEach(function(bt) {
          if (bt.externalId !== btId && !BS.PauseProjectDialog._getCheckboxByBtId(bt.externalId).is(':checked')) {
            BS.PauseProjectDialog._addBtToPartiallyActivatedGroup(hash, bt.externalId);
          }
        });
    }
  },

  _removeGroupFromPartiallyActivatedGroups: function(hash) {
    delete BS.PauseProjectDialog._partiallyActivatedGroups[hash];
  },

  _addBtToPartiallyActivatedGroup: function (hash, btId) {
    var groups = BS.PauseProjectDialog._partiallyActivatedGroups;

    if (!groups[hash]) {
      groups[hash] = [];
    }

    BS.PauseProjectDialog._removeGroupFromWhollyActivatedList(hash);

    if (groups[hash].indexOf(btId) === -1) {
      groups[hash].push(btId);

      if (groups[hash].length === BS.PauseProjectDialog.CommentData[hash].buildTypes.length) {
        BS.PauseProjectDialog._removeGroupFromPartiallyActivatedGroups(hash);
        BS.PauseProjectDialog._addGroupToWhollyActivatedList(hash);
      }
    }
  },

  _addGroupToWhollyActivatedList: function(hash) {
    if (BS.PauseProjectDialog._whollyActivatedGroups.indexOf(hash) === -1) {
      BS.PauseProjectDialog._whollyActivatedGroups.push(hash);
    }
  },

  _removeGroupFromWhollyActivatedList: function(hash) {
    BS.PauseProjectDialog._whollyActivatedGroups = BS.PauseProjectDialog._whollyActivatedGroups.filter(function(_hash) {
      return hash !== _hash;
    });
  },

  _getCheckboxByBtId: function (btId) {
    return $j(this.formElement()).find('input[value="' + btId + '"]');
  }
}));
