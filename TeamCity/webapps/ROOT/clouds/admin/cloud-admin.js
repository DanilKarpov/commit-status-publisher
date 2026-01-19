if (!BS.Clouds) {
  BS.Clouds = {};
}

BS.Clouds.Admin = {
  _runningInstancesCount : 0,

  setRunningInstancesCount: function(c) {
    this._runningInstancesCount = c;
  },

  getRunningInstancesCount: function() {
    return this._runningInstancesCount;
  },

  refresh: function() {
    return $('cloudRefreshable').refresh();
  },

  registerRefresh: function() {
    $j(function() {
      BS.Clouds.registerRefreshable(BS.Clouds.Admin.refresh.bind(BS.Clouds.Admin));
    });
  },

  submitFilter: function(projectId, showSubProjects) {
    BS.ajaxRequest(window["base_uri"] + "/clouds/admin/cloudAdmin.html", {
      method: "post",

      parameters: {projectId: projectId, showSubProjects: showSubProjects},

      onComplete: function(/*transport*/) {
        BS.reload(true);
      }
    });
  },

  updateDependentCheckboxes: function () {
    debugger;
    if ($j('#enableProject').is(':checked')){
      $j("#enableSubprojectsCheckbox").prop('disabled', false);
      $j('#enableSubprojectsCheckbox').removeClass('grayNote');
    } else {
      $j('#enableSubprojects').prop('checked', false);
      $j("#enableSubprojectsCheckbox").prop('disabled', true);
      $j('#enableSubprojectsCheckbox').addClass('grayNote');
    }

    var projectWasDisabled = $j('#initiallyEnabled').val() === 'true' && !$j('#enableProject').is(':checked');
    var subProjectWasDisabled = $j('#initiallySubprojectsEnabled').val() === 'true' && !$j('#enableSubprojects').is(':checked');
    var subp_cnt = subProjectWasDisabled ? $j('#subprojectsInstancesCount').val() : 0;
    var pr_cnt = projectWasDisabled ? $j('#projectInstancesCount').val() : 0;
    var totalCnt = parseInt(subp_cnt) + parseInt(pr_cnt);

    if ((projectWasDisabled || subProjectWasDisabled) && totalCnt > 0) { // was initialized initially
      $j('#terminateInstancesCheckbox').show();
      $j('#confirmShutdown_instanceCount').text(totalCnt);
    } else {
      $j('#terminateInstancesCheckbox').prop('checked', false);
      $j('#confirmShutdown_instanceCount').text('');
      $j('#terminateInstancesCheckbox').hide();
    }
    return true;
  },

  CreateProfileForm : OO.extend(BS.PluginPropertiesForm, {

    initialData: {},

    formElement: function() {
      return $('newProfileForm');
    },

    savingIndicator: function() {
      return $('newProfileProviderProgress');
    },

    getSelectedType: function() {
      const cloudType = document.getElementById('cloudType');
      return cloudType?.value;
    },

    beforeSaveForm: function() {},

    saveForm: function() {
      this.beforeSaveForm();
      var that = this;
      var url = this.formElement().getAttribute('action');
      BS.PasswordFormSaver.save(that, url, OO.extend(BS.ErrorsAwareListener, {
        onCompleteSave: function(form, responseXML, err) {
          var wereErrors = BS.XMLResponse.processErrors(responseXML, {}, that.propertiesErrorsHandler);

          BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);

          if (wereErrors) {
            BS.Util.reenableForm(that.formElement());
            return;
          }
          var projectId = encodeURIComponent($j('#projectId').val());

          document.location.href = BS.ensureLocalUrl($j('#cameFromUrl').val());// window['base_uri'] + "/admin/editProject.html?projectId="+projectId+"&tab=clouds";
        }
      }));
    },

    recordInitialParams: function(){
      var that = this;
      if ($j('#action').val() == 'edit'){
        $j('input').add($j('select')).each(function(){
          var elem = $j(this);
          if (elem.hasClass('ignoreModified'))
            return;
          if (!elem.attr('name'))
            return;
          if (elem.attr('type') == 'checkbox'){
            that.initialData[elem.attr('name')] = elem.prop('checked');
          } else {
            that.initialData[elem.attr('name')] = elem.val();
          }

          elem.on('change', function(e, data){
            if (arguments.length === 1) {
              that.checkIfModified();
            }
          });
        });
      }
    },

    checkIfModified: function () {
      var modified = false;
      var that = this;
      $j('input').add($j('select')).each(function(){
        var elem = $j(this);
        var attrName = elem.attr('name');
        if (!attrName || (typeof that.initialData[attrName] =='undefined'))
          return;
        if (elem.hasClass('ignoreModified'))
          return;

        var val;
        if (elem.attr('type') == 'checkbox'){
          val = elem.prop('checked');
        } else {
          val = elem.val();
        }

        if (val != that.initialData[attrName]) {
          if (elem.hasClass('jsonParam')){
            var oldVal = JSON.parse(that.initialData[attrName]);
            var newVal = JSON.parse(val);
            if (that._checkJsonDifferent(oldVal, newVal)){
              modified = true;
            }
          } else {
            modified = true;
          }
        }
      });
      if (modified){
        $j('.modifiedMessage').show();
      } else {
        $j('.modifiedMessage').hide();
      }
    },

    _checkJsonDifferent: function(oldVal, newVal){
      var oldKeys = Object.keys(oldVal).sort();
      var newKeys = Object.keys(newVal).sort();
      if (oldKeys.length != newKeys.length)
        return true;
      for(var key in oldVal){
        if (typeof newVal[key] == 'undefined')
          return true;
        if(typeof oldVal[key] == "object" && typeof newVal[key] == "object"){
          if (this._checkJsonDifferent(oldVal[key], newVal[key]))
            return true;
        } else if (!(newVal[key].toString() == oldVal[key].toString())) {
          return true;
        }
      }
      return false;
    },

    baseParams: function() {
      return "";
    },

    beforeShow: function(serverUrl) {
      var providerType = this.getSelectedType();
      if (providerType == '') {
        this.disableButton(['createButton'], true);
      }
      $j('#profileServerUrl').change(function(){
        if ($j(this).val()==''){
          $j(this).attr('placeholder', serverUrl);
        } else {
          $j(this).removeAttr('placeholder');
        }
      });
      $j('#profileServerUrl').focusin(function () {
        $j(this).removeAttr('placeholder');
      });
      $j('#profileServerUrl').focusout(function () {
        $j('#profileServerUrl').trigger('change');
      });
      $j('#profileServerUrl').trigger('change');
    },

    disableButton: function(ids, value) {
      if (value) {
        ids.each(function(item) {
          $(item).disabled = 'disabled';
        });
      } else {
        ids.each(function(item) {
          $(item).disabled = '';
        });
      }
      var that = this;
      return function() {
        that.disableButton(ids, !value);
      };
    },

    refreshSelectedCloudType: function() {
      var enable;
      var providerType = this.getSelectedType();
      if (providerType != '') {
        enable = this.disableButton(["createButton", "cloudType"], true);
      } else {
        this.disableButton(["createButton"], true);
        enable = null;
      }
      var url = 'cloudType=' + providerType + "&" + this.baseParams();
      $('newProfilesContainer').refresh('newProviderSaving',  url, enable);
    },

    submit: function() {
       var providerType = this.formElement();
       if (providerType == '') {
         alert('Please select Cloud Type');
         return false;
       }
       this.saveForm();
       return false;
     }
  }),

  enabledClouds: function(b, uri) {
    var btn = $(b);
    btn.disable();

    $('enable_integration_loader').show();
    BS.ajaxRequest(uri, {
      parameters : {
        action :  'enable'
      },
      method: 'post',
      onComplete: function() {
        BS.reload(true);
      }
    });
  },

  ConfirmDialog : OO.extend(BS.AbstractModalDialog, {
    aThis : null,

    getContainer: function() {
      return $('confirmShutdownDialog');
    },

    showDialog: function(caption, submitCaption, runningCount) {
      BS.Clouds.Admin.ConfirmDialog.aThis = this;
      $j('#confirmShutdown_action').text(caption);
      $('confirmShutdown_submit').value = submitCaption;
      $j('#confirmShutdown_instanceCount').text(runningCount);
      if (runningCount > 0) {
        $j('#terminateInstancesCheckbox').show();
      } else {
        $j('#terminateInstancesCheckbox').hide();
      }
      this.showCentered();
      this.bindCtrlEnterHandler(this.submit.bind(this));
    },

    shouldKillInstances: function() {
      return $('terminateInstances').checked ? 'true' : 'false';
    },

    enableProject: function(){
      return $j('#enableProject').is(':checked');
    },

    enableSubprojects: function(){
      return $j('#enableSubprojects').is(':checked');
    },

    allowOverride: function(){
      return $j('#allowSubprojectsOverwrite').is(':checked');
    },

    //Override this function to handle confirm
    onConfirm: function() {
    },

    submit: function() {
      $('confirmShutdown').disable();
      $('confirmShutdownDialog_loader').show();

      (this.aThis||this).onConfirm();

      return false;
    },

    postSubmit: function() {
      $('confirmShutdownDialog_loader').hide();
      $('confirmShutdown').enable();
      this.close();
    },

    processKillError: function(transport) {
      return BS.XMLResponse.processErrors(transport.responseXML, {
        onKillFailedError: function(elem) {
          alert(elem.firstChild.nodeValue + "\nAction is canceled due to the error");
        }
      }, function(id, elem) {
        alert(elem.firstChild.nodeValue);
      });
    }
  })
};

