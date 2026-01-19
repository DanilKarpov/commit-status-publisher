<%@ taglib prefix="forms" uri="http://www.springframework.org/tags/form" %>
<%@ page import="jetbrains.buildServer.serverSide.auth.Permission" %>
<%@include file="/include-internal.jsp" %>
<jsp:useBean id="currentProject" type="jetbrains.buildServer.serverSide.impl.ProjectEx" scope="request"/>
<jsp:useBean id="settingsBean" type="jetbrains.buildServer.controllers.project.VersionedSettingsBean" scope="request"/>
<c:set var="configuredVcsRoot" value="${settingsBean.configuredVcsRoot}"/>
<c:set var="enabled" value="${settingsBean.enabledGlobally and not settingsBean.containsConvertedFiles}"/>
<c:set var="syncMode" value="${settingsBean.synchronizationMode}"/>
<c:set var="useCredentialsStorage" value="${settingsBean.useCredentialsStorage}"/>
<c:set var="availableFormats" value="${settingsBean.availableSettingsFormats}"/>
<c:set var="showNonPortableDSLOption" value="${currentProject.getBooleanInternalParameter('kotlinDsl.newProjects.allowUsingNonPortableDSL')}"/>
<c:set var="showHiddenDSLFormats" value="${currentProject.getBooleanInternalParameter('versionedSettings.showHidden')}"/>
<bs:linkScript>
  /js/bs/versionedSettings.js
</bs:linkScript>
<style type="text/css">
  ul#dirNameList {
    list-style-type: none;
  }

  div#nonEmptyDirConfirmDialog {
    width: 45em;
  }

  div.commitProjectSettingsWrapper {
    margin-top: 1em;
    margin-left: 0.5em;
  }

  span#error_settingsVcsRootId {
    margin-left: 0px;
  }

  .selectRootLabel {
    vertical-align: top;
  }

  a#downloadSample {
    margin-left: 1em;
  }

  ul#dirNameList {
    max-height: 30em;
    overflow-y: auto;
  }

  div#loadSettingsConfirmDialog {
    width: 45em;
  }

  ul#projectList {
    max-height: 30em;
    overflow-y: auto;
    max-width: 40em;
    white-space: nowrap;
  }

  div.disabledSettingsNote {
    margin-top: 1em;
  }

  span#format_documentation {
    margin-left: .5em;
  }
</style>

