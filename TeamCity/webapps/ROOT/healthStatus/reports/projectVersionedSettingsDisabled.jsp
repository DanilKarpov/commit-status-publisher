<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@include file="/include-internal.jsp"%>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:set var="modifiedProject" value="${healthStatusItem.additionalData['project']}"/>
<%--@elvariable id="modifiedProject" type="jetbrains.buildServer.serverSide.SProject"--%>
<%--@elvariable id="project" type="jetbrains.buildServer.serverSide.SProject"--%>
<c:set var="projectAdmin" value="${afn:permissionGrantedForProject(modifiedProject, 'EDIT_PROJECT')}"/>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<%--
looks like addJsFile() doesn't work for health report page extensions,
therefore the copy the necessary part of versionedSettings.js
--%>
<script type="text/javascript">
  if (!BS.VersionedSettings) {
    BS.VersionedSettings = {
      url: window['base_uri'] + "/admin/versionedSettingsActions.html",
      enableProjectVersionedSettings: function(projectExtId, optionalProgressSelector) {
        if (!confirm('With enabled versioned settings TeamCity will apply your DSL to the configs on the server. Continue?'))
          return;
        if (optionalProgressSelector) {
          $j(optionalProgressSelector).show();
        }
        BS.ajaxRequest(BS.VersionedSettings.url, {
          parameters: Object.toQueryString({action: 'enableProjectVersionedSettings', projectId: projectExtId}),
          onComplete: function(transport) {
            BS.reload();
          }
        });
      }
    }
  }
</script>
<div>
  <c:choose>
    <c:when test="${showMode == inplaceMode and modifiedProject eq project}">
      Versioned settings are disabled because project configs were modified during TeamCity upgrade.
    </c:when>
    <c:otherwise>
      Versioned settings are disabled in the <admin:projectName project="${modifiedProject}" addToUrl="&tab=versionedSettings"/> project because its configs were modified during TeamCity upgrade.
    </c:otherwise>
  </c:choose>
  <c:if test="${projectAdmin}">Enable versioned settings to commit updated configs to VCS.</c:if>
</div>
<c:set var="progressId" value="healthReportEnableProjectSettings_${modifiedProject.externalId}_${showMode}"/>
<c:if test="${projectAdmin}">
  <input type="button" class="btn btn_mini" value="Enable" title="Enable versioned settings"
         onclick="BS.VersionedSettings.enableProjectVersionedSettings('${modifiedProject.externalId}', '#${progressId}')"/>
  <forms:saving id="${progressId}" style="float: none; margin-left: 0.5em;"/>
</c:if>