BS.Clouds.Admin.DisableEnableProfile = OO.extend(BS.Clouds.Admin.ConfirmDialog, {
  profileId : "",
  projectId : "",

  showDisableProfileDialog: function(projectId, profileId, profileName, runningCount) {
    this.profileId = profileId;
    this.projectId = projectId;
    $j("#confirmShutdownTitle").text("Disable Cloud Profile");
    $j("#enableCheckbox").hide();
    $j("#enableSubprojectsCheckbox").hide();
    $j("#allowSubprojectsOverwriteCheckbox").hide();

    return this.showDialog('Are you sure you want to disable "' + profileName + '"?', 'Disable', runningCount);
  },

  enableProfile: function(projectId, profileId){
    var that = this;
    BS.ajaxRequest(window['base_uri'] + "/clouds/admin/cloudAdminProfile.html", {
      parameters : {
        action : 'enable',
        profileId : profileId,
        projectId: projectId
      },
      method : 'post',
      onComplete: function(transport) {
        var handled = that.processKillError(transport);
        if (!handled) {
          BS.Clouds.Admin.refresh();
        }
        that.postSubmit();
      }
    });
  },

  onConfirm: function() {
    var that = this;
    BS.ajaxRequest(window['base_uri'] + "/clouds/admin/cloudAdminProfile.html", {
      parameters : {
        action : 'disable',
        profileId : that.profileId,
        projectId : that.projectId,
        killInstances : that.shouldKillInstances()
      },
      method : 'post',
      onComplete: function(transport) {
        var handled = that.processKillError(transport);
        if (!handled) {
          BS.Clouds.Admin.refresh();
        }
        that.postSubmit();
      }
    });
  }
});

