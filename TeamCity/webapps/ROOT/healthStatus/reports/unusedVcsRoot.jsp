<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<jsp:useBean id="healthStatusReportUrl" type="java.lang.String" scope="request"/>

<c:set var="vcsRoot" value="${healthStatusItem.additionalData['vcsRoot']}"/>
<c:set var="isVcsrootGlobal" value="${vcsRoot.scope.global}"/>
<c:set var="project" value="${healthStatusItem.additionalData['project']}"/>
<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<c:set var="projectLink"><admin:editProjectLink projectId="${project.externalId}" withoutLink="true"/></c:set>
<c:set var="returnUrl" value="${showMode eq inplaceMode ? projectLink : healthStatusReportUrl}"/>

<div>
  <admin:vcsRootName vcsRoot="${vcsRoot}" editingScope="" cameFromUrl="${returnUrl}"/> is not used and can be safely removed.
</div>
<c:if test="${afn:canEditVcsRoot(vcsRoot) and not project.readOnly}">
  <div>
    <a href="#" onclick="BS.AdminActions.deleteVcsRoot('${vcsRoot.externalId}', '${util:forJS(vcsRoot.name, true, true)}', function() { if (BS.HealthStatusReport) { BS.HealthStatusReport.refreshContent(); } else { document.location.href='${returnUrl}'; }}); return false;">Delete VCS root</a>
  </div>
</c:if>