<script type="text/javascript">
  BS.NonEmptyDirConfirm = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
    formElement: function() {
      return $('nonEmptyDirConfirm');
    },

    getContainer: function() {
      return $('nonEmptyDirConfirmDialog');
    },

    show: function(dirNames) {
      $j('#dirNameList').empty();
      for (var i = 0; i < dirNames.length; i++) {
        var li = document.createElement("li");
        $j(li).text(dirNames[i]);
        $j('#dirNameList').append(li);
      }
      this.showCentered();
    },

    submit: function(confirmDecision) {
      $j('#confirmation').val(confirmDecision);
      BS.VersionedSettingsForm.applySettings(true);
      this.doClose();
    },

    close: function() {
      this.doClose();
    }
  }));


  BS.LoadSettingsConfirm = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
    formElement: function() {
      return $('loadSettingsConfirm');
    },

    getContainer: function() {
      return $('loadSettingsConfirmDialog');
    },

    show: function() {
      this.showCentered();
      $j('#loadSettingsConfirmSubmit').focus();
    },

    submit: function() {
      BS.Util.disableFormTemp(this.formElement());
      BS.VersionedSettingsForm.disableAll();
      $j('#loadSaving').show();
      BS.ajaxRequest('<c:url value="/admin/versionedSettingsActions.html"/>', {
        parameters: Object.toQueryString({action: 'loadProjectSettings', projectId: '${currentProject.externalId}'}),
        onComplete: function(transport) {
          BS.LoadSettingsConfirm.close();
          $j('#versionedSettingsTabs').get(0).refresh();
        }
      });
    }
  }));

  BS.VersionedSettingsForm = OO.extend(BS.AbstractWebForm, {
    documentationUrls: {
      <c:forEach var="format" items="${availableFormats}" varStatus="status">
      "${format.id}": "${empty format.documentationUrl ? "" : format.documentationUrl}"<c:if test="${not status.last}">,</c:if>
      </c:forEach>
    },

    supportsRelativeIds: {
      <c:forEach var="format" items="${availableFormats}" varStatus="status">
      "${format.id}": ${format.supportsRelativeIds}<c:if test="${not status.last}">,</c:if>
      </c:forEach>
    },

    formElement: function() {
      return $('versionedSettingsConfigForm');
    },

    applySettings: function (confirmed) {
      var msg = this.getConfirmation();
      if (confirmed || !msg || confirm(msg)) {
        $j('#versionedSettingSavings').show();
        BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
          vcsRootNotSpecified: function(elem) {
            $j('#versionedSettingSavings').hide();
            $('error_settingsVcsRootId').innerHTML = elem.firstChild.nodeValue;
          },
          settingsPathError: function(elem) {
            $j('#versionedSettingSavings').hide();
            $('error_customSettingsPath').innerHTML = elem.firstChild.nodeValue;
          },
          versionedSettingsGloballyDisabled: function (elem) {
            $j('#versionedSettingSavings').hide();
            alert(elem.firstChild.nodeValue);
          },
          versionedSettingsConfigChangeIsUnsupported: function (elem) {
            $j('#versionedSettingSavings').hide();
            alert(elem.firstChild.nodeValue);
          },
          settingsMixDetected: function (elem) {
            $j('#versionedSettingSavings').hide();
            alert(elem.firstChild.nodeValue);
          },
          readOnlyProject: function (elem) {
            $j('#versionedSettingSavings').hide();
            alert(elem.firstChild.nodeValue);
          },
          commitProjectSettingsFailed: function (elem) {
            $j('#versionedSettingSavings').hide();
            alert(elem.firstChild.nodeValue);
          },
          onSuccessfulSave: function (responseXML) {
            $j('#versionedSettingSavings').hide();
            var confirmation = responseXML.getElementsByTagName('confirmOverrideVcs')[0];
            if (confirmation) {
              var dirs = confirmation.getElementsByTagName('dir');
              var dirNames = [];
              for (var i = 0; i < dirs.length; i ++) {
                dirNames.push(dirs[i].getAttribute('project'));
              }
              BS.NonEmptyDirConfirm.show(dirNames);
            } else {
              $j('#versionedSettingsTabs').get(0).refresh();
            }
          }
        }));
      }

      return false;
    },

    getConfirmation: function() {
      //don't show confirmation if:
      //- VCS root is not selected: server will not allow to save such settings
      //- syncMode is not 'enabled': no confirm required for 'disabled' and
      //- syncMode was already 'enabled'
      //  disabling editing via UI when 'same as parent' is selected most likely won't surprise
      var root = $j("#settingsVcsRootId").val();
      var syncMode = $j("[name=synchronizationMode]:checked").val();
      var useCreStorage = $j("[name=useCredentialsStorage]:checked").val();
      var format = $j("#settingsFormat").val();//undefined if no custom formats found
      if (root == '' || syncMode != 'enabled' || ('enabled' == '${syncMode}' && useCreStorage == ${useCredentialsStorage}) || ${not settingsBean.enabledGlobally}) {
        return null;
      }

      var result = !useCreStorage ? 'Passwords from VCS roots, build configurations, templates, and projects will be scrambled and committed to VCS. ' : '';
      if (result) {
        result += 'Do you want to continue?';
      }
      return result;
    },

    hideCommitAndLoadProjectSettings: function() {
      $j('#commitProjectSettings').hide();
      $j('#loadProjectSettings').hide();
    },

    disableAll: function() {
      this.disable();
      $j('#commitProjectSettings').attr("disabled", "disabled");
      $j('#loadProjectSettings').attr("disabled", "disabled");
    },

    commitProjectSettings: function(element) {
      if ($j(element).attr("disabled") == "disabled") {
        return false;
      }
      BS.confirm("Commit current settings of this project and all sub projects with the same versioned settings configuration in VCS?", function () {
        this.disableAll();
        $j('#commitSaving').show();
        BS.ajaxRequest('<c:url value="/admin/versionedSettingsActions.html"/>', {
          parameters: Object.toQueryString({action: 'commitProjectSettings', projectId: '${currentProject.externalId}'}),
          onComplete: function(transport) {
            $j('#versionedSettingsTabs').get(0).refresh();
          }
        });
      }.bind(this));
      return false;
    },

    loadProjectSettings: function(element) {
      if ($j(element).attr("disabled") == "disabled") {
        return false;
      }
      BS.LoadSettingsConfirm.show();
      return false;
    },

    changeSynchMode: function(syncMode) {
      if (syncMode == 'default') {
        $j('#versionedSettingsEnabledSection').hide();
        $j('#editSettingsRoot').hide();
        $j('.advancedSettingsToggle').hide();
        this.hideCommitAndLoadProjectSettings();
      } else if (syncMode == 'disabled') {
        $j('#versionedSettingsEnabledSection').hide();
        $j('#editSettingsRoot').hide();
        $j('.advancedSettingsToggle').hide();
        this.hideCommitAndLoadProjectSettings();
      } else if (syncMode == 'enabled') {
        $j('#versionedSettingsEnabledSection').show();
        $j('.advancedSettingsToggle').show();
        this.hideCommitAndLoadProjectSettings();
      } else {
        console.error('Unknown sync mode', syncMode);
      }
    },

    partiallyDisable: function() {
      //disable all fields except the option disabling versioned settings,
      //so they can always be disabled
      $j('#useParentSettings').prop('disabled', 'disabled');
      $j('#enabled').prop('disabled', 'disabled');
      $j('#settingsVcsRootId').prop('disabled', 'disabled');
      $j('#buildSettingsModeAlwaysCurrent').prop('disabled', 'disabled');
      $j('#buildSettingsModePreferCurrent').prop('disabled', 'disabled');
      $j('#buildSettingsModePreferVcs').prop('disabled', 'disabled');
      $j('#showSettingsChanges').prop('disabled', 'disabled');
      $j('#settingsFormat').prop('disabled', 'disabled');
      $j('#useRelativeIds').prop('disabled', 'disabled');
      $j('#useCredentialsStorage').prop('disabled', 'disabled');
      $j('#useTwoWaySynchronization').prop('disabled', 'disabled');
      $j('#applyChangesInDependenciesAndVcsSettings').prop('disabled', 'disabled');
      $j('#customSettingsPath').prop('disabled', 'disabled');
    },

    versionedSettingsRootChanged: function() {
      <c:if test="${not empty configuredVcsRoot}">
      this.hideCommitAndLoadProjectSettings();
      if ('${configuredVcsRoot.externalId}' == $j('#settingsVcsRootId').val()) {
        $j('#editSettingsRoot').show();
      } else {
        $j('#editSettingsRoot').hide();
      }
      </c:if>

      <c:if test="${empty configuredVcsRoot}">
      if ($j('#settingsVcsRootId').val() == '') {
        $j('#createSettingsRoot').show();
      } else {
        $j('#createSettingsRoot').hide();
      }
      </c:if>
    },

    showDocumentation: function() {
      var url = null;
      var format = $j("#settingsFormat").val();
      if (format) {
        url = BS.VersionedSettingsForm.documentationUrls[format];
      }

      if (url) {
        $j('#format_documentation').html('<a href="' + url + '" target="_blank">Documentation</a>');
      } else {
        $j('#format_documentation').html('');
      }
    },

    showRelativeIds: function() {
      var format = $j("#settingsFormat").val();
      if (format && BS.VersionedSettingsForm.supportsRelativeIds[format]) {
        $j('#useRelativeIdsRow').show();
      } else {
        $j('#useRelativeIdsRow').hide();
      }
    },

    updateFormatDependentSettings: function() {
      this.showDocumentation();
      this.showRelativeIds();
    }
  });

  <c:choose>
    <c:when test="${not afn:permissionGrantedForProject(currentProject, 'EDIT_PROJECT')}">
      $j(document).ready(function() {
        BS.VersionedSettingsForm.disable();
      });
    </c:when>
    <c:when test="${not enabled and syncMode != 'enabled'}">
      <%-- versioned settings are not enabled in the project - don't allow to change anything --%>
      $j(document).ready(function() {
        BS.VersionedSettingsForm.disable();
      });
    </c:when>
    <c:when test="${not enabled and syncMode == 'enabled'}">
      $j(document).ready(function() {
        BS.VersionedSettingsForm.partiallyDisable();
      });
    </c:when>
    <c:when test="${empty configuredVcsRoot and not empty createdVcsRoot and syncMode != 'enabled'}">
      $j(document).ready(function() {
        $j('#enabled').click();
      });
    </c:when>
  </c:choose>

  $j(document).ready(function() {
    BS.VersionedSettingsForm.updateFormatDependentSettings();
  });