BS.Clouds.Admin.ConfirmDeleteProfileDialog = OO.extend(BS.Clouds.Admin.ConfirmDialog, {
  profileId : "",
  projectId : "",

  showDeleteProfileDialog: function(projectId, profileId, profileName, runningCount) {
    this.profileId = profileId;
    this.projectId = projectId;
    $j("#confirmShutdownTitle").text("Remove Cloud Profile");
    $j("#enableCheckbox").hide();
    $j("#enableSubprojectsCheckbox").hide();
    $j("#allowSubprojectsOverwriteCheckbox").hide();

    return this.showDialog('Are you sure you want to remove the "' + profileName +'" profile?', 'Remove', runningCount);
  },

  onConfirm: function() {
    var that = this;
    BS.ajaxRequest(window['base_uri'] + "/clouds/admin/cloudAdminProfile.html", {
      parameters : {
        action : 'delete',
        profileId : that.profileId,
        projectId : that.projectId,
        killInstances : that.shouldKillInstances()
      },
      method : 'post',
      onComplete: function(transport) {
        var handled = that.processKillError(transport);
        if (!handled) {
          BS.reload(true);
        }
        that.postSubmit();
      }
    });
  }
});

BS.Clouds.Admin.ResetProfileDialog = OO.extend(BS.Clouds.Admin.ConfirmDialog, {
  profileId : "",
  projectId : "",

  showResetProfileDialog: function(projectId, profileId, profileName, runnningCount) {
    this.profileId = profileId;
    this.projectId = projectId;
    $j("#confirmShutdownTitle").text("Reset Cloud Profile");
    $j("#enableCheckbox").hide();
    $j("#enableSubprojectsCheckbox").hide();
    $j("#allowSubprojectsOverwriteCheckbox").hide();

    return this.showDialog('TeamCity will reset the connection to the underlying cloud provider, this can cause temporary loss of information about running cloud instances.', 'Reset', runnningCount);
  },

  onConfirm: function() {
    var that = this;
    BS.ajaxRequest(window['base_uri'] + "/clouds/admin/cloudAdminProfile.html", {
      parameters : {
        action : 'reset',
        profileId : that.profileId,
        projectId : that.projectId,
        killInstances: that.shouldKillInstances(),
      },
      method : 'post',
      onComplete: function(transport) {
        var handled = that.processKillError(transport);
        if (!handled) {
          BS.reload(true);
        }
        that.postSubmit();
      }
    });
  }
});

