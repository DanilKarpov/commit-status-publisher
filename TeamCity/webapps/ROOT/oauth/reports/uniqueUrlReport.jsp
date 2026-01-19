<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>

<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<jsp:useBean id="showMode" type="jetbrains.buildServer.web.openapi.healthStatus.HealthStatusItemDisplayMode" scope="request"/>
<jsp:useBean id="healthStatusReportUrl" type="java.lang.String" scope="request"/>

<c:set var="project" value="${healthStatusItem.additionalData['project']}"/>
<c:set var="connection" value="${healthStatusItem.additionalData['connection']}"/>

<c:url var="editUrl" value='/admin/editProject.html?projectId=${project.externalId}&tab=oauthConnections#editConnection=${connection.id}'/>

<div>
  The connection
  <a href="${editUrl}" target="_blank" rel="noreferrer"><c:out value="${connection.displayName}"/></a>
  is not using a unique redirect URL. Consider enabling this setting to enhance the connection security.
</div>
<c:if test="${not project.readOnly}">
  <div>
    <a href="${editUrl}" target="_blank" rel="noreferrer">Edit connection</a>
  </div>
</c:if>