</script>
<c:set var="pageTitle" value="Versioned Settings"/>
<c:set var="suitableVcses" value="${settingsBean.versionedSettingsSuitableVcses}"/>
<c:set var="suitableRoots" value="${settingsBean.versionedSettingsSuitableVcsRoots}"/>
<c:set var="effectiveParentSettings" value="${settingsBean.effectiveParentSettings}"/>
<c:set var="supportedVcses"><c:forEach items="${suitableVcses}" var="vcs" varStatus="pos"><strong><c:out value="${vcs.core.displayName}"/></strong><c:if test="${not pos.last}">, </c:if></c:forEach></c:set>

<div class="grayNote" style="margin-top: 1em;">
  <p>
    This page allows you to enable configuration-as-code by storing project and build configuration settings in a remote repository in Kotlin DSL or XML format. You can choose from two sync modes:
  </p>
  <ul>
    <li>
      One-way &ndash; settings are editable only via the repository. Choose "Synchronization enabled" and disable "Allow editing project settings via UI"
    </li>
    <li>
      Two-way &ndash; changes sync between the UI and the repository. Choose "Synchronization enabled" and enable "Allow editing project settings via UI"
    </li>
  </ul>
  <c:if test="${intprop:getBoolean('teamcity.pipelines.enabled')}">
    <p>
      Note that pipeline and job settings are excluded from Kotlin/XML configuration. Their configuration is stored in a separate YAML file: open pipeline repository settings and choose a required "Store the configuration YAML file" mode.
    </p>
  </c:if>
</div>

<bs:unprocessedMessages/>

<c:set var="canEdit" value="${afn:permissionGrantedForProject(currentProject, 'EDIT_VERSIONED_SETTINGS')}"/>

<c:if test="${!hasPermissionToEdit}">
  <div style="margin-top: 1em;">
    <bs:buildStatusIcon type="red-sign" className="warningIcon"/>These settings are disabled as you do not have '<%=Permission.EDIT_VERSIONED_SETTINGS.getDescription()%>' permission.
    <bs:help file="Storing+Project+Settings+in+Version+Control" anchor="SynchronizingSettingswithVCS"/>
  </div>
</c:if>

<c:if test="${not enabled}">
  <div class="disabledSettingsNote">
    <c:choose>
      <c:when test="${not settingsBean.enabledGlobally}">
        <bs:buildStatusIcon type="red-sign" className="warningIcon"/>Versioned settings are globally disabled on the server, contact your system administrator for details
      </c:when>
      <c:when test="${settingsBean.containsConvertedFiles}">
        <c:set var="inheritedSettings" value="${settingsBean.synchronizationMode == 'default' and not empty effectiveParentSettings}"/>
        <bs:buildStatusIcon type="red-sign" className="warningIcon"/>Versioned settings are disabled in this project because its settings files were modified during TeamCity upgrade.
        <c:choose>
          <c:when test="${inheritedSettings}">
            Enable versioned settings in the <admin:projectName project="${effectiveParentSettings.project}" addToUrl="&tab=versionedSettings"/>
            project to commit updated configs to VCS.
          </c:when>
          <c:otherwise>
            Enable versioned settings to commit updated configs to VCS.
          </c:otherwise>
        </c:choose>
        <c:if test="${canEdit and not inheritedSettings}">
          <input type="button" class="btn btn_mini" value="Enable" title="Enable versioned settings" onclick="BS.VersionedSettings.enableProjectVersionedSettings('${currentProject.externalId}', '#enablingProjectVersionedSettingsInForm')"/>
          <forms:saving id="enablingProjectVersionedSettings" style="float: none; margin-left: 0.5em;"/>
        </c:if>
      </c:when>
    </c:choose>
  </div>
</c:if>

<c:set var="versionedSettingsConfigReadOnly" value="${not canEdit or not settingsBean.versionedSettingsConfigUpdateSupported}"/>
<c:set var="formTitle">
  <c:choose>
    <c:when test="${not settingsBean.enabledGlobally}">Versioned settings are globally disabled on the server</c:when>
    <c:when test="${settingsBean.containsConvertedFiles}">Versioned settings are disabled because project configs were converted on the server</c:when>
    <c:otherwise></c:otherwise>
  </c:choose>
</c:set>