BS.Clouds.Admin.ConfirmShutdownDialog = OO.extend(BS.Clouds.Admin.ConfirmDialog, {
  showConfirmDisableDialog: function() {
    var running = BS.Clouds.Admin.getRunningInstancesCount();
    $j("#confirmShutdownTitle").text("Change Cloud Integration Status");
    $j("#enableCheckbox").show();
    $j('#enableProject').prop('checked', $j('#initiallyEnabled').val() === 'true');
    $j("#enableSubprojectsCheckbox").show();
    $j("#enableSubprojects").prop('checked', $j('#initiallySubprojectsEnabled').val() == 'true');
    $j("#allowSubprojectsOverwriteCheckbox").show();

    var showDialog = this.showDialog('', 'Update', running);
    BS.Clouds.Admin.updateDependentCheckboxes();
    return showDialog;
  },

  onConfirm: function() {
    var form = 'confirmShutdown';
    var url = $(form).getAttribute('action');

    var that = this;
    BS.ajaxRequest(url, {
      parameters : {
        action : 'update',
        kill : that.shouldKillInstances(),
        enableProject : that.enableProject(),
        enableSubprojects : that.enableSubprojects(),
        allowOverride : that.allowOverride()
      },
      method: 'post',
      onComplete: function(transport) {
        var handled = that.processKillError(transport);
        if (!handled) {
          BS.reload(true);
        }
        that.postSubmit();
      }
    });
  }
});

if(!BS.Clouds.Admin.Images) BS.Clouds.Admin.Images = {
  showAddDialog: function (projectId) {
    $('editImageDialogBody').innerHTML = '<i class="icon-refresh icon-spin ring-loader-inline"></i> Loading...';
    BS.Clouds.Admin.Images.EditDialog.showCentered();
    BS.ajaxUpdater($("editImageDialogBody"), window['base_uri'] + '/clouds/admin/projectImages.html', {
      method: 'get',
      evalScripts: true,
      parameters: {
        projectId: projectId
      }
    });
  },

  showEditDialog: function (imageId) {
    BS.Clouds.Admin.Images.EditDialog.showCentered();
  },

  showRemoveDialog: function (imageId) {
    BS.Clouds.Admin.Images.RemoveDialog.showCentered();
  }
};

