/*
 * See also BS.CopyBuildTypeForm.
 */
BS.MoveForm = OO.extend(BS.AbstractCopyMoveDialog, {
  _projects: [],

  _onFetchDialogComplete: function (response) {
    $j('body').append(response.responseText);
    this.showCentered();
    $j(this.formElement().projectId).trigger('change').focus();
    this.bindCtrlEnterHandler(this.submitMove.bind(this));
  },

  _createMoveErrorsListener: function() {
    var that = this;
    return OO.extend(BS.ErrorsAwareListener, {
      onSaveProjectErrorError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },

      onProjectNotFoundError: function(elem) {
        $("error_" + that.formElement().id + '_projectId').innerHTML = elem.firstChild.nodeValue;
        that.highlightErrorField(that.formElement().projectId);
      },

      onCannotMoveError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },

      onCompleteSave: function(form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);

        if (!err) {
          BS.XMLResponse.processRedirect(responseXML);
        }
      }
    });
  },

  checkCanMove: function(targetId, objectIdParam, objectName, oncomplete) {
    BS.AdminActions.checkCanMove(targetId, objectIdParam, function(vcsRoots, templates, clashingCleanupRules, otherReasons) {
      if (vcsRoots.length > 0 || templates.length > 0 || otherReasons.length > 0) {
        var msg = '<div class="icon_before icon16 attentionComment">' + objectName + ' cannot be moved. ';

        if (otherReasons.length > 0) {
          msg += 'Reasons:' +
                 '<ul>';
          for (var i=0; i<otherReasons.length; i++) {
            msg += '<li>' + otherReasons[i].escapeHTML() + '</li>';
          }

          msg += '</ul>';
        }

        if (vcsRoots.length > 0) {
          msg += 'The following VCS roots won\'t be available in the selected project:' +
                 '<ul>';
          for (i=0; i<vcsRoots.length; i++) {
            msg += '<li>' + vcsRoots[i] + '</li>';
          }

          msg += '</ul>';
        }

        if (templates.length > 0) {
          msg += 'The following templates won\'t be available in the selected project:' +
                 '<ul>';
          for (i=0; i<templates.length; i++) {
            msg += '<li>' + templates[i].escapeHTML() + '</li>';
          }

          msg += '</ul></div>';
        }

        oncomplete(msg);
      } else if (clashingCleanupRules.clashingCleanupDisableRules > 0 || clashingCleanupRules.clashingOverriddenRules > 0) {

        var confirmMsg;
        if (objectName == 'Project') {
          confirmMsg = '<div class="icon_before icon16 attentionComment">' +
            'After the move to the selected project effective cleanup rules of the moved project or some of its sub projects or build configurations will change. ' +
            'Please review the cleanup rules for the ' + objectName.toLowerCase() + ' after the move. ' +
            '</div>';

          oncomplete(confirmMsg, true);
        } else if (clashingCleanupRules.clashingCleanupDisableRules > 0) {
          var rulesStr = clashingCleanupRules.clashingCleanupDisableRules > 1 ? 'rules' : 'rule';

          confirmMsg = '<div class="icon_before icon16 attentionComment">' +
            'After the move to the selected project ' + clashingCleanupRules.clashingCleanupDisableRules + ' cleanup ' + rulesStr + ' will be automatically enabled to prevent clashes with rules from the new parent project. ' +
            'Please review the cleanup rules for the ' + objectName.toLowerCase() + ' after the move. ' +
            '</div>';

          oncomplete(confirmMsg, true);
        } else {
          oncomplete(null);
        }
      } else {
        oncomplete(null);
      }
    });
  }

});

BS.MoveBuildTypeForm = OO.extend(BS.MoveForm, {
  __baseId: 'moveBuildType',
  fetchParamName: 'buildTypeId',

  submitMove: function() {
    BS.FormSaver.save(this, this.formElement().action, OO.extend(this._createMoveErrorsListener(), {
      onMaxNumberOfBuildTypesReachedError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },

      onBuildTypeNotFoundError: function(elem) {
        alert(elem.firstChild.nodeValue);
        BS.reload(true);
      }
    }));

    return false;
  }
});

BS.MoveTemplateForm = OO.extend(BS.MoveForm, {
  __baseId: 'moveTemplate',
  fetchParamName: 'templateId',

  submitMove: function() {
    BS.FormSaver.save(this, this.formElement().action, OO.extend(this._createMoveErrorsListener(), {
      onTemplateNotFoundError: function(elem) {
        alert(elem.firstChild.nodeValue);
        BS.reload(true);
      }}));

    return false;
  }
});

BS.MoveProjectForm = OO.extend(BS.MoveForm, {
  __baseId: 'moveProject',
  fetchParamName: 'projectId',

  submitMove: function() {
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onSaveProjectErrorError: function(elem) {
        alert(elem.firstChild.nodeValue);
      },

      onProjectNotFoundError: function(elem) {
        alert(elem.firstChild.nodeValue);
        BS.XMLResponse.processRedirect(elem.ownerDocument);
      },

      onCompleteSave: function(form, responseXML, err) {
        BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);

        if (!err) {
          BS.XMLResponse.processRedirect(responseXML);
        }
      }
    }));
    return false;
  }
});

BS.MoveVcsRootForm = OO.extend(BS.AbstractCopyMoveDialog, {
  __baseId: 'moveVcsRoot',

  showDialog: function(vcsRootId) {
    this.formElement().vcsRootId.value = vcsRootId;

    this.showCentered();
    this.formElement().moveToProjectId.onchange();
    this.formElement().moveToProjectId.focus();
    this.bindCtrlEnterHandler(this.submitMove.bind(this));

    return false;
  },

  submitMove: function() {
    BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
      onMoveFailedError: function(elem) {
        $j("#error_moveVcsRootForm").text(elem.firstChild.nodeValue);
      },

      onRootNotFoundError: function(elem) {
        alert(elem.firstChild.nodeValue);
        BS.XMLResponse.processRedirect(elem.ownerDocument)
      },

      onSuccessfulSave: function() {
        BS.reload(true);
      }
    }));
    return false;
  }
});
