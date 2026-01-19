<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<jsp:useBean id="healthStatusReportUrl" type="java.lang.String" scope="request"/>

<c:set var="buildType" value="${healthStatusItem.additionalData['buildType']}"/>
<c:set var="vcsRoots" value="${healthStatusItem.additionalData['vcsRoots']}"/>

<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<c:set var="cameFromUrl" value="${showMode eq inplaceMode ? pageUrl : healthStatusReportUrl}"/>

<div>

  The following VCS root<bs:s val="${fn:length(vcsRoots)}"/> prevent
  <admin:viewOrEditBuildTypeLinkFull buildType="${buildType}" step="buildTriggers" cameFromUrl="${cameFromUrl}"/>
  from triggering via VCS trigger due to large checking for changes interval (bigger or equal to quiet period):

  <ul>
    <c:forEach items="${vcsRoots}" var="vcsRoot">
      <li><admin:vcsRootName vcsRoot="${vcsRoot}" editingScope="none" cameFromUrl="${cameFromUrl}"/>: ${vcsRoot.modificationCheckInterval} seconds</li>
    </c:forEach>
  </ul>
</div>