BS.Clouds.Admin.Images.EditDialog = OO.extend(BS.AbstractModalDialog, {
  getContainer: function () {
    return $('EditImageDialogFormDialog');
  },

  submit: function (projectId) {
    var that = this;
    var sourceImageInternalId = $j('#sourceImageInternalId').val();
    var sourceImageProjectId = $j('#sourceImageProjectId').val();
    if(sourceImageInternalId && sourceImageProjectId){
      BS.ajaxRequest(window['base_uri'] + '/clouds/admin/projectImages.html', {
        method: 'post',
        evalScripts: true,
        parameters: {
          action: 'add',
          projectId: projectId,
          sourceImageProjectId: sourceImageProjectId,
          sourceImageInternalId: sourceImageInternalId
        },
        onComplete: function () {
          that.close();
          BS.Clouds.Admin.refresh();
        }
      });
    } else{
      BS.Log.error("sourceImageInternalId OR sourceImageProjectId values were not resolved")
    }
    return false;
  },

  formElement: function () {
    return $('EditImageDialogForm');
  },

  selectImage: function () {
    var selector = $('image');
    var selectedIndex = selector.selectedIndex;
    if (selectedIndex <= 0) {
      return;
    }
    $j('#sourceImageInternalId').val(selector.options[selectedIndex].value);
    $j('#sourceImageProjectId').val(selector.options[selectedIndex].readAttribute('data-filter-data'));
  }
});

BS.Clouds.Admin.Images.RemoveDialog = OO.extend(BS.AbstractModalDialog, {
  getContainer: function () {
    return $('RemoveImageDialogFormDialog');
  },

  formElement: function () {
    return $('RemoveImageDialogForm');
  }
});

{
  const hiddenClass = 'grid-types-hidden';
  const getHeaderTextEls = () => document.querySelectorAll('.grid-type__header-text');
  const headerToggleSelector = '#backToProviderPickerButton.grid-type__header-button';
  const getHeaderToggleEls = () => document.querySelectorAll(headerToggleSelector);
  const getBackToCloudButtons = () => document.querySelectorAll('#backToCloudAgentsButton.grid-type__header-button');
  const getSelectorEls = () => document.querySelectorAll('.grid-types-selector');

  const setCloudType = (type) => {
    const cloudTypeSelectorEl = document.getElementById('cloudType');
    cloudTypeSelectorEl.setValue(type);
    cloudTypeSelectorEl.dispatchEvent(new Event('change'));
  };

  const hideElements = (elems) => {
    elems.forEach(elem => elem.classList.add(hiddenClass))
  };

  const showElements = (elems) => {
    elems.forEach(elem => elem.classList.remove(hiddenClass))
  };

  document.addEventListener('click', event => {
    const headerToggleEl = event.target.closest(headerToggleSelector);
    if (headerToggleEl != null) {
      const formDialogEl = document.getElementById('newProfileFormDialog');
      formDialogEl.classList.add(hiddenClass);
      hideElements(getHeaderToggleEls());
      showElements(getHeaderTextEls());
      showElements(getSelectorEls());
      showElements(getBackToCloudButtons());
    };
  });

  document.addEventListener('click', event => {
    const containerEl = event.target.closest('.grid-types-layout .type__item');
    if (containerEl != null) {
      const cloudCode = containerEl.dataset.code;

      setCloudType(cloudCode);

      [...document.querySelectorAll(`.${hiddenClass}`)].forEach(item => {
        item.classList.remove(hiddenClass);
      });

      hideElements(getHeaderTextEls());
      hideElements(getSelectorEls());
      showElements(getHeaderToggleEls());
      hideElements(getBackToCloudButtons());
    };
  });
};
