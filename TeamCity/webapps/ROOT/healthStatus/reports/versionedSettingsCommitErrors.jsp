<%@include file="/include-internal.jsp"%>
<%@ page import="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" %>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>

<c:set var="inplaceMode" value="<%=HealthStatusItemDisplayMode.IN_PLACE%>"/>
<c:set var="errorsBlockId" value="vsettingsCommitError_${showMode}_${root.externalId}"/>
<c:set var="projectsCount" value="${fn:length(projects)}"/>
<c:set var="cameFromUrl" value="${showMode eq inplaceMode ? pageUrl : healthStatusReportUrl}"/>

<div class="_inline-block">
  Failed to commit project settings to <admin:vcsRootName vcsRoot="${root.parent}" editingScope="none" cameFromUrl="${cameFromUrl}"/>,
  <strong>${projectsCount}</strong> project<bs:s val="${projectsCount}"/> affected.
  <c:if test="${showMode == inplaceMode}"><a href="javascript:;" onclick="$j('#${errorsBlockId}').toggle();">Show details &raquo;</a></c:if>
</div>
<div class="vsettingsCommitErrors" id="${errorsBlockId}" style="display: ${showMode == inplaceMode ? 'none' : ''}">
  <c:forEach var="p" items="${projects}">
    <div>
      <admin:projectName project="${p}" addToUrl="&tab=versionedSettings&subTab=config"/>
    </div>
  </c:forEach>
</div>