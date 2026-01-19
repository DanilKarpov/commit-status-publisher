<%@include file="/include-internal.jsp"%>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:choose>
  <c:when test="${not empty affectedProject}">
    <admin:editProjectLinkFull project="${affectedProject}"/> has <bs:out value="${fn:replace(healthStatusItem.additionalData['error'], 'Critical error', 'critical error')}"/>
  </c:when>
  <c:otherwise><bs:out value="${healthStatusItem.additionalData['error']}"/></c:otherwise>
</c:choose>