<form id="versionedSettingsConfigForm" action="<c:url value='/admin/versionedSettings.html'/>" method="post" onsubmit="return BS.VersionedSettingsForm.applySettings()"
      title="${not settingsBean.enabledGlobally ? 'Versioned settings are globally disabled on the server' : ''}">
  <table class="synchronizationMode">
    <c:if test="${not currentProject.rootProject}">
    <tr>
      <td><forms:radioButton disabled="${not canEdit or (versionedSettingsConfigReadOnly and syncMode != 'default')}" name="synchronizationMode" id="useParentSettings" value="default" checked="${syncMode == 'default'}" onclick="BS.VersionedSettingsForm.changeSynchMode('default');"/>
        <label for="useParentSettings">Use settings from a parent project</label>
        <c:if test="${not empty effectiveParentSettings}"> (<admin:projectName project="${effectiveParentSettings.project}" addToUrl="&tab=versionedSettings"><c:out value="${effectiveParentSettings.project.fullName}"/></admin:projectName>)</c:if>
        <c:if test="${empty effectiveParentSettings}">(there are no parent projects with enabled versioned settings)</c:if>
      </td>
    </tr>
    </c:if>
    <tr>
      <td><forms:radioButton disabled="${not canEdit or settingsBean.readOnlyNotBecauseOfVersionedSettings}" name="synchronizationMode" id="disabled" value="disabled" checked="${syncMode == 'disabled'}" onclick="BS.VersionedSettingsForm.changeSynchMode('disabled');"/>
        <label for="disabled">Synchronization disabled</label></td>
    </tr>
    <tr>
      <td>
        <forms:radioButton disabled="${not canEdit or (versionedSettingsConfigReadOnly and syncMode != 'enabled')}" name="synchronizationMode" id="enabled" value="enabled" checked="${syncMode == 'enabled'}" onclick="BS.VersionedSettingsForm.changeSynchMode('enabled');"/>
        <label for="enabled">Synchronization enabled</label>
      </td>
    </tr>
    <tr id="versionedSettingsEnabledSection" style="display: ${syncMode == 'enabled' ? '' : 'none'};">
      <td>
        <table style="width:70%;">
          <tr>
            <td class="selectRootLabel" style="width:20%">
              <label for="settingsVcsRootId">Project settings VCS root:</label>
            </td>
            <td style="width:80%">
              <forms:select name="settingsVcsRootId" enableFilter="true" onchange="BS.VersionedSettingsForm.versionedSettingsRootChanged();" disabled="${versionedSettingsConfigReadOnly}">
                <forms:option value="">-- Choose VCS root --</forms:option>
                <c:set var="prevProjId" value=""/>
                <c:set var="hasSelectedVcsRoot" value="${false}"/>
                <c:forEach items="${suitableRoots}" var="vcsRoot">
                  <c:set var="createGroup">
                    ${vcsRoot.scope.ownerProjectId != prevProjId}
                  </c:set>
                  <c:if test="${createGroup}">
                    <optgroup value="" label="-- <c:out value="${vcsRoot.project.fullName}"/> project VCS roots --">
                    <c:set var="prevProjId" value="${vcsRoot.scope.ownerProjectId}"/>
                  </c:if>
                  <c:set var="vcsRootSelected" value="${(not empty configuredVcsRoot and configuredVcsRoot.externalId == vcsRoot.externalId) or (empty configuredVcsRoot and not empty createdVcsRoot and createdVcsRoot.externalId == vcsRoot.externalId)}"/>
                  <forms:option value="${vcsRoot.externalId}" className="user-depth-2" selected="${vcsRootSelected}"><c:out value="${vcsRoot.name}"/></forms:option>
                  <c:if test="${vcsRootSelected}"><c:set var="hasSelectedVcsRoot" value="${true}"/></c:if>
                  <c:if test="${createGroup}">
                    </optgroup>
                  </c:if>
                </c:forEach>
              </forms:select>
              <c:if test="${not empty configuredVcsRoot and afn:canEditVcsRoot(configuredVcsRoot)}">
                <span id="editSettingsRoot" style="margin-left: 1em;">
                  <admin:editVcsRootLink vcsRoot="${configuredVcsRoot}" editingScope="editProject:${currentProject.externalId}" cameFromUrl="${pageUrl}">Edit VCS root</admin:editVcsRootLink>
                </span>
              </c:if>
              <c:if test="${afn:permissionGrantedForProject(currentProject, 'EDIT_PROJECT')}">
              <c:set var="versionedSettingsUrl"><admin:editProjectLink projectId="${currentProject.externalId}" withoutLink="true" addToUrl="&tab=versionedSettings&versionedSettingsRootCreated=true"/></c:set>
              <c:set var="createVcsRootUrl"><admin:createVcsRootLink editingScope="editProject:${currentProject.externalId}" cameFromUrl="${versionedSettingsUrl}" withoutLink="true"/></c:set>
              <span id="createSettingsRoot" style="margin-left: 1em; display: ${hasSelectedVcsRoot ? 'none' : ''};">
                <a href="${createVcsRootUrl}">Create VCS root</a>
              </span>
              </c:if>

              <span class="error" id="error_settingsVcsRootId" ></span>
            </td>
          </tr>

          <c:set var="currentFormat" value="${settingsBean.settingsFormat}"/>
          <c:if test="${fn:length(availableFormats) > 1}">
            <tr>
              <td style="padding-top: 10px">
                <label for="settingsFormat">Settings format:</label>
              </td>
              <td style="padding-top: 10px">
                <forms:select name="settingsFormat" enableFilter="true" disabled="${versionedSettingsConfigReadOnly or (currentFormat ne 'xml' and currentFormat ne '')}"
                              onchange="BS.VersionedSettingsForm.updateFormatDependentSettings()">
                  <c:forEach var="format" items="${availableFormats}">
                    <c:if test="${format.visible or showHiddenDSLFormats or currentFormat == format.id}">
                      <forms:option value="${format.id}" selected="${format.id == currentFormat}"><c:out value="${format.name}"/>${format.id == currentFormat and format.id ne 'xml' and not settingsBean.checkedRelativeIds ? ' (non portable)' : ''}</forms:option>
                    </c:if>
                  </c:forEach>
                </forms:select>

                <c:if test="${not showNonPortableDSLOption}">
                  <input type="hidden" name="useRelativeIds" value="${settingsBean.checkedRelativeIds}"/>
                </c:if>

                <span id="format_documentation"></span>
              </td>
            </tr>
            <c:if test="${showNonPortableDSLOption}">
              <tr id="useRelativeIdsRow" style="display: ${currentFormat eq 'xml' ? 'none' : ''}">
                <td colspan="2" style="padding-left: 2em;">
                  <forms:checkbox name="useRelativeIds" id="useRelativeIds" value="true" disabled="${versionedSettingsConfigReadOnly or currentFormat ne 'xml'}" checked="${settingsBean.checkedRelativeIds}"/>
                  <label for="useRelativeIds">Generate portable DSL scripts<bs:help file="Kotlin+DSL" anchor="portableDSL"/></label>
                </td>
              </tr>
            </c:if>
          </c:if>

          <c:if test="${settingsBean.customSettingsPathEnabled or not empty settingsBean.customSettingsPath}">
            <tr id="customSettingsPathRow" class="advancedSetting">
              <td style="padding-top: 10px">
                <label for="customSettingsPath">Settings path in VCS:</label>
              </td>
              <td style="padding-top: 10px">
                <forms:textField name="customSettingsPath" id="customSettingsPath" style="width:100%;"
                                 value="${empty settingsBean.customSettingsPath ? settingsBean.defaultSettingsPath : settingsBean.customSettingsPath}"
                                 disabled="${versionedSettingsConfigReadOnly or (syncMode == 'enabled')}"/>

                <span class="error" id="error_customSettingsPath" style="margin-left: 0;"></span>
              </td>
            </tr>
            <tr id="customSettingsPathHint" class="advancedSetting">
              <td/>
              <td colspan="2">
                <div class="grayNote">
                  Specify a directory for versioned project settings.
                  Custom directories enable distinct settings for different projects targeting the same VCS repository.
                  If this setting is empty, the default directory will be used. <br/>
                  Enter "." to save settings directly to the repository root.
                  Be aware, TeamCity may clear the target directory before committing new files.
                  Use "." solely for repositories that should store nothing but project settings.
                </div>
              </td>
            </tr>
          </c:if>

          <c:if test="${settingsBean.showUseTwoWaySynchronizationOption}">
            <tr>
              <td colspan="2">
                <forms:checkbox name="useTwoWaySynchronization" id="useTwoWaySynchronization" value="true" checked="${settingsBean.useTwoWaySynchronization}"
                                disabled="${versionedSettingsConfigReadOnly}" className="${not settingsBean.useTwoWaySynchronization ? 'valueChanged' : ''}"
                                onclick="if (this.checked) { BS.Util.show('credentialsStorageRow') } else { BS.Util.hide('credentialsStorageRow') }"/>
                <label for="useTwoWaySynchronization">Allow editing project settings via UI</label>
                <div class="grayNote" style="padding-left: 1.5em;">
                  If enabled, changes of the project / build configuration settings made via the user interface or REST API will be checked in to the settings repository.
                  If disabled, the project will be read-only.
                </div>
              </td>
            </tr>

            <tr id="credentialsStorageRow" style="display: ${not settingsBean.useTwoWaySynchronization ? 'none' : ''}">
              <td colspan="2" style="padding-left: 2em">
                <forms:checkbox name="useCredentialsStorage" id="useCredentialsStorage" value="true" checked="${settingsBean.useCredentialsStorage}"
                                disabled="${versionedSettingsConfigReadOnly}" className="${not settingsBean.useCredentialsStorage ? 'valueChanged' : ''}"/>
                <label for="useCredentialsStorage">Store passwords and API tokens outside of VCS</label>
              </td>
            </tr>
          </c:if>

          <tr class="advancedSetting">
            <td colspan="2" style="padding-top: 10px">
              <label for="buildSettingsMode">When build starts:<bs:help file="Storing+Project+Settings+in+Version+Control" anchor="DefiningSettingstoApplytoBuilds"/></label>
            </td>
          </tr>
          <tr class="advancedSetting">
            <td colspan="2" style="padding-left: 2em; padding-top: 0;">
              <forms:radioButton disabled="${versionedSettingsConfigReadOnly}" name="buildSettingsMode" id="buildSettingsModeAlwaysCurrent" value="${settingsBean.alwaysUseCurrentModeName}"
                                 checked="${settingsBean.buildSettingsMode == settingsBean.alwaysUseCurrentModeName}"/>
              <label for="buildSettingsModeAlwaysCurrent">always use current settings</label>
              <div class="grayNote" style="padding-left: 1.5em;">
                All the builds use current project settings from the TeamCity server. Settings changes in branches, history and personal builds are ignored.
              </div>
            </td>
          </tr>
          <tr class="advancedSetting">
            <td colspan="2" style="padding-left: 2em; padding-top: 0;">
              <forms:radioButton disabled="${versionedSettingsConfigReadOnly}" name="buildSettingsMode" id="buildSettingsModePreferCurrent" value="${settingsBean.preferCurrentModeName}"
                                 checked="${settingsBean.buildSettingsMode == settingsBean.preferCurrentModeName}" className="${settingsBean.buildSettingsMode == settingsBean.preferCurrentModeName ? 'valueChanged' : ''}"/>
              <label for="buildSettingsModePreferCurrent">use current settings by default</label>
              <div class="grayNote" style="padding-left: 1.5em;">
                Builds use current project settings from the TeamCity server. Users can run a build with settings from VCS via the run custom build dialog.
              </div>
            </td>
          </tr>
          <tr class="advancedSetting">
            <td colspan="2" style="padding-left: 2em; padding-top: 0;">
              <forms:radioButton disabled="${versionedSettingsConfigReadOnly}" name="buildSettingsMode" id="buildSettingsModePreferVcs" value="${settingsBean.preferVcsModeName}"
                                 checked="${settingsBean.buildSettingsMode == settingsBean.preferVcsModeName}" className="${settingsBean.buildSettingsMode == settingsBean.preferVcsModeName ? 'valueChanged' : ''}"/>
              <label for="buildSettingsModePreferVcs">use settings from VCS</label>
              <div class="grayNote" style="padding-left: 1.5em;">
                Builds in branches and history builds use settings from corresponding branch and revision in VCS. Developers can also change settings in <b>personal</b> builds.
              </div>
            </td>
          </tr>

          <tr class="advancedSetting">
            <td colspan="2">
              <forms:checkbox name="applyChangesInDependenciesAndVcsSettings" id="applyChangesInDependenciesAndVcsSettings" checked="${settingsBean.applyChangesInDependenciesAndVcsSettings}"
                              className="${settingsBean.applyChangesInDependenciesAndVcsSettings ? 'valueChanged' : ''}" disabled="${versionedSettingsConfigReadOnly}"/>
              <label for="applyChangesInDependenciesAndVcsSettings">Apply changes in snapshot dependencies and version control settings</label>
              <div class="grayNote" style="padding-left: 1.5em;">
                If enabled, then VCS roots, checkout rules and snapshot dependencies changes made in versioned settings in a branch will be applied to the builds triggered in this branch.
                Otherwise, such changes will be ignored and snapshot dependencies configuration as well as settings of VCS roots and checkout rules will be taken from the current project settings.
              </div>
            </td>
          </tr>

          <tr id="showSettingsChangesRow" class="advancedSetting">
            <td colspan="2">
              <forms:checkbox name="showSettingsChanges" id="showSettingsChanges" value="true" checked="${settingsBean.showSettingsChanges}"
                              disabled="${versionedSettingsConfigReadOnly}" className="${settingsBean.showSettingsChanges ? 'valueChanged' : ''}"/>
              <label for="showSettingsChanges">Show settings changes in builds</label>
            </td>
          </tr>

          <c:if test="${not settingsBean.showUseTwoWaySynchronizationOption}">
            <tr id="credentialsStorageRow" class="advancedSetting">
              <td colspan="2">
                <forms:checkbox name="useCredentialsStorage" id="useCredentialsStorage" value="true" checked="${settingsBean.useCredentialsStorage}"
                                disabled="${versionedSettingsConfigReadOnly}" className="${not settingsBean.useCredentialsStorage ? 'valueChanged' : ''}"/>
                <label for="useCredentialsStorage">Store secure values (like passwords or API tokens) outside of VCS</label>
              </td>
            </tr>
          </c:if>

        </table>
      </td>
    </tr>

    <c:if test="${canEdit}">
    <tr id="versionedSettingSaveRow">
      <td>
        <admin:showHideAdvancedOpts containerId="versionedSettingsEnabledSection" optsKey="versionedSettings"/>
        <script type="text/javascript">$j('.advancedSettingsToggle').hide();</script>
        <c:if test="${syncMode == 'enabled'}">
          <script type="text/javascript">$j('.advancedSettingsToggle').show();</script>
        </c:if>

        <forms:submit label="Apply" disabled="${settingsBean.readOnlyNotBecauseOfVersionedSettings}"/>
        <forms:saving id="versionedSettingSavings" style="float: none;"/>
        <input type="hidden" name="projectId" value="${currentProject.externalId}"/>
      <c:if test="${not settingsBean.showUseTwoWaySynchronizationOption}">
        <input type="hidden" name="useTwoWaySynchronization" value="true"/>
      </c:if>
      </td>
    </tr>
    </c:if>
  </table>
  <input type="hidden" id="confirmation" name="confirmation" value=""/>
