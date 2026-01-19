<%@ page import="jetbrains.buildServer.controllers.admin.projects.setupFromUrl.VcsUrlObjectSetupBean" %>
<%@ page import="jetbrains.buildServer.web.openapi.PlaceId" %>
<%@include file="/include-internal.jsp"%>
<jsp:useBean id="vcsUrlObjectSetupBean" type="jetbrains.buildServer.controllers.admin.projects.setupFromUrl.VcsUrlObjectSetupBean" scope="request"/>
<jsp:useBean id="cameFromSupport" type="jetbrains.buildServer.web.util.CameFromSupport" scope="request"/>
<bs:linkCSS>
  /css/admin/vcsSettings.css
</bs:linkCSS>

<div>

<c:url value="/admin/vcsUrlObjectSetup.html" var="action"/>
<form id="createProjectForm" action="${action}" method="post" onsubmit="return BS.VcsUrlObjectSetupForm.submit()">

  <div class="connectionSuccessful">
    <span class="checkmark">&#x2713;</span>
    The connection to the VCS repository has been verified
  </div>

  <c:choose>
  <c:when test="${vcsUrlObjectSetupBean.hasPermissionsToEnableVersionedSettings && vcsUrlObjectSetupBean.versionedSettingsFound and vcsUrlObjectSetupBean.objectType == 'PROJECT'}">
    <table class="runnerFormTable importSettings">
      <tr>
        <td colspan="2">
          <div>
            <bs:buildStatusIcon type="red-sign" className="warningIcon"/>
            The VCS repository contains <strong>.teamcity/settings.kts</strong> file with settings of some project. Would you like to import these settings?
          </div>
        </td>
      </tr>
      <tr>
        <td colspan="2" class="importOption">
          <c:set var="loadWithoutSyncMode" value="<%=VcsUrlObjectSetupBean.VcsSettingsMode.LOAD_WITHOUT_SYNC%>"/>
          <input type="radio" name="vcsSettingsOption" value="${loadWithoutSyncMode}" onclick="$j('#buildConfName').hide()" <c:if test="${loadWithoutSyncMode == vcsUrlObjectSetupBean.vcsSettingsOption || vcsUrlObjectSetupBean.vcsSettingsOption == null}">checked="checked"</c:if> id="vcsSettings_LOAD_WITHOUT_SYNC"/>
          <label for="vcsSettings_LOAD_WITHOUT_SYNC">Import settings from <strong>.teamcity/settings.kts</strong></label>
        </td>
      </tr>
      <tr>
        <td colspan="2">
          <c:set var="loadWithSyncMode" value="<%=VcsUrlObjectSetupBean.VcsSettingsMode.LOAD_AND_ENABLE_SYNC%>"/>
          <input type="radio" name="vcsSettingsOption" value="${loadWithSyncMode}" onclick="$j('#buildConfName').hide()" <c:if test="${loadWithSyncMode == vcsUrlObjectSetupBean.vcsSettingsOption}">checked="checked"</c:if> id="vcsSettings_LOAD_AND_ENABLE_SYNC"/>
          <label for="vcsSettings_LOAD_AND_ENABLE_SYNC">Import settings from <strong>.teamcity/settings.kts</strong> and enable synchronization with the VCS repository</label>
        </td>
      </tr>
      <tr>
        <td colspan="2">
          <c:set var="ignoreMode" value="<%=VcsUrlObjectSetupBean.VcsSettingsMode.IGNORE%>"/>
          <input type="radio" name="vcsSettingsOption" value="${ignoreMode}" onclick="$j('#buildConfName').show()" <c:if test="${ignoreMode == vcsUrlObjectSetupBean.vcsSettingsOption}">checked="checked"</c:if> id="vcsSettings_IGNORE"/>
          <label for="vcsSettings_IGNORE">Do not import settings, create project from scratch</label>
        </td>
      </tr>
      <tr>
        <td colspan="2">
          <div style="white-space: pre"><span class="error" id="error_projectSettingsImportFailed" style="margin-left: 0"></span></div>
        </td>
      </tr>
      </table>

      <table class="runnerFormTable" style="margin-top: 1em">
      <tr>
        <th>Project name:<l:star/></th>
        <td>
          <forms:textField name="projectName" value="${vcsUrlObjectSetupBean.projectName}" className="longField"/>
          <span class="error" id="error_projectName"></span>
          <span class="error" id="error_persistFailed"></span>
        </td>
      </tr>
      <tr style="display: none;" id="buildConfName">
        <th>Build configuration name:<l:star/></th>
        <td>
          <forms:textField name="buildTypeName" value="${vcsUrlObjectSetupBean.buildTypeName}" className="longField"/>
          <span class="error" id="error_buildTypeName"></span>
        </td>
      </tr>
      <tr>
        <th>VCS root:</th>
        <td>
          (<c:out value="${vcsUrlObjectSetupBean.detectedVcs.displayName}"/>) <c:out value="${vcsUrlObjectSetupBean.repositoryUrl}"/>
          <span class="error" id="error_vcsRoot"></span>
        </td>
      </tr>
      <ext:includeExtensions placeId="<%=PlaceId.ADMIN_CUSTOMIZE_VCS_ROOT%>"/>
      </table>

    <c:if test="${fn:length(vcsUrlObjectSetupBean.dslContextParams) > 0}">
      <div id="dslContextParams" style="margin-top: 1em;">
        <span class="red-text">Settings from <strong>.teamcity/settings.kts</strong> require the following context parameters:</span>
        <table class="runnerFormTable" style="margin-top: 1em">
          <c:forEach items="${vcsUrlObjectSetupBean.dslContextParams}" var="dslParam">
            <tr>
              <th>${dslParam.key}:<l:star/></th>
              <td>
                <c:set var="dslParamValue"><c:if test="${dslParam.value != null}">${dslParam.value}</c:if></c:set>
                <forms:textField name="dslContextParam_${dslParam.key}" className="longField" value="${dslParamValue}"/>
              </td>
            </tr>
          </c:forEach>
        </table>
      </div>
    </c:if>

  </c:when>
  <c:otherwise>
    <table class="runnerFormTable" style="margin-top: 1em;" id="createNewProjectForm">
      <c:if test="${vcsUrlObjectSetupBean.objectType == 'PROJECT'}">
        <tr>
          <th>Project name:<l:star/></th>
          <td>
            <forms:textField name="projectName" value="${vcsUrlObjectSetupBean.projectName}" className="longField"/>
            <span class="error" id="error_projectName"></span>
            <span class="error" id="error_persistFailed"></span>
          </td>
        </tr>
      </c:if>
      <tr>
        <th>Build configuration name:<l:star/></th>
        <td>
          <forms:textField name="buildTypeName" value="${vcsUrlObjectSetupBean.buildTypeName}" className="longField"/>
          <span class="error" id="error_buildTypeName"></span>
          <c:if test="${vcsUrlObjectSetupBean.objectType == 'BUILD_TYPE'}">
            <span class="error" id="error_persistFailed"></span>
          </c:if>
        </td>
      </tr>
      <tr>
        <th>VCS root:</th>
        <td>
          (<c:out value="${vcsUrlObjectSetupBean.detectedVcs.displayName}"/>) <c:out value="${vcsUrlObjectSetupBean.repositoryUrl}"/>
          <span class="error" id="error_vcsRoot"></span>
        </td>
      </tr>
      <ext:includeExtensions placeId="<%=PlaceId.ADMIN_CUSTOMIZE_VCS_ROOT%>"/>
    </table>

  </c:otherwise>