</form>

<c:import url="/versionedSettingsStatus.html?projectId=${currentProject.externalId}"/>

<c:if test="${canEdit and settingsBean.syncEnabled}">
<div class="commitProjectSettingsWrapper">
  <c:if test="${settingsBean.useTwoWaySynchronization}">
  <forms:button id="commitProjectSettings" onclick="return BS.VersionedSettingsForm.commitProjectSettings(this)" disabled="${not enabled}"
                title="${not settingsBean.enabledGlobally ? 'Versioned settings are globally disabled on the server' : 'Commit current TeamCity server settings of this project and all its children which use same versioned settings configuration'}">
    Commit current project settings&hellip;
  </forms:button>
  </c:if>
  <forms:button id="loadProjectSettings" onclick="return BS.VersionedSettingsForm.loadProjectSettings(this)" disabled="${not enabled}"
                title="${not settingsBean.enabledGlobally ? 'Versioned settings are globally disabled on the server' : 'Load settings of this project and all its children from VCS'}">
    Load project settings from VCS&hellip;
  </forms:button>
  <forms:saving id="commitSaving" style="float: none;"/>
</div>
</c:if>

<bs:modalDialog formId="nonEmptyDirConfirm" title="Existing Project Settings Detected"
                action="" closeCommand="BS.NonEmptyDirConfirm.close()" saveCommand="BS.NonEmptyDirConfirm.submit();">
  <div id="confirmMessage">
    The settings of the following projects were found in the VCS:
    <ul id="dirNameList">
    </ul>
    How do you want to proceed?
  </div>

  <div style="margin-top: 1em;">
    <forms:submit id="overwriteButton" type="button" label="Overwrite settings in VCS" onclick="BS.NonEmptyDirConfirm.submit('override');"/>
    <forms:submit type="button" label="Import settings from VCS" onclick="BS.NonEmptyDirConfirm.submit('import');"/>
    <forms:cancel onclick="BS.NonEmptyDirConfirm.close();"/>
  </div>
</bs:modalDialog>

<bs:modalDialog formId="loadSettingsConfirm" title="Load settings from VCS"
                action="" closeCommand="BS.LoadSettingsConfirm.close()" saveCommand="BS.LoadSettingsConfirm.submit();">
  <c:set var="projectsInRoot" value="${settingsBean.allProjectsInRoot}"/>
  <c:set var="projectsInRootCount" value="${fn:length(settingsBean.allProjectsInRoot)}"/>
  <div>
    ${projectsInRootCount} <bs:plural txt="project" val="${projectsInRootCount}"/> use this VCS root to store settings:

    <ul id="projectList">
      <c:forEach items="${settingsBean.allProjectsInRoot}" var="p">
        <li><admin:projectName project="${p}" addToUrl="&tab=versionedSettings"><c:out value="${p.fullName}"/></admin:projectName></li>
      </c:forEach>
    </ul>

    <c:choose>
      <c:when test="${settingsBean.firstRevisionMissing}">
        Some changes in ${projectsInRootCount > 1 ? "these" : "this"} <bs:plural txt="project" val="${projectsInRootCount}"/> were not committed to VCS.
        <b>If you load settings from VCS, these changes will be lost. Do you want to continue?</b>
      </c:when>
      <c:otherwise>
        Do you want to load ${projectsInRootCount > 1 ? "their" : "its"} settings from VCS?
      </c:otherwise>
    </c:choose>
  </div>

  <div style="text-align: center; margin-top: 1em;">
    <forms:cancel onclick="BS.LoadSettingsConfirm.close();"/>
    <forms:submit type="button" id="loadSettingsConfirmSubmit" label="Load settings from VCS" onclick="BS.LoadSettingsConfirm.submit();"/>
    <forms:saving id="loadSaving" style="float: none;"/>
  </div>
</bs:modalDialog>