</c:choose>

<div class="saveButtonsBlock">
  <c:set var="selectedRoot" value=""/>
  <c:if test="${vcsUrlObjectSetupBean.selectedVcsRootId != null}">
    <c:set var="selectedRoot" value="${vcsUrlObjectSetupBean.selectedVcsRootId}"/>
  </c:if>
  <input type="hidden" name="selectedVcsRootId" value="${selectedRoot}"/>
  <input type="hidden" name="skipDuplicateVcsRootCheck" value="false"/>
  <input type="hidden" name="cameFromUrl" value="${param.cameFromUrl}"/>
  <forms:submit name="createProject" label="Proceed"/>
  <forms:cancel cameFromSupport="${cameFromSupport}"/>
  <forms:saving/>
</div>

<c:set var="parentProjectId" value="${vcsUrlObjectSetupBean.parentProject.externalId}"/>
<input type="hidden" id="parentProjectId" name="parentProjectId" value="${parentProjectId}"/>
</form>

</div>

<script type="text/javascript">
  $j(document).ready(function() {
    BS.AvailableParams.attachPopupsTo('projectId=${parentProjectId}', "[name^='prop:']");
  });
  BS.VcsUrlObjectSetupForm = OO.extend(BS.PluginPropertiesForm, {
    formElement: function() {
      return $('createProjectForm');
    },

    submit: function() {
      var that = this;
      BS.FormSaver.save(this, this.formElement().action, OO.extend(BS.ErrorsAwareListener, {
        onCompleteSave: function (form, responseXML) {
          var err = BS.XMLResponse.processErrors(responseXML, this, form.propertiesErrorsHandler);
          BS.ErrorsAwareListener.onCompleteSave(form, responseXML, err);
          if (!err) {
            this.onSuccessfulSave(responseXML);
          }
        },

        projectName: function(elem) {
          $j('#error_projectName').text(elem.firstChild.nodeValue);
          that.highlightErrorField($("projectName"));
        },

        buildTypeName: function(elem) {
          $j('#error_buildTypeName').text(elem.firstChild.nodeValue);
          that.highlightErrorField($("buildTypeName"));
        },

        persistFailed: function(elem) {
          $j('#error_persistFailed').text(elem.firstChild.nodeValue);
        },

        projectSettingsImportFailed: function(elem) {
          $j('#error_projectSettingsImportFailed').text(elem.firstChild.nodeValue);
        },

        projectSettingsImportFailed_dslParam: function(elem) {
          var params = window.location.search.toQueryParams();
          delete params['init'];
          window.location.search = Object.toQueryString(params);
        },

        vcsRoot: function(elem) {
          $j('#error_vcsRoot').text(elem.firstChild.nodeValue);
        },

        duplicateVcsRootsFound: function(elem) {
          BS.DuplicateVcsRootsDialog.showDialog(elem.firstChild.nodeValue,
                                                function (vcsRootId) {
                                                  BS.VcsUrlObjectSetupForm.formElement().selectedVcsRootId.value = vcsRootId;
                                                  BS.VcsUrlObjectSetupForm.submit();
                                                },
                                                function () {
                                                  BS.VcsUrlObjectSetupForm.formElement().skipDuplicateVcsRootCheck.value = 'true';
                                                  BS.VcsUrlObjectSetupForm.submit();
                                                });
        },

        onSuccessfulSave: function(responseXml) {
          BS.XMLResponse.processRedirect(responseXml);
        }
      }));
      return false;
    }
  });
</script>

<admin:duplicateVcsRootsDialog